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

#import "AZErgoDownloadDetailsPopover.h"

#import "AZDataProxy.h"

@interface AZErgoMainTab () <AZErgoDownloadStateListener, AZErgoDownloadsDataSourceDelegate> {
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

- (NSString *) tabIdentifier {
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

	return _downloads;
}

- (void) updateContents {
	self.downloads.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);
	[self delayFetch:YES];
}

- (void) showEntity:(id)entity detailsFromSender:(id)sender {
	NSView *view = sender;
	[self.pDownloadPopover showDetailsFor:entity alignedTo:view];
}

- (void) fetchDownloads:(BOOL)fullFetch {
	BOOL filterFinished = PREF_BOOL(PREFS_UI_DOWNLOADS_HIDEFINISHED);

	__block NSArray *data = self.downloads.data;
	if (fullFetch) {
//		[downloads setData:nil];
//		downloads.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);

		[[AZDataProxy sharedProxy] securedTransaction:^(NSManagedObjectContext *context, BOOL *propagateChanges) {
			[context lock];
			if (filterFinished) {
				NSMutableArray *all = [[AZErgoManga all] mutableCopy];
				[all removeObjectsInArray:[AZErgoMangaTag taggedManga:AZErgoTagGroupDownloaded]];
				[all removeObjectsInArray:[AZErgoMangaTag taggedManga:AZErgoTagGroupReaded]];
				[all removeObjectsInArray:[AZErgoMangaTag taggedManga:AZErgoTagGroupSuspended]];
				AZ_Mutable(Array, *filtered);
				for (AZErgoManga *manga in all)
					[filtered addObjectsFromArray:[manga.downloads allObjects]];

				data = filtered;
//				data =  [AZDownload filter:[NSPredicate predicateWithFormat:@"(totalSize == 0) or (downloaded < totalSize)"]
//														 limit:0];
			} else {
				NSArray *mangas = [AZErgoManga allDownloaded:NO];
				AZ_Mutable(Array, *fetch);
				for (AZErgoManga *manga in mangas)
					[fetch addObjectsFromArray:[manga.downloads allObjects]];

				data = fetch;
			}
			[context unlock];
		}];

	}

	if (filterFinished || fullFetch) {
		NSArray *filtered = [self filterDownloaded:data reclaim:fullFetch];
		if (filterFinished)
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
	if (PREF_BOOL(PREFS_UI_DOWNLOADS_HIDEFINISHED))
		[self delayFetch:YES];
}

#pragma mark - fetch

- (void) delayFetch:(BOOL)fullFetch {
	[self delayed:@"downloads-fetch" withBlock:^{
		[self fetchDownloads:fullFetch];

		[self delayed:@"database-flush" forTime:10. withBlock:^{
			[[AZDataProxy sharedProxy] saveContext];
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
			for (AZDownload *download in restarts)
				[proxifier reRegisterDownload:download];
		}];

	return filtered;
}

#pragma mark - Delegated & protocol methods

@end
