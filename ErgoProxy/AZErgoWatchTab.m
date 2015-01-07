//
//  AZErgoWatchTab.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoWatchTab.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangachanSource.h"

#import "AZProxifier.h"

#import "AZErgoDownloadPrefsWindowController.h"
#import "AZErgoUpdateWatchSubmitterWindowController.h"

#import "AZErgoWatcherScheduler.h"

typedef NS_ENUM(NSUInteger, AZErgoWatcherState) {
	AZErgoWatcherStateIddle = 0,
	AZErgoWatcherStateWatching = 1,
	AZErgoWatcherStateHasUpdates = 2,
};

@interface AZErgoWatchTab () <AZErgoUpdatesSourceDelegate, AZErgoUpdatesDataSourceDelegate> {
	AZErgoWatcherScheduler *scheduler;
}

@property (nonatomic) AZErgoUpdatesDataSource *updates;

@end

@implementation AZErgoWatchTab
@synthesize updates = _updates;

- (id)init {
	if (!(self = [super init]))
		return self;

	__weak id wSelf = self;
	scheduler = [AZErgoWatcherScheduler schedulerWithBlock:^void(AZErgoWatcherScheduler *scheduler, BOOL *stop) {
		AZErgoWatchTab *sSelf = wSelf;
		if ((*stop = !(sSelf = wSelf)))
			return;

		[sSelf runChecker];
	}];

	[AZErgoMangachanSource sharedSource].delegate = self;
	self.updateOnPrefsChange = YES;

	return self;
}

- (NSString *) tabIdentifier {
	return AZEPUIDWatchTab;
}

- (void) updateContents {
	[scheduler revalidate];

	[self delayFetch:[AZErgoUpdatesSource inProcess]];
}

- (void) show {
	_updates = (id)self.ovUpdates.delegate;
	_updates.expanded = YES;
	[super show];
}

- (AZGroupableDataSource *) updates {
	if (!_updates) {
		_updates = (id)self.ovUpdates.delegate;
		_updates.expanded = YES;
	}

	return _updates;
}

- (void) watcherState:(AZErgoWatcherState)state {
	NSToolbar *toolbar = [self.tabs associatedToolbar];
	if (toolbar) {
		NSToolbarItem *found = nil;
		NSArray *items = [toolbar items];
		for (NSToolbarItem *item in items)
			if ([item.itemIdentifier isEqualToString:[self tabIdentifier]]) {
				found = item;
				break;
			}

		if (found) {
			NSString *imageName = NSImageNameRevealFreestandingTemplate;
			switch (state) {
				case AZErgoWatcherStateWatching:
					imageName = NSImageNameNetwork;
					break;
				case AZErgoWatcherStateHasUpdates:
					imageName = NSImageNameComputer;
					break;
				default:
					break;
			}

			[found setImage:[NSImage imageNamed:imageName]];
		}
	}
}

- (void) watch:(AZErgoUpdateWatch *)watch inProcess:(AZErgoWatcherState)state {
	[self watcherState:state];

	for (AZErgoUpdateChapter *c in watch.updates)
		if (c.idx < 0)
			[c delete];
		else
			switch (state) {
				case AZErgoWatcherStateWatching:
					c.state = AZErgoUpdateChapterDownloadsDownloaded;
					break;

				case AZErgoWatcherStateHasUpdates:
					//					c.state = AZErgoUpdateChapterDownloadsNone;
					//					break;

				default:
					c.state = AZErgoUpdateChapterDownloadsUnknown;
					break;
			}

	if (state == AZErgoWatcherStateWatching)
		[self dummyUpdateNode].watch = watch;
}

- (void) watchers:(AZErgoUpdatesSourceDescription *)source inProcess:(AZErgoWatcherState)inProcess {
	for (AZErgoUpdateWatch *watch in source.watches)
		[self watch:watch inProcess:inProcess];
}

- (void) runChecker {
	if ([AZErgoUpdatesSource inProcess])
		return;

	NSDictionary *sources;
	@synchronized(sources = (id)[AZErgoUpdatesSource sharedSources]) {
		for (AZErgoUpdatesSource *source in [sources allValues])
			[self watchers:source.descriptor inProcess:AZErgoWatcherStateWatching];
	}
	[AZErgoUpdatesSource checkAll];
}

- (void) scheduleDownloads:(id)from recursive:(BOOL)recursive {
	if ([from isKindOfClass:[AZErgoUpdatesSourceDescription class]]) {
		AZErgoUpdatesSourceDescription *source = from;
		for (AZErgoUpdateWatch *watch in source.watches)
			[self scheduleDownloads:watch recursive:YES];
	} else

		if ([from isKindOfClass:[AZErgoUpdateWatch class]]) {
			AZErgoUpdateWatch *watch = from;
			for (AZErgoUpdateChapter *chapter in watch.updates)
				[self scheduleDownloads:chapter recursive:YES];
		} else

			if ([from isKindOfClass:[AZErgoUpdateChapter class]]) {
				AZErgoUpdateChapter *chapter = from;
				switch (chapter.state ?: [chapter.watch chapterState:chapter]) {
					case AZErgoUpdateChapterDownloadsDownloaded:
						break;

					case AZErgoUpdateChapterDownloadsPartial:
						if (recursive)
							break;

					case AZErgoUpdateChapterDownloadsNone: {
						AZErgoUpdatesSource *source = [chapter.watch.source relatedSource];

						[source checkUpdate:chapter withBlock:^(AZErgoUpdateChapter *chapter, NSArray *scans) {
							if (![scans count]) {
								[AZUtils notifyErrorMsg:[NSString stringWithFormat:@"Scans aquire failed for %@!", chapter.genData]];
								return;
							}

							AZDownloadParams *params = [[AZErgoDownloadPrefsWindowController sharedController] aquireParams:YES];

							if (!params) {
								[AZUtils notifyErrorMsg:@"Download params not aquired!"];
								return;
							}

							AZProxifier *proxifier = [AZProxifier sharedProxy];

							NSUInteger pageIDX = 1;
							for (NSString *scan in scans) {
								NSURL *url = [NSURL URLWithString:scan];
								AZDownload *download = [proxifier downloadForURL:url withParams:params];
								download.manga = chapter.watch.manga;
								download.chapter = chapter.idx;
								download.page = pageIDX++;
							}

							if (source.inProcess <= 1) {
								chapter.watch.checking = NO;
								[self watcherState:(source.inProcess > 1) ? AZErgoWatcherStateWatching : AZErgoWatcherStateHasUpdates];
							}

							[chapter.watch clearChapterState:chapter];
							chapter.state = AZErgoUpdateChapterDownloadsUnknown;

							[self delayFetch:NO];
						}];
						chapter.watch.checking = YES;
						[self watch:chapter.watch inProcess:AZErgoWatcherStateIddle];
						[self watcherState:AZErgoWatcherStateWatching];

						break;
					}

					default:
						break;
				}
			}

}

- (void) refreshChaptersList:(id)source {
	if ([source isKindOfClass:[AZErgoUpdateWatch class]]) {
		AZErgoUpdateWatch *watch = source;
		[self watchers:watch.source inProcess:AZErgoWatcherStateIddle];
		[[watch.source relatedSource] checkWatch:source];
	} else
		if ([source isKindOfClass:[AZErgoUpdatesSourceDescription class]])
			[self runChecker];
}

- (void) delegatedAction:(AZErgoUpdateActionIntent *)action {
	if ([action is:@"refresh"])
		[self refreshChaptersList:action.initiatorRelatedEntity];
	else
		if ([action is:@"scans"])
			[self scheduleDownloads:action.initiatorRelatedEntity recursive:YES];
}

- (AZErgoUpdateChapter *) dummyUpdateNode {
	AZErgoUpdateChapter *c = [AZErgoUpdateChapter insertNew];
	c.title = NSLocalizedString(@"<loading...>", @"Update loading dummy label");
	c.genData = @"";
	c.idx = -1;
	c.date = [NSDate new];
	c.state = AZErgoUpdateChapterDownloadsFailed;
	return c;
}

- (void) updatesSource:(AZErgoUpdatesSource *)source checkingWatch:(AZErgoUpdateWatch *)watch {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self watch:watch inProcess:AZErgoWatcherStateWatching];

		self.updates.expanded = YES;
		[self delayFetch:YES];
	});
}

- (void) updatesSource:(AZErgoUpdatesSource *)source watch:(AZErgoUpdateWatch *)watch checked:(BOOL)hasUpdates {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self watch:watch inProcess:hasUpdates ? AZErgoWatcherStateHasUpdates : AZErgoWatcherStateIddle];
		[self delayFetch:YES];
	});
}

- (void) delayFetch:(BOOL)fullFetch {
	[self delayed:@"fetch" withBlock:^{
		[self fetchUpdates:fullFetch];
	}];
}

- (void) fetchUpdates:(BOOL)fullFetch {
	NSArray *data = self.updates.data;
	self.updates.data = nil;
	self.updates.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);

	//	if (fullFetch) {
	data = [AZErgoUpdateChapter all];

	BOOL hasUpdates = NO;
	data = [self filter:fullFetch data:data withUpdates:&hasUpdates];

	if (hasUpdates)
		[self watcherState:AZErgoWatcherStateHasUpdates];

	//	}

	[self.updates setData:data];
	[self.ovUpdates reloadData];

	// suppressing "rowView requested from -heightOfRow" annoying error bug
	@try {
		[self.ovUpdates expandItem:nil expandChildren:YES];
	}
	@catch (NSException *exception) {
		NSLog(@"WARN: %@", exception);
	}
}

- (NSArray *) filter:(BOOL)fullFetch data:(NSArray *)data withUpdates:(BOOL *)_hasUpdates {
	__block BOOL hasUpdates = NO;

	if (PREF_BOOL(PREFS_UI_WATCHER_HIDEFINISHED)) {
		NSMutableSet *whs = [NSMutableSet setWithCapacity:[data count]];
		NSUInteger ehs = 0;
		for (AZErgoUpdateChapter *chapter in data) {
			AZErgoUpdateWatch *watch = chapter.watch;
			if (watch)
				[whs addObject:watch];
			else
				ehs++;
		}

		if (ehs)
			NSLog(@"Updates without established ->watch relationship: %lu", ehs);

		NSMutableArray *filteredData = [NSMutableArray arrayWithCapacity:[data count]];
		for (AZErgoUpdateWatch *watch in whs) {
			BOOL done = YES;
			NSArray *sorted = [[watch.updates allObjects] sortedArrayUsingComparator:^NSComparisonResult(AZErgoUpdateChapter *c1, AZErgoUpdateChapter *c2) {
				int d = c2.idx - c1.idx;
				return d ? d / abs(d) : NSOrderedSame;
			}];

			NSMutableArray *c = [NSMutableArray arrayWithCapacity:[sorted count]];
			AZErgoUpdateChapter *last = [sorted lastObject];

			done = !(last && last.idx < 0);
			if (!done) {
				last.state = AZErgoUpdateChapterDownloadsFailed;
				if (fullFetch)
					[c addObject:last];
			}

			for (AZErgoUpdateChapter *chapter in sorted)
				if (chapter.idx >= 0)
					switch ([watch chapterState:chapter]) {
						case AZErgoUpdateChapterDownloadsDownloaded:
							goto skip;

						case AZErgoUpdateChapterDownloadsNone:
							hasUpdates = YES;

						case AZErgoUpdateChapterDownloadsPartial:
						default:
							done = NO;
							[c addObject:chapter];
					}

		skip:

			if (!done)
				[filteredData addObjectsFromArray:c];
		}

		data = filteredData;
	} else {
		NSUInteger count = [data count];
		NSUInteger iterations = 4;
		NSUInteger splice = count / iterations;
		if (false && splice) {
			dispatch_apply(iterations, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
				for (NSUInteger i = index * splice; i < (index + 1) * splice; i++) {
					AZErgoUpdateChapter *chapter = data[i];
					if ([chapter.watch chapterState:chapter] == AZErgoUpdateChapterDownloadsNone)
						hasUpdates = YES;
				}

			});

			NSUInteger upper = splice * iterations;
			for (NSUInteger i = upper; i < count; i++) {
				AZErgoUpdateChapter *chapter = data[i];
				if ([chapter.watch chapterState:chapter] == AZErgoUpdateChapterDownloadsNone)
					hasUpdates = YES;
			}
		} else
			for (AZErgoUpdateChapter *chapter in data)
				if ([chapter.watch chapterState:chapter] == AZErgoUpdateChapterDownloadsNone)
					hasUpdates = YES;
	}


	if (_hasUpdates != NULL)
		*_hasUpdates = hasUpdates;

	return data;
}

@end
