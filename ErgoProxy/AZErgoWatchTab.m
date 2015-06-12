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

#import "AZErgoChapterDownloadParams.h"

#import "AZProxifier.h"
#import "AZDownload.h"
#import "AZDownloadParams.h"

#import "AZErgoDownloadPrefsWindowController.h"
#import "AZErgoUpdateWatchSubmitterWindowController.h"

#import "AZErgoMangaDetailsPopover.h"
#import "AZErgoChaptersSchedulingPopover.h"

#import "AZErgoWatcherScheduler.h"

#import "AZErgoMangaCommons.h"

#import "AZDataProxy.h"

#import "AZErgoSchedulingQueue.h"
#import "AZWaitableTask.h"

typedef NS_ENUM(NSUInteger, AZErgoWatcherState) {
	AZErgoWatcherStateIddle = 0,
	AZErgoWatcherStateWatching = 1,
	AZErgoWatcherStateHasUpdates = 2,
};

@interface AZErgoWatchTab () <AZErgoUpdatesSourceDelegate, AZErgoUpdateWatchDelegate> {
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

	schedulingQueue = [AZErgoSchedulingQueue sharedQueue];

	[AZErgoMangachanSource sharedSource].delegate = self;
	self.updateOnPrefsChange = YES;

	return self;
}

+ (NSString *) tabIdentifier {
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
			if ([item.itemIdentifier isEqualToString:[[self class] tabIdentifier]]) {
				found = item;
				break;
			}

		if (found) {
			NSString *imageName = NSImageNameRevealFreestandingTemplate;
			switch (state) {
				case AZErgoWatcherStateIddle:
					if (!schedulingQueue.hasNewChapters)
						break;
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
	watch = [watch inContext:nil];
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
//					c.state = AZErgoUpdateChapterDownloadsDownloaded;
					break;

				case AZErgoWatcherStateHasUpdates:
					//					c.state = AZErgoUpdateChapterDownloadsNone;
					//					break;

				default:
					c.state = AZErgoUpdateChapterDownloadsUnknown;
					break;
			}

	if ((state == AZErgoWatcherStateWatching) && ![watch.updates count]) {
		AZErgoUpdateChapter *node = [self dummyUpdateNode];
		node.watch = watch;
	}
}

- (void) watchers:(AZErgoUpdatesSourceDescription *)source inProcess:(AZErgoWatcherState)inProcess {
	for (AZErgoUpdateWatch *watch in [source.watches allObjects])
		[self watch:watch inProcess:inProcess];
}

- (void) watch:(AZErgoUpdateWatch *)watch stateChanged:(BOOL)checking {
	[self watch:watch inProcess:checking ? AZErgoWatcherStateWatching : AZErgoWatcherStateIddle];
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

- (void) scheduleDownloads:(id)from recursive:(BOOL)recursive sender:(id)sender {
	AZ_IFCLASS(from, AZErgoUpdatesSourceDescription, *source, {
		for (AZErgoUpdateWatch *watch in [source.watches allObjects])
			[self scheduleDownloads:watch recursive:YES sender:sender];
	}) else
		AZ_IFCLASS(from, AZErgoUpdateWatch, *watch, {
			if (recursive) {
				AZErgoManga *manga = watch.relatedManga;
				if (manga.isDownloaded)
					return;
			}

			NSArray *chapters = [[watch.updates allObjects] sortedArray];

			NSMutableArray *schedule = [NSMutableArray new];
			for (AZErgoUpdateChapter *chapter in [chapters reverseObjectEnumerator]) {
				AZErgoUpdateChapterDownloads state = [watch chapterState:chapter];
				switch (state) {
					case AZErgoUpdateChapterDownloadsDownloaded:
					case AZErgoUpdateChapterDownloadsPartial:
						break;

					default:
						if (!chapter.isDummy)
							[schedule addObject:chapter];
						break;
				}
			}

			if (![schedule count])
				return;

			[AZErgoChaptersSchedulingPopover showAlignedTo:sender
																		withConfigurator:[AZPopoverConfigurator with:schedule]];

		}) else
			AZ_IFCLASS(from, AZErgoUpdateChapter, *chapter, {
				[schedulingQueue queueChapterDownloadTask:chapter];
			});
}

- (void) refreshChaptersList:(id)source {
	AZ_IFCLASS(source, AZErgoUpdateWatch, *watch, {
		if (AZ_KEYDOWN(Command))
			[[AZErgoUpdateWatchSubmitterWindowController sharedController] showWatchSubmitter:watch];
		else
			if (AZ_KEYDOWN(Shift) && AZ_KEYDOWN(Alternate)) {
				[watch delete];
				[self delayFetch:YES];
			} else {
				[schedulingQueue checkWatch:watch];
			}
	}) else
		AZ_IFCLASS(source, AZErgoUpdatesSourceDescription, *source, {
			[self runChecker];
		});
}

- (void) markWatchDownloaded:(AZErgoUpdateWatch *)watch {
	AZErgoUpdateChapter *chapter = [watch lastChapter];
	AZErgoManga *manga = [AZErgoManga mangaWithName:watch.manga];

	if (!AZConfirm(LOC_FORMAT(@"Mark last chapter (%@) of %@ as downloaded?", chapter.formattedString, manga)))
		return;

	AZDownloadParams *params = [AZDownloadParams defaultParams:manga];
	NSString *path = [manga previewFile] ?: [manga mangaFolder];
	AZDownload *download = [[AZProxifier sharedProxifier] downloadForURL:path withParams:params];
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
		if (action.commandKey) {
			if (![action.initiatorRelatedEntity isKindOfClass:[AZErgoUpdateWatch class]])
				AZErrorTip(LOC_FORMAT(@"Works only on watches!"));
			else
				[self markWatchDownloaded:action.initiatorRelatedEntity];
		} else {
			[self scheduleDownloads:action.initiatorRelatedEntity recursive:NO sender:action.initiator];
		}
	}

	if ([action is:@"info"]) {
		AZErgoUpdateWatch *watch = action.initiatorRelatedEntity;
		[AZErgoMangaDetailsPopover showAlignedTo:action.initiator
														withConfigurator:[AZPopoverConfigurator with:watch.relatedManga]];
	}
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
	dispatch_async_at_main(^{
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
	if ([AZErgoUpdatesSource inProcess])
		return;

	dispatch_async_at_background(^{
		[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context
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

- (NSArray *) filter:(BOOL)fullFetch data:(NSArray *)dataToFilter withUpdates:(BOOL *)_hasUpdates {
	__block BOOL hasUpdates = NO;
	__block NSArray *filtered = dataToFilter;

	BOOL dontCheck = AZ_KEYDOWN(Shift);
	BOOL checkFinished = PREF_BOOL(PREFS_UI_WATCHER_HIDEFINISHED);

	[self.tabs progressed:^(AZProgressCallback progress) {

		if (checkFinished) {
//			NSUInteger ehs = 0;
//			for (AZErgoUpdateChapter *chapter in filtered) {
//				if (!chapter.watch) {
//					ehs++;
//					if (chapter.idx < 0)
//						[chapter delete];
//				}
//			}
//
//			if (ehs)
//				DDLogWarn(@"Updates without established ->watch relationship: %lu", ehs);

			NSArray *watches = [AZErgoUpdateWatch all];

			NSMutableArray *filteredData = [NSMutableArray arrayWithCapacity:[filtered count]];

			NSMutableArray *toCheck = [NSMutableArray new];
			for (AZErgoUpdateWatch *watch in watches) {
				if (dontCheck) {
//					for (AZErgoUpdateChapter *chapter in [watch.updates allObjects])
//						if (chapter.idx >= 0)
//							chapter.state = AZErgoUpdateChapterDownloadsNone;
////						else
////							[chapter delete];

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

				if (watch.requiresCheck)
					[toCheck addObject:watch];
			}

			watches = toCheck;

			for (AZErgoUpdateWatch *watch in watches) {
				BOOL done = YES;
				NSArray *sorted = [[watch.updates allObjects] sortedArrayUsingComparator:^NSComparisonResult(AZErgoUpdateChapter *c1, AZErgoUpdateChapter *c2) {
					return SIGN(c2.idx - c1.idx);
				}];

				NSMutableArray *c = [NSMutableArray arrayWithCapacity:[sorted count]];
				AZErgoUpdateChapter *last = [sorted lastObject];

				if ([watch.manga rangeOfString:@"negima" options:NSCaseInsensitiveSearch].location != NSNotFound)
					last = last;

				done = !(last && last.idx < 0);
				if (!done) {
					last.state = AZErgoUpdateChapterDownloadsFailed;
					if (fullFetch)
						[c addObject:last];
				}

				if (dontCheck)
					goto skip;

				double piece = 1. / [watches count];
				NSInteger index = [watches indexOfObject:watch];
				double thruProgress = index * piece;

				for (AZErgoUpdateChapter *chapter in sorted)
					if (chapter.idx >= 0) {
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

						progress(thruProgress + piece * _PROGRESSED(sorted, chapter));
					}

			skip:

				if (!done) {
					[filteredData addObjectsFromArray:c];

					[self bindAsDelegateTo:watch solo:NO];
				}
			}

			filtered = filteredData;
		} else {
			NSMutableDictionary *r = [NSMutableDictionary new];
			for (AZErgoUpdateChapter *chapter in filtered)
				[GET_OR_INIT(r[@(chapter.state)], [NSMutableArray new]) addObject:chapter];

			NSArray *at = r[@(AZErgoUpdateChapterDownloadsUnknown)];
			NSUInteger count = [at count];
			for (int i = 0; i < count; i++) {
				AZErgoUpdateChapter *chapter = at[i];

				if ([chapter.watch chapterState:chapter] == AZErgoUpdateChapterDownloadsNone)
					hasUpdates = YES;
				
				progress((i + 1) / (double)count);
			}
		}
		
	}];

	if (_hasUpdates != NULL)
		*_hasUpdates = hasUpdates;

	return filtered;
}

@end
