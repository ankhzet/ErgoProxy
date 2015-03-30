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
#import "AZDownload.h"
#import "AZDownloadParams.h"

#import "AZErgoDownloadPrefsWindowController.h"
#import "AZErgoUpdateWatchSubmitterWindowController.h"

#import "AZErgoMangaStatePopoverController.h"

#import "AZErgoWatcherScheduler.h"

#import "AZErgoMangaCommons.h"

#import "AZDataProxy.h"

#import "AZErgoSchedulingQueue.h"

typedef NS_ENUM(NSUInteger, AZErgoWatcherState) {
	AZErgoWatcherStateIddle = 0,
	AZErgoWatcherStateWatching = 1,
	AZErgoWatcherStateHasUpdates = 2,
};

@interface AZErgoWatchTab () <AZErgoUpdatesSourceDelegate, AZErgoUpdatesDataSourceDelegate> {
	AZErgoWatcherScheduler *scheduler;
	AZErgoSchedulingQueue *schedulingQueue;
}

@property (nonatomic) AZErgoUpdatesDataSource *updates;

@end

MULTIDELEGATED_INJECT_LISTENER(AZErgoWatchTab)

@implementation AZErgoWatchTab
@synthesize updates = _updates;

- (id)init {
	if (!(self = [super init]))
		return self;

	__weak id wSelf = self;
	scheduler = [AZErgoWatcherScheduler schedulerWithBlock:^void(AZErgoWatcherScheduler *scheduler, BOOL *stop) {
		AZErgoWatchTab *sSelf = wSelf;
		if ((*stop = !sSelf))
			return;

		[sSelf runChecker];
	}];

	schedulingQueue = [AZErgoSchedulingQueue new];

	[AZErgoMangachanSource sharedSource].delegate = self;
	self.updateOnPrefsChange = YES;

	return self;
}

- (NSString *) tabIdentifier {
	return AZEPUIDWatchTab;
}

- (void) updateContents {
	[scheduler revalidate];

	[self delayFetch:[AZErgoUpdatesSource inProcess] || AZ_KEYDOWN(Command)];
}

- (void) show {
	[self updates];
	[super show];
}

- (AZGroupableDataSource *) updates {
	if (!_updates) {
		_updates = (id)self.ovUpdates.delegate;
		_updates.expanded = YES;
		[self bindAsDelegateTo:_updates solo:NO];
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
	AZErgoWatcherState all = state;
	if (all == AZErgoWatcherStateIddle)
		if (!![watch.source relatedSource].inProcess)
			all = AZErgoWatcherStateWatching;

	[self watcherState: all];

	for (AZErgoUpdateChapter *c in [watch.updates allObjects])
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

	if (state == AZErgoWatcherStateWatching) {
		AZErgoUpdateChapter *node = [self dummyUpdateNode];
		node.watch = watch;
	}
}

- (void) watchers:(AZErgoUpdatesSourceDescription *)source inProcess:(AZErgoWatcherState)inProcess {
	for (AZErgoUpdateWatch *watch in [source.watches allObjects])
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

	[AZErgoUpdatesSource checkAll:^(dispatch_block_t block) {
		[schedulingQueue enqueue:^(BOOL *requeue, id associatedObject) {
			block();
		} withAssociatedObject:[AZErgoUpdatesSource class]];
	}];
}

- (void) scheduleDownloads:(id)from recursive:(BOOL)recursive {
	if ([from isKindOfClass:[AZErgoUpdatesSourceDescription class]]) {
		AZErgoUpdatesSourceDescription *source = from;
		for (AZErgoUpdateWatch *watch in [source.watches allObjects])
			[self scheduleDownloads:watch recursive:YES];
	} else

		if ([from isKindOfClass:[AZErgoUpdateWatch class]]) {
			AZErgoUpdateWatch *watch = from;
			for (AZErgoUpdateChapter *chapter in [watch.updates allObjects])
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

					case AZErgoUpdateChapterDownloadsFailed:
					case AZErgoUpdateChapterDownloadsUnknown:
					case AZErgoUpdateChapterDownloadsNone: {
						AZErgoManga *manga = [AZErgoManga mangaWithName:chapter.watch.manga];
						if (manga.isDownloaded)
							return;

						[self queueSchedulingTask:chapter];

						break;
					}

					default:
						break;
				}
			}

}

- (void) refreshChaptersList:(id)source {
	if ([source isKindOfClass:[AZErgoUpdateWatch class]]) {
		if (AZ_KEYDOWN(Command))
			[[AZErgoUpdateWatchSubmitterWindowController sharedController] showWatchSubmitter:source];
		else
			if (AZ_KEYDOWN(Shift) && AZ_KEYDOWN(Alternate)) {
				[source delete];
				[self delayFetch:YES];
			} else {
				AZErgoUpdateWatch *watch = source;
				[schedulingQueue enqueue:^(BOOL *requeue, id associatedObject) {
					[self watchers:watch.source inProcess:AZErgoWatcherStateIddle];
					[[watch.source relatedSource] checkWatch:associatedObject];
				} withAssociatedObject:watch];
			}
	} else
		if ([source isKindOfClass:[AZErgoUpdatesSourceDescription class]])
			[self runChecker];
}

- (void) markWatchDownloaded:(AZErgoUpdateWatch *)watch {
	AZErgoUpdateChapter *chapter = [watch lastChapter];
	AZErgoManga *manga = [AZErgoManga mangaWithName:watch.manga];

	if (!AZConfirm(LOC_FORMAT(@"Mark last chapter (%@) of %@ as downloaded?", chapter.formattedString, manga)))
		return;

	NSString *path = [manga previewFile] ?: [manga mangaFolder];
	AZDownload *download = [[AZProxifier sharedProxifier] downloadForURL:path withParams:[AZDownloadParams defaultParams]];
	download.state = AZErgoDownloadStateDownloaded;
	download.chapter = chapter.idx;
	download.page = 1;
	download.forManga = manga;
	download.fileURL = path;
	download.totalSize = download.downloaded = [NSFileManager fileSize:path];

	chapter.state = AZErgoUpdateChapterDownloadsUnknown;
	[watch chapterState:chapter];
	[self delayFetch:YES];
}

- (void) delegatedAction:(AZActionIntent *)action {
	if ([action is:@"refresh"])
		[self refreshChaptersList:action.initiatorRelatedEntity];

	if ([action is:@"scans"]) {
		if ([action key:NSCommandKeyMask]) {
			if (![action.initiatorRelatedEntity isKindOfClass:[AZErgoUpdateWatch class]])
				AZErrorTip(LOC_FORMAT(@"Works only on watches!"));
			else
				[self markWatchDownloaded:action.initiatorRelatedEntity];
		} else {
			[self scheduleDownloads:action.initiatorRelatedEntity recursive:NO];
		}
	}

	if ([action is:@"info"])
		[[[AZErgoMangaStatePopoverController sharedController] popover] showDetailsOf:action.initiatorRelatedEntity alignedTo:action.initiator];
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
	dispatch_async_at_main(^{
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
	dispatch_async_at_background(^{
		[[AZDataProxy sharedProxy] securedTransaction:^(NSManagedObjectContext *context, BOOL *propagateChanges) {
			NSArray *data = [AZErgoUpdateChapter all];

			BOOL hasUpdates = NO;
			data = [self filter:fullFetch data:data withUpdates:&hasUpdates];

			if (![data count]) {
				AZErgoUpdateWatch *watch = [[[AZErgoMangachanSource sharedSource] descriptor].watches anyObject];
				AZErgoUpdateChapter *dummy = [self dummyUpdateNode];
				dummy.watch = watch;
				dummy.title = @"<no updates at all>";
				data = @[dummy];
			}

			self.updates.data = nil;
			self.updates.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);
			self.updates.data = data;

			dispatch_async_at_main(^{
				if (hasUpdates)
					[self watcherState:AZErgoWatcherStateHasUpdates];

				[self.ovUpdates reloadData];

				// suppressing "rowView requested from -heightOfRow" annoying error bug
				@try {
					[self.updates expandFirstLevelIn:self.ovUpdates];
				}
				@catch (NSException *exception) {
					DDLogVerbose(@"WARN: %@", exception);
				}
			});
		}];
	});
}

- (NSArray *) filter:(BOOL)fullFetch data:(NSArray *)data withUpdates:(BOOL *)_hasUpdates {
	BOOL hasUpdates = NO;
	
	BOOL dontCheck = AZ_KEYDOWN(Shift);

	if (PREF_BOOL(PREFS_UI_WATCHER_HIDEFINISHED)) {
		NSUInteger ehs = 0;
		for (AZErgoUpdateChapter *chapter in data) {
			if (!chapter.watch) {
				ehs++;
				if (chapter.idx < 0)
					[chapter delete];
			}
		}

		if (ehs)
			DDLogWarn(@"Updates without established ->watch relationship: %lu", ehs);

		NSArray *watches = [AZErgoUpdateWatch all];

		NSMutableArray *filteredData = [NSMutableArray arrayWithCapacity:[data count]];
		for (AZErgoUpdateWatch *watch in watches) {
			if (dontCheck) {
//				NSUInteger chapters = 0;
				for (AZErgoUpdateChapter *chapter in [watch.updates allObjects])
					if (chapter.idx >= 0)
						chapter.state = AZErgoUpdateChapterDownloadsNone;
//						chapters++;
					else
						[chapter delete];

				NSArray *updates = [watch.updates allObjects];
				if (![updates count]) {
					AZErgoUpdateChapter *update = [self dummyUpdateNode];
					update.title = LOC_FORMAT(@"No chapters aquired");
					update.watch = watch;
					[filteredData addObject:update];
				} else
					[filteredData addObjectsFromArray:[watch.updates allObjects]];

				continue;
			}

			if (!watch.requiresCheck) {
				DDLogVerbose(@"No need to check %@", [AZErgoManga mangaByName:watch.manga]);
				continue;
			}

			BOOL done = YES;
			NSArray *sorted = [[watch.updates allObjects] sortedArrayUsingComparator:^NSComparisonResult(AZErgoUpdateChapter *c1, AZErgoUpdateChapter *c2) {
				return SIGN(c2.idx - c1.idx);
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
	} else
		for (AZErgoUpdateChapter *chapter in data)
			if ([chapter.watch chapterState:chapter] == AZErgoUpdateChapterDownloadsNone)
				hasUpdates = YES;


	if (_hasUpdates != NULL)
		*_hasUpdates = hasUpdates;

	return data;
}

#pragma mark - Serial scheduling queue

- (void) queueSchedulingTask:(AZErgoUpdateChapter *)chapter {
	if (chapter.idx >= 0)
		[schedulingQueue enqueue:^(BOOL *requeue, AZErgoUpdateChapter *chapter) {
			__block BOOL needRequeue = *requeue;

			chapter.watch.checking = YES;
			[self watch:chapter.watch inProcess:AZErgoWatcherStateIddle];
			[self watcherState:AZErgoWatcherStateWatching];

			[AZErgoWaitBreakTask executeTask:^(AZErgoWaitBreakTask *task) {
				AZErgoUpdatesSource *source = [chapter.watch.source relatedSource];

				[source checkUpdate:chapter withBlock:^(NSArray *scans) {
					if (![scans count]) {
						chapter.state = AZErgoUpdateChapterDownloadsFailed;
						needRequeue = YES;
						[AZUtils notifyErrorMsg:LOC_FORMAT(@"Scans aquire failed for %@!", chapter.genData)];

						[task break];
						return;
					}

					AZDownloadParams *params;
					AZDownload *anyDownload = (id)[AZDownload mangaDownloads:chapter.watch.manga limit:1];
					if (anyDownload)
						params = anyDownload.downloadParameters;
					else
						params = [[AZErgoDownloadPrefsWindowController sharedController] aquireParams:NO forManga:[AZErgoManga mangaByName:chapter.watch.manga]];

					if (!params) {
						chapter.state = AZErgoUpdateChapterDownloadsFailed;
						[AZUtils notifyErrorMsg:LOC_FORMAT(@"Download params not aquired!")];
						[task break];
						return;
					}

					AZProxifier *proxifier = [AZProxifier sharedProxifier];

					[[AZDataProxy sharedProxy] securedTransaction:^(NSManagedObjectContext *context, BOOL *propagateChanges) {
						NSUInteger pageIDX = 1;
						for (NSString *scan in scans) {
							AZDownload *download = [proxifier downloadForURL:scan withParams:params];
							download.forManga = [AZErgoManga mangaWithName:chapter.watch.manga];
							download.chapter = chapter.idx;
							download.page = pageIDX++;
							download.state = AZErgoDownloadStateNone;
						}
					}];

					if (source.inProcess <= 1) {
						[self watcherState:(source.inProcess > 1) ? AZErgoWatcherStateWatching : AZErgoWatcherStateHasUpdates];
					}

					[chapter.watch clearChapterState:chapter];
					chapter.state = AZErgoUpdateChapterDownloadsUnknown;

					[task break];
				}];

			}];

			chapter.watch.checking = NO;
			[self delayFetch:NO];
			
			*requeue = needRequeue;
		} withAssociatedObject:chapter];
}

@end
