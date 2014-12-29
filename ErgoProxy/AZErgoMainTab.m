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
#import "AZDownloader.h"
#import "AZDownload.h"

#import "AZErgoDownloader.h"

#import "AZErgoDownloadDetailsPopover.h"

#import "AZDataProxyContainer.h"
#import "AZSynkEnabledStorage.h"

#define FETCH_DELAY 1.0

@interface AZErgoMainTab () <AZErgoProxifierDelegate, AZErgoDownloadsDataSourceDelegate> {
	AZErgoDownloadsDataSource *downloads;
	NSTimeInterval fetchDelayed;
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
	if (!downloads) {
		downloads = (id)self.ovDownloads.delegate;
	}

	[AZProxifier sharedProxy].delegate = self;
	[super show];
}

- (void) updateContents {
	[self fetchDownloads];
}

- (void) showDownload:(AZDownload *)download detailsFromSender:(id)sender {
	NSView *view = sender;
	[self.pDownloadPopover showDetailsFor:download alignedTo:view];
}

- (void) fetchDownloads {
	[downloads setData:nil];
	downloads.groupped = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED);
	NSArray *data = [AZDownload fetchDownloads];
	if (PREF_BOOL(PREFS_UI_DOWNLOADS_HIDEFINISHED)) {
		NSArray *filtered = [data objectsAtIndexes:[data indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			AZErgoDownloadedAmount downloaded = [downloads downloaded:obj];
			return (!downloaded.total) || (downloaded.downloaded < downloaded.total);
		}]];

		data = filtered;
	}

	[downloads setData:data];

	[self.ovDownloads reloadData];
	[downloads expandUnfinishedInOutlineView:self.ovDownloads];
}

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state {
	[AZDataProxyContainer saveContext];
	[self delayFetch];
}

- (void) delayFetch {
	@synchronized(self) {
		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		if (now - fetchDelayed > FETCH_DELAY) { // last quest to fetch was more than FETCH_DELAY sec ago
			fetchDelayed = now;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self fetchDownloads];
			});
		}
	}
}

@end
