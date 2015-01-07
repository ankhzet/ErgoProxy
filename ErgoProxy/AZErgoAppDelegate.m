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
#import "AZDownloader.h"

#import "AZSynkEnabledStorage.h"
#import "AZDataProxyContainer.h"

#import "AZErgoManualSchedulerWindowController.h"
#import "AZErgoUpdateWatchSubmitterWindowController.h"
#import "AZErgoMangaAddWindowController.h"

@interface AZErgoAppDelegate ()
@property (weak) IBOutlet NSMenu *mNavMenu;

@end

@implementation AZErgoAppDelegate {
	BOOL running, paused;
	NSDictionary *tabMapping;
}

- (void) registerTabs {
	AZSynkEnabledStorage *storage = [AZSynkEnabledStorage storageWithParameters:@{
																																								kDPParameterModelName:@"ErgoProxy",
																																								kDPParameterStorageFile:@"ErgoProxy.sqlite",
																																								}];

	[AZDataProxyContainer initInstance:storage];
	[storage synkToggled];

	PREF_SAVE_BOOL(NO, @"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints");
	if (![PREF_STR(PREFS_PROXY_URL) length])
		PREF_SAVE_STR(@"http://ankh.ua/", PREFS_PROXY_URL);

	[AZProxifier sharedProxy].url = [NSURL URLWithString:PREF_STR(PREFS_PROXY_URL)];

	running = NO;
	paused = NO;

	tabMapping = @{
								 @1: AZEPUIDMangaTab,
								 @2: AZEPUIDWatchTab,
								 @3: AZEPUIDMainTab,
								 @4: AZEPUIDBrowserTab,
								 @5: AZEPUIDTagBrowserTab,
								 };

	[self registerTab:[AZErgoMainTab class]];
	[self registerTab:[AZErgoPreferencesTab class]];
	[self registerTab:[AZErgoWatchTab class]];
	[self registerTab:[AZErgoBrowserTab class]];

	[self registerTab:[AZErgoMangaTab class]];
	[self registerTab:[AZErgoTagBrowser class]];
	[self registerTab:[AZErgoMangaInfoTab class]];
}

- (NSString *) initialTab {
	return AZEPUIDMangaTab;
}

- (IBAction)actionShowPreferences:(id)sender {
	[self.tabsGroup navigateTo:AZEPUIDPreferencesTab withNavData:nil];
}

- (IBAction)actionAddManga:(id)sender {
	[[AZErgoMangaAddWindowController sharedController] showWithSetup:nil andFiltering:^AZDialogReturnCode(AZDialogReturnCode code, id controller) {

		switch (code) {
			case AZDialogReturnOk:
			case AZDialogReturnApply:
				if ([self.tabsGroup.currentTab.tabIdentifier isEqualToString:AZEPUIDMangaTab])
					[self.tabsGroup.currentTab updateContents];
				break;

			default:
				break;
		}

		return code;
	}];
}

- (IBAction)actionAddWatcher:(id)sender {
	[[AZErgoUpdateWatchSubmitterWindowController sharedController] showWatchSubmitter];
}

- (IBAction)actionManualSchedule:(id)sender {
	[[AZErgoManualSchedulerWindowController sharedController] beginSheet];
}

- (IBAction)actionMenuNavigate:(id)sender {
	NSMenuItem *item = sender;
	NSString *tab = tabMapping[@(item.tag)];

	if (!tab) {
		NSLog(@"Unknown menu navigation item tag %lu", item.tag);
		return;
	}

	[self.tabsGroup navigateTo:tab withNavData:nil];
}

- (void) tabGroup:(AZTabsGroup *)tabGroup navigatedTo:(AZTabProvider *)tab {
	[super tabGroup:tabGroup navigatedTo:tab];

	for (NSMenuItem *item in self.mNavMenu.itemArray)
		if (!!item.tag)
			[item setEnabled:![tabMapping[@(item.tag)] isEqualToString:tab.tabIdentifier]];
}

- (IBAction)actionRunDownloader:(id)sender {
	@synchronized(self) {
		NSError *error = nil;
		NSString *path = PREF_STR(PREFS_COMMON_MANGA_STORAGE);
		NSString *test = [path stringByAppendingPathComponent:@".~test"];
		[[NSFileManager defaultManager] removeItemAtPath:test error:nil];
		if (![[NSFileManager defaultManager] createDirectoryAtPath:test withIntermediateDirectories:NO attributes:@{} error:&error]) {
			[NSApp presentError:error];
			return;
		}
		[[NSFileManager defaultManager] removeItemAtPath:test error:nil];

		[[[self tabsGroup] tabByID:AZEPUIDMainTab] updateContents];

		[[AZProxifier sharedProxy] runDownloaders:(running = !running)];
		((NSMenuItem *) sender).title = running ? @"Stop downloaders" : @"Download";
	}
}

- (IBAction)actionPauseDownloader:(id)sender {
	@synchronized(self) {
		[[AZProxifier sharedProxy] pauseDownloaders:(paused = !paused)];
		((NSMenuItem *) sender).title = paused ? @"Resume workers" : @"Pause workers";
	}
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender {
	if (![[[AZDataProxyContainer getInstance] managedObjectContext] commitEditing]) {
		NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
	}

	[AZDataProxyContainer saveContext];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (void) applicationWillTerminate:(NSNotification *)notification {
	[self saveAction:nil];
}

@end
