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

@implementation AZErgoAppDelegate {
	BOOL running, paused;
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

	[self registerTab:[AZErgoManualScheduleTab class]];
	[self registerTab:[AZErgoMainTab class]];
	[self registerTab:[AZErgoPreferencesTab class]];
	[self registerTab:[AZErgoWatchTab class]];
}

- (NSString *) initialTab {
	return AZEPUIDMainTab;
}

- (IBAction)actionRunDownloader:(id)sender {
	@synchronized(self) {
		[[AZProxifier sharedProxy] runDownloaders:(running = !running)];
		((NSToolbarItem *) sender).label = running ? @"Stop" : @"Download";
	}
}

- (IBAction)actionPauseDownloader:(id)sender {
	@synchronized(self) {
		[[AZProxifier sharedProxy] pauseDownloaders:(paused = !paused)];
		((NSToolbarItem *) sender).label = paused ? @"Resume" : @"Pause";
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
