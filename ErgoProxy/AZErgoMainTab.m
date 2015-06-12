//
//  AZErgoMainTab.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoMainTab.h"
#import "AZErgoTabsComons.h"

#import "AZErgoDownloadsDataSource.h"

#import "AZProxifier.h"
#import "AZDownload.h"
#import "AZErgoMangaCommons.h"

#import "AZErgoUpdateWatch.h"

#import "AZErgoMangaDetailsPopover.h"
#import "AZErgoDownloadDetailsPopover.h"

#import "AZDataProxy.h"

#import "AZActionIntent.h"

@interface AZErgoMainTab () <AZErgoDownloadStateListener, AZActionDelegate> {
	AZErgoDownloadsDataSource *_downloads;
}
@property (weak) IBOutlet NSOutlineView *ovDownloads;
@property (strong) IBOutlet AZErgoDownloadDetailsPopover *pDownloadPopover;

@end

MULTIDELEGATED_INJECT_LISTENER (AZErgoMainTab)

@implementation AZErgoMainTab

- (id)init {
	if (!(self = [super init]))
		return self;

	self.updateOnPrefsChange = YES;

	[[AZDataProxy sharedProxy] subscribeForUpdateNotifications:self
																										selector:@selector(synkNotification:)];

//	[self delayed:@"auto-download" forTime:2. withBlock:^{
//		[self filterDownloaded:[AZDownload fetchDownloads] reclaim:YES];
//		[[AZProxifier sharedProxifier] runDownloaders:YES];
//	}];
	return self;
}

- (void) synkNotification:(NSNotification *)notification {
//	[self updateContents];
}

+ (NSString *) tabIdentifier {
	return AZEPUIDMainTab;
}

- (void) show {
	[self bindAsDelegateTo:[AZProxifier sharedProxifier] solo:YES];

	[super show];
}

- (void) dealloc {
	[self unbindDelegate];
}

- (AZErgoDownloadsDataSource *) downloads {
	if ((!_downloads) && !!self.ovDownloads) {
		_downloads = [(id)self.ovDownloads.dataSource setTo:self.ovDownloads];
		_downloads.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);
	}

	[self bindAsDelegateTo:_downloads solo:NO];
	return _downloads;
}

- (void) updateContents {
	self.downloads.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);
	[self delayFetch:YES];
}

- (void) fetchDownloads:(BOOL)fullFetch {
	BOOL filterFinished = PREF_BOOL(PREFS_UI_DOWNLOADS_HIDEFINISHED);
	BOOL showUnfinished = PREF_BOOL(PREFS_UI_DOWNLOADS_SHOWUNFINISHED);

	__block NSArray *data = self.downloads.data;
	if (fullFetch) {
		[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context

			[self.tabs progressed:^(AZProgressCallback progress) {
				AZ_Mutable(Array, *requiresDownloads);
				AZ_Mutable(Array, *zeroDownloads);
				NSArray *chapters = [AZErgoUpdateChapter all:@"persistentState != %lu", AZErgoUpdateChapterDownloadsDownloaded];

				NSUInteger mod = 0;
				chapters = [chapters sortedArrayUsingSelector:@selector(compare:)];

				AZ_Mutable(Array, *brokenChapters);
				for (AZErgoUpdateChapter *chapter in chapters) {
					if (![[chapter downloads] count]) {
						chapter.state = AZErgoUpdateChapterDownloadsDownloaded;
						[zeroDownloads addObject:chapter];
//						continue;
					}

					AZErgoUpdateChapterDownloads state = chapter.state;
					if (state != AZErgoUpdateChapterDownloadsDownloaded) {
						chapter.state = AZErgoUpdateChapterDownloadsUnknown;
						[chapter.watch chapterState:chapter];

						state = chapter.state;
					}

					if (state != AZErgoUpdateChapterDownloadsDownloaded) {
						if (state == AZErgoUpdateChapterDownloadsNone) {
							for (AZDownload *download in [chapter.downloads allObjects])
								if (![download.updateChapter isEqual:chapter])
									[chapter removeDownloadsObject:download];
								else
									[requiresDownloads addObject:download];
						} else {
							double chapterIDX = chapter.idx;
							if (!_IDX(chapterIDX))
								[brokenChapters addObject:chapter];
							else {
								for (AZDownload *download in [chapter.downloads allObjects])
									download.chapter = chapterIDX;

								[requiresDownloads addObjectsFromArray:[chapter.downloads allObjects]];
							}
						}

//						NSLog(@"\n%@\n%lu state, %lu downloads", chapter, chapter.state, [[chapter downloads] count]);
//						break;
					} else {
						mod++;
//						NSLog(@"%@ -> %lu", chapter, chapter.state);
//						break;
					}

					progress(_PROGRESSED(chapters, chapter));
				}
				if (!!mod || !![chapters count])
					NSLog(@"Downloaded: %lu/%lu", mod, [chapters count]);

				if (!![brokenChapters count]) {
					NSLog(@"Broken: %lu", [brokenChapters count]);
					AZ_Mutable(Dictionary, *watches);
					for (AZErgoUpdateChapter *chapter in brokenChapters) {
						chapter.state = AZErgoUpdateChapterDownloadsNone;
						watches[chapter.watch.manga] = chapter.watch;
					}

					for (AZErgoUpdateWatch *watch in [watches allValues]) {
						[watch clearChaptersState];
						[watch.relatedManga toggle:NO tagWithGUID:AZErgoTagGroupDownloaded];

						for (AZErgoUpdateChapter *chapter in [[watch.updates allObjects] sortedArrayUsingSelector:@selector(compare:)]) {
							chapter.state = AZErgoUpdateChapterDownloadsNone;
						}
					}
				}

				data = requiresDownloads;
			}];
			return;

			NSMutableArray *all = [[AZErgoManga all] mutableCopy];
			[all removeObjectsInArray:[AZErgoMangaTag taggedManga:AZErgoTagGroupDownloaded]];
			[all removeObjectsInArray:[AZErgoMangaTag taggedManga:AZErgoTagGroupReaded]];
			[all removeObjectsInArray:[AZErgoMangaTag taggedManga:AZErgoTagGroupSuspended]];

			NSMutableArray *prefetch = all;

			if (showUnfinished) {
				AZFR *unfinished = AZF_ALL_OF(@"(forManga IN %@) and ((updateChapter != nil) and (updateChapter.state != %lu))", prefetch, AZErgoUpdateChapterDownloadsDownloaded);

				NSMutableDictionary *manga = [NSMutableDictionary new];
				NSArray *downloads = [AZDownload fetch:[unfinished prefetch:@[@"forManga"]]];
				for (AZDownload *download in downloads) {
					NSString *mangaName = download.forManga.name;
					if (!manga[mangaName])
						manga[mangaName] = download.forManga;
				}

				prefetch = (id)[manga allValues];
			}

			AZFR *fetch = filterFinished
			? AZF_ALL_OF(@"(forManga IN %@) and ((updateChapter == nil) or (updateChapter.state != %lu))", prefetch, AZErgoUpdateChapterDownloadsDownloaded)
			: AZF_ALL_OF(@"forManga IN %@", prefetch);

			if (!filterFinished)
				fetch = [fetch prefetchEntities];

			data = [AZDownload fetch:[fetch prefetch:@[@"updateChapter"]]];

			if (showUnfinished) {
				AZ_MutableI(Array, *chapters, arrayWithCapacity:[data count]);

//				NSMutableDictionary *chaptersHash = [NSMutableDictionary new];
				[self.tabs progressed:^(AZProgressCallback progress) {
					for (AZDownload *d in data) {
						progress([data indexOfObject:d] / (double)[data count]);

//						NSString *manga = d.forManga.name;

//						NSMutableDictionary *chapters = GET_OR_INIT(chaptersHash[manga], [NSMutableDictionary new]);

						AZErgoUpdateChapter *chapter = d.updateChapter;
						if (!chapter) {
							d.updateChapter = chapter = [AZErgoUpdateChapter updateChapterForManga:d.forManga chapter:d.chapter];
//							chapters[@(d.chapter)] = chapter;
						} else {
//						if (!chapter.watch)
//							chapter.watch = [AZErgoUpdateWatch watchByManga:manga];
//
//						if (!chapter.title)
//							chapter.title = chapter.fullTitle;

//							chapters[@(d.chapter)] = chapter;
						}

						[chapters addObject:chapter];

					}
				}];

				Class c = [AZErgoUpdateChapter class];
				AZ_Mutable(Array, *updatedState);

				[self.tabs progressed:^(AZProgressCallback progress) {
//					AZ_Mutable(Array, *batch);
//					for (NSDictionary *chapters in [chaptersHash allValues])
//						[batch addObjectsFromArray:[chapters allValues]];

					NSArray *batch = [[NSSet setWithArray:chapters] allObjects];
					for (AZErgoUpdateChapter *chapter in batch) {
						if ([chapter isKindOfClass:c]) {
							AZErgoUpdateChapterDownloads state = chapter.state;
							if (state != AZErgoUpdateChapterDownloadsDownloaded) {
								chapter.state = AZErgoUpdateChapterDownloadsUnknown;
								[chapter.watch chapterState:chapter];

								state = chapter.state;
							}

							if (state == AZErgoUpdateChapterDownloadsDownloaded)
								[updatedState addObject:chapter];
						}


						progress([batch indexOfObject:chapter] / (double)[batch count]);
					}
				}];

				if (!![updatedState count]) {
//					dispatch_sync_at_background(^{
						[self.tabs progressed:^(AZProgressCallback progress) {
							AZ_MutableI(Array, *toDrop, arrayWithCapacity:[data count]);
							for (AZErgoUpdateChapter *chapter in updatedState) {
								[toDrop addObjectsFromArray:[chapter.downloads allObjects]];

								progress([updatedState indexOfObject:chapter] / (double)[updatedState count]);
							}

							data = [data mutableCopy];
							[(id) data removeObjectsInArray:toDrop];

						}];
//					});
				}

			}

		}];

	}

	if (filterFinished || fullFetch) {
		NSArray *filtered = [self filterDownloaded:data reclaim:fullFetch];
		if (0 && filterFinished)
			data = filtered;
	}


	[self.downloads setData:data];


	[self.ovDownloads performWithSavedScroll:^{
//		[self.downloads diff:data];
		[self.ovDownloads reloadData];
		//		if (fullFetch)
		[self.downloads expandUnfinishedInOutlineView:self.ovDownloads];
	}];
}

#pragma mark - Download delegate methods

- (void) download:(AZDownload *)download progressChanged:(double)progress {}

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state {
	if (HAS_BIT(state, AZErgoDownloadStateDownloaded) && PREF_BOOL(PREFS_UI_DOWNLOADS_HIDEFINISHED))
		[self delayFetch:YES];
}

#pragma mark - fetch

- (void) delayFetch:(BOOL)fullFetch {
	[self delayed:@"downloads-fetch" forTime:1. withBlock:^{
		[self fetchDownloads:fullFetch];

		[self delayed:@"database-flush" forTime:10. withBlock:^{
			[[AZDataProxy sharedProxy] saveContext:YES];
		}];
	}];
}

- (NSArray *) filterDownloaded:(NSArray *)data reclaim:(BOOL)reclaim {
	AZ_MutableI(Array, *filtered, arrayWithCapacity:[data count]);
	AZ_MutableI(Array, *restarts, arrayWithCapacity:[data count]);

	for (AZDownload *download in data) {
		BOOL show = HAS_BIT(download.state, AZErgoDownloadStateProcessing);

		if (!show) {
			BOOL started = NO;
			show = ![download downloadComplete:&started];

			if (show)
				[restarts addObject:download];

			show &= started;
		}

		if (show)
			[filtered addObject:download];
	}

	if (reclaim)
		[self delayed:@"re-register" withBlock:^{
			AZProxifier *proxifier = [AZProxifier sharedProxifier];
			[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context
				for (AZDownload *download in restarts)
					[proxifier registerForDownloading:download];
			}];
		}];

	return filtered;
}

#pragma mark - Delegated & protocol methods

- (void) delegatedAction:(AZActionIntent *)action {
	if ([action is:@"details"]) {
		if ([GroupsDictionary isDictionary:action.initiatorRelatedEntity]) {
			GroupsDictionary *groups = action.initiatorRelatedEntity;
			AZErgoManga *manga = [AZErgoManga mangaByName:groups.owner];
			[AZErgoMangaDetailsPopover showAlignedTo:action.initiator withConfigurator:[AZPopoverConfigurator with:manga]];
		} else
			[self.pDownloadPopover showDetailsFor:action.initiatorRelatedEntity alignedTo:action.initiator];
	}
}

@end
