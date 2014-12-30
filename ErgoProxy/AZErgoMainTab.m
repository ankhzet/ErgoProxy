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

#import "AZErgoUpdateWatch.h"
#import "AZDelayableAction.h"

#import "AZErgoDownloadDetailsPopover.h"

#import "AZDataProxyContainer.h"
#import "AZSynkEnabledStorage.h"

#define FETCH_DELAY 0.2

@interface AZErgoMainTab () <AZErgoDownloadStateListener, AZErgoDownloadsDataSourceDelegate> {
	AZErgoDownloadsDataSource *downloads;
	id observer;
}
@property (weak) IBOutlet NSOutlineView *ovDownloads;
@property (strong) IBOutlet AZErgoDownloadDetailsPopover *pDownloadPopover;

@end
@implementation AZErgoMainTab

- (id)init {
	if (!(self = [super init]))
		return self;

	self.updateOnPrefsChange = YES;

	[(id)[[AZDataProxyContainer getInstance] dataProxy] subscribeForUpdateNotifications:self
																																						 selector:@selector(synkNotification:)];
	return self;
}

- (void) synkNotification:(NSNotification *)notification {
	[self updateContents];
}

- (NSString *) tabIdentifier {
	return AZEPUIDMainTab;
}

- (void) show {
	if (!downloads)
		downloads = (id)self.ovDownloads.delegate;

	[AZProxifier sharedProxy].delegate = self;
	[super show];
}

- (void) updateContents {
	[self delayFetch:YES];
}

- (void) showEntity:(id)entity detailsFromSender:(id)sender {
	NSView *view = sender;
	[self.pDownloadPopover showDetailsFor:entity alignedTo:view];
}

- (void) fetchDownloads:(BOOL)fullFetch {
	NSArray *data = downloads.data;
	if (fullFetch) {
		[downloads setData:nil];
		downloads.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);
		data = [AZDownload fetchDownloads];
	}

	NSArray *filtered = [self filterDownloaded:data reclaim:fullFetch];
	if (PREF_BOOL(PREFS_UI_DOWNLOADS_HIDEFINISHED))
		data = filtered;

	[downloads setData:data];

	[self view:self.ovDownloads updateWithSavedScroll:^{
		[self.ovDownloads reloadData];
		//		if (fullFetch)
		[downloads expandUnfinishedInOutlineView:self.ovDownloads];
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
	[[AZDelayableAction shared:@"downloads-update"] delayed:FETCH_DELAY execute:^{
		[self fetchDownloads:fullFetch];

		[[AZDelayableAction shared:@"database-flush"] delayed:30. execute:^{
			[AZDataProxyContainer saveContext];
		}];
	}];
}

- (NSScrollView *) scrollViewOf:(NSView *)view {
	Class scrollViewClass = [NSScrollView class];
	while (view && ![view isKindOfClass:scrollViewClass])
		view = [view superview];

	return (id)view;
 }

- (void) view:(NSOutlineView *)view updateWithSavedScroll:(void(^)())block  {
	NSScrollView *scrollView = [self scrollViewOf:view];
	NSPoint currentScrollPosition = [[scrollView contentView] bounds].origin;

	@try { block(); }
	@finally { [[scrollView documentView] scrollPoint:currentScrollPosition]; }
 }

- (NSArray *) filterDownloaded:(NSArray *)data reclaim:(BOOL)reclaim {
	Class downloadClass = [AZDownload class];
	return [data objectsAtIndexes:[data indexesOfObjectsPassingTest:^BOOL(AZDownload *obj, NSUInteger idx, BOOL *stop) {
		AZErgoDownloadedAmount downloaded = [downloads downloaded:obj reclaim:reclaim];
		BOOL show = (downloaded.downloaded < downloaded.total);

		if ((!show) && [obj isKindOfClass:downloadClass]) {
			show = HAS_BIT(obj.state, AZErgoDownloadStateProcessing) || (obj.downloaded < obj.totalSize);
		 }

		return show;
	}]];
 }


@end
