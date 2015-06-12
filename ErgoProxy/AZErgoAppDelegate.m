//
//  AZErgoAppDelegate.m
//  ErgoProxy
//
//  Created by Ankh on 30.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoAppDelegate.h"

#import "AZErgoTabsComons.h"

#import "AZProxifier.h"
#import "AZErgoDownloader.h"

#import "AZSynkEnabledStorage.h"

#import "AZErgoManualSchedulerWindowController.h"
#import "AZErgoUpdateWatchSubmitterWindowController.h"
#import "AZErgoMangaAddWindowController.h"
#import "AZErgoChapterStateWindowController.h"

#import "AZDownloadSpeedWatcher.h"

#import "AZErgoStatusItem.h"

#import "AZErgoMangachanSource.h"

#import "AZErgoTabPreferencesWindowController.h"

#define APP_TITLE @"ErgoProxy"

@interface AZErgoAppDelegate () <AZDownloadSpeedWatcherDelegate, AZErgoDownloaderDelegate>
@property (weak) IBOutlet NSMenu *mNavMenu;
@property (weak) IBOutlet NSMenuItem *miToggleDownloaders;

@property (nonatomic) BOOL runningDownloaders;
@end

MULTIDELEGATED_INJECT_LISTENER(AZErgoAppDelegate)

@implementation AZErgoAppDelegate {
	BOOL paused;
	NSDictionary *tabMapping;
	AZErgoStatusItem *statusItem;
}
@synthesize runningDownloaders = _runningDownloaders;

- (void) registerTabs {
	AZSynkEnabledStorage *storage = [AZSynkEnabledStorage initSharedProxy:@{
																																					kDPParameterModelName:@"ErgoProxy",
																																					kDPParameterStorageFile:@"ErgoProxy.sqlite",
																																					}];

	[[AZDataProxy sharedProxy] subscribeForUpdateNotifications:self
																										selector:@selector(synkNotification:)];
	[storage synkToggled];

	PREF_SAVE_BOOL(NO, @"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints");
	if (![PREF_STR(PREFS_PROXY_URL) length])
		PREF_SAVE_STR(@"http://ankh.ua/", PREFS_PROXY_URL);

	paused = NO;
	self.runningDownloaders = NO;

	tabMapping = @{
								 @1: AZEPUIDMangaTab,
								 @2: AZEPUIDWatchTab,
								 @3: AZEPUIDMainTab,
								 @4: AZEPUIDBrowserTab,
								 @5: AZEPUIDTagBrowserTab,
								 @6: AZEPUIDUtilsTab,
								 @7: AZEPUIDDownloadPriorityTab,
								 @8: @"chapters-state",
								 };

	[self registerTab:[AZErgoMainTab class]];
	[self registerTab:[AZErgoPreferencesTab class]];
	[self registerTab:[AZErgoWatchTab class]];
	[self registerTab:[AZErgoBrowserTab class]];

	[self registerTab:[AZErgoMangaTab class]];
	[self registerTab:[AZErgoTagBrowser class]];
	[self registerTab:[AZErgoMangaInfoTab class]];

	[self registerTab:[AZErgoDowdloadPriorityTab class]];

	[self registerTab:[AZErgoUtilsTab class]];


	[AZErgoMangachanSource sharedSource];

	[[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:0.5
																														target:self
																													selector:@selector(fireTimer:)
																													userInfo:nil
																													 repeats:YES]
														forMode:NSDefaultRunLoopMode];
}

- (void) synkNotification:(NSNotification *)notification {
	[self bindAsDelegateTo:[AZDownloadSpeedWatcher sharedSpeedWatcher] solo:NO];
	[self bindAsDelegateTo:[AZProxifier sharedProxifier] solo:NO];

	[AZProxifier sharedProxifier].url = PREF_STR(PREFS_PROXY_URL);

	statusItem = statusItem ?: [AZErgoStatusItem new];

//	[[AZErgoTabPreferencesWindowController sharedController] test];
}

- (NSString *) initialTab {
	return AZEPUIDUtilsTab;
}

- (void) fireTimer:(NSTimer *)timer {
	[self watcherUpdated:[AZDownloadSpeedWatcher sharedSpeedWatcher]];
}

- (void) watcherUpdated:(AZDownloadSpeedWatcher *)watcher {
	if ([self.tabsGroup.currentTab isKindOfClass:[AZErgoBrowserTab class]])
		return;

	NSUInteger downloaded = [watcher totalDownloaded];

	NSString *averageStr = nil;
	if (downloaded > 0) {
		NSString *pattern = NSLocalizedString(@" - [%@, %@ (%@) / sec]", @"Main window title pattern");
		NSUInteger precission = 1;
		if (downloaded > 1024 * 1024)
			precission = 2;

		NSTimeInterval longTerm = [AZDownloadSpeedWatcher timeWithTimeIntervalSinceNow:-(60*5)];
		NSTimeInterval shortTerm = [AZDownloadSpeedWatcher timeWithTimeIntervalSinceNow:-5];

		float shortAverage = [watcher averageSpeedSince:shortTerm];
		float longAverage = [watcher averageSpeedSince:longTerm];

		NSString *sDownloaded = [NSString cvtFileSize:downloaded withPrec:precission];
		NSString *sShort = ((shortAverage - 0.01)>0) ? [NSString cvtFileSize:shortAverage] : @"---";
		NSString *sLong = ((longAverage - 0.01)>0) ? [NSString cvtFileSize:longAverage] : @"---";
		averageStr = [NSString stringWithFormat:pattern, sDownloaded, sShort, sLong];
	} else
		averageStr = @"";

	self.window.title = [NSString stringWithFormat:@"%@%@", APP_TITLE, averageStr];
}

- (void) downloader:(AZErgoCustomDownloader *)downloader stateSchanged:(AZErgoDownloaderState)state {
	if (state == AZErgoDownloaderStateWorking)
		self.runningDownloaders = YES;
	else
		self.runningDownloaders = !![[AZProxifier sharedProxifier] hasRunningDownloaders];
}

- (void) downloader:(AZErgoCustomDownloader *)downloader readyForNextStage:(AZDownload *)download {

}

- (void) setRunningDownloaders:(BOOL)runningDownloaders {
	self.miToggleDownloaders.title = runningDownloaders ? @"Stop downloaders" : @"Toggle downloaders";

	_runningDownloaders = runningDownloaders;
}

- (IBAction)actionShowPreferences:(id)sender {
	[self.tabsGroup navigateTo:AZEPUIDPreferencesTab withNavData:nil];
}

- (IBAction)actionAddManga:(id)sender {
	[[AZErgoMangaAddWindowController sharedController] showWithSetup:nil andFiltering:^AZDialogReturnCode(AZDialogReturnCode code, id controller) {

		switch (code) {
			case AZDialogReturnOk:
			case AZDialogReturnApply: {
				AZTabProvider *tab = self.tabsGroup.currentTab;
				if (tab == [AZErgoMainTab sharedTab])
					[tab updateContents];
				break;
			}

			default:
				break;
		}

		return code;
	}];
}

- (IBAction)actionAddWatcher:(id)sender {
	[[AZErgoUpdateWatchSubmitterWindowController sharedController] showWatchSubmitter:nil];
}

- (IBAction)actionManualSchedule:(id)sender {
	[[AZErgoManualSchedulerWindowController sharedController] beginSheet];
}

- (IBAction)actionMenuNavigate:(id)sender {
	NSMenuItem *item = sender;
	NSString *tab = tabMapping[@(item.tag)];

	if ([tab isEqualToString:@"chapters-state"]) {
		[[AZErgoChapterStateWindowController sharedController] showStateController:nil];
		return;
	}

	if (!tab) {
		DDLogWarn(@"Unknown menu navigation item tag %lu", item.tag);
		return;
	}

	[self.tabsGroup navigateTo:tab withNavData:nil];
}

- (void) tabGroup:(AZTabsGroup *)tabGroup navigatedTo:(AZTabProvider *)tab {
	[super tabGroup:tabGroup navigatedTo:tab];

	for (NSMenuItem *item in self.mNavMenu.itemArray)
		if (!!item.tag)
			[item setEnabled:![tabMapping[@(item.tag)] isEqualToString:[[tab class] tabIdentifier]]];
}

- (IBAction)actionRunDownloader:(id)sender {
	dispatch_async_at_background(^{
		@synchronized(self) {
			BOOL forceRunning = !self.runningDownloaders;

			if (forceRunning) {
				NSError *error = nil;
				NSString *path = PREF_STR(PREFS_COMMON_MANGA_STORAGE);
				NSString *test = [path stringByAppendingPathComponent:@".~test"];
				[[NSFileManager defaultManager] removeItemAtPath:test error:nil];
				if (![[NSFileManager defaultManager] createDirectoryAtPath:test withIntermediateDirectories:NO attributes:@{} error:&error]) {
					NSString *message = error.localizedDescription;
					if ([error.domain isEqualToString:NSCocoaErrorDomain] && (error.code == 4)) {
						NSError *under = error.userInfo[NSUnderlyingErrorKey];
						if ([under.domain isEqualToString:NSPOSIXErrorDomain] && (under.code == 2))
							message = [NSString stringWithFormat:NSLocalizedString(@"Can't access \"%@\"", @"Unavailable storage"), path];
					}
					[AZAlert showAlert:AZErrorTitle message:message];
					return;
				}
				[[NSFileManager defaultManager] removeItemAtPath:test error:nil];
			}

			dispatch_async_at_main(^{
//				[[[self tabsGroup] tabByID:AZEPUIDrMainTab] updateContents];

				if (forceRunning) {
					[[AZProxifier sharedProxifier] reRegisterDownloads];
				}
				self.runningDownloaders = forceRunning;
				[[AZProxifier sharedProxifier] runDownloaders:self.runningDownloaders];
				if (forceRunning) {
					[[AZProxifier sharedProxifier] pauseDownloaders:(paused = NO)];
				}
			});
		}
	});
}

- (IBAction)actionPauseDownloader:(id)sender {
	@synchronized(self) {
		[[AZProxifier sharedProxifier] pauseDownloaders:(paused = !paused)];
		((NSMenuItem *) sender).title = paused ? @"Resume workers" : @"Pause workers";
	}
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender {
	[[AZDataProxy sharedProxy] saveContext:YES];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (void) applicationWillTerminate:(NSNotification *)notification {
	PREF_SAVE_INT(PREF_INT(PREFS_COMMON_MANGA_DOWNLOADED) + [[AZDownloadSpeedWatcher sharedSpeedWatcher] totalDownloaded], PREFS_COMMON_MANGA_DOWNLOADED);


	[[AZDataProxy sharedProxy] saveContext:NO];
}

@end
