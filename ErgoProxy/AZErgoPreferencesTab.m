//
//  AZPreferencesTab.m
//  AnkhReader
//
//  Created by Ankh on 29.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoPreferencesTab.h"
#import "AZErgoTabsComons.h"
#import "AZSyncedScrollView.h"


@interface AZErgoPreferencesTab () <AZSyncedScrollViewProtocol>

@property (weak) IBOutlet NSTextField *tfServerAddress;

@property (weak) IBOutlet NSTextField *tfUserLogin;
@property (weak) IBOutlet NSSecureTextField *tfUserPassword;
@property (weak) IBOutlet NSButton *cbLoginAsGuest;
@property (weak) IBOutlet NSButton *cbLoginAutomatically;

@property (weak) IBOutlet NSTextField *tfMangaStorage;
@property (weak) IBOutlet NSButton *cbGroupDownloads;
@property (weak) IBOutlet NSButton *cbHideFinishedDownloads;

@property (weak) IBOutlet NSTextField *tfSimultaneousDownloadsPerStorage;
@property (weak) IBOutlet NSButton *cbDownloadsFullResolve;

@property (weak) IBOutlet NSTextField *tfWatcherAutocheckInterval;
@property (weak) IBOutlet NSButton *cbHideDownloadedChapters;

@property (weak) IBOutlet AZSyncedScrollView *ssvScrollView;
@property (weak) IBOutlet NSLayoutConstraint *lcFloatWidth;

@end

@implementation AZErgoPreferencesTab

- (NSString *) tabIdentifier {
	return AZEPUIDPreferencesTab;
}

- (void) show {
	self.ssvScrollView.delegate = self;
	[super show];
}

- (void) frame:(NSScrollView *)view sizeChanged:(NSSize)size {
	self.lcFloatWidth.constant = size.width;
}

- (void) updateContents {
	// server
	self.tfServerAddress.stringValue = PREF_STR(PREFS_PROXY_URL);

	// user
	self.cbLoginAutomatically.state = PREF_BOOL(DEF_USER_LOGIN_AUTOMATICALY) ? NSOnState : NSOffState;
	[self setLoginAsGuest:PREF_BOOL(DEF_USER_LOGIN_AS_GUEST)];

	// schedule ui
	self.tfMangaStorage.stringValue = PREF_STR(PREFS_COMMON_MANGA_STORAGE);
	self.cbGroupDownloads.state = PREF_BOOL(PREFS_UI_DOWNLOADS_GROUPPED) ? NSOnState : NSOffState;
	self.cbHideFinishedDownloads.state = PREF_BOOL(PREFS_UI_DOWNLOADS_HIDEFINISHED) ? NSOnState : NSOffState;

	// downloads prefs
	self.tfSimultaneousDownloadsPerStorage.stringValue = PREF_STR(PREFS_DOWNLOAD_PER_STORAGE);
	self.cbDownloadsFullResolve.state = PREF_BOOL(PREFS_DOWNLOAD_FULL_RESOLVE) ? NSOnState : NSOffState;

	// watcher
	self.tfWatcherAutocheckInterval.stringValue = PREF_STR(PREFS_WATCHER_AUTOCHECK_INTERVAL);
	self.cbHideDownloadedChapters.state = PREF_BOOL(PREFS_UI_WATCHER_HIDEFINISHED) ? NSOnState : NSOffState;
}

- (BOOL) loginAsGuest {
	return [self.cbLoginAsGuest state] == NSOnState;
}

- (BOOL) loginAutomatically {
	return [self.cbLoginAutomatically state] == NSOnState;
}

- (void) setLoginAsGuest:(BOOL)asGuest {
	[self.cbLoginAsGuest setState:asGuest ? NSOnState : NSOffState];

	[self.tfUserLogin setEnabled:!asGuest];
	[self.tfUserPassword setEnabled:!asGuest];

	if (asGuest) {
		[self.tfUserLogin setStringValue:@""];
		[self.tfUserPassword setStringValue:@""];
	} else {
		self.tfUserLogin.stringValue = PREF_STR(DEF_USER_LOGIN);
		self.tfUserPassword.stringValue = PREF_STR(DEF_USER_PASSWORD);
	}

	PREF_SAVE_UI_BOOL(self.cbLoginAsGuest, DEF_USER_LOGIN_AS_GUEST);
}

- (IBAction)actionLoginAsGuestChecked:(id)sender {
	[self setLoginAsGuest:[self loginAsGuest]];
}

- (IBAction)actionLoginAutomaticalyChecked:(id)sender {
	PREF_SAVE_UI_BOOL(self.cbLoginAutomatically, DEF_USER_LOGIN_AUTOMATICALY);
}

- (IBAction)actionServerAddressChanged:(id)sender {
	PREF_SAVE_UI_STR(self.tfServerAddress, PREFS_PROXY_URL);
}

- (IBAction)actionUserLoginChanged:(id)sender {
	PREF_SAVE_UI_STR(self.tfUserLogin, DEF_USER_LOGIN);
}

- (IBAction)actionUserPasswordChanged:(id)sender {
	PREF_SAVE_UI_STR(self.tfUserPassword, DEF_USER_PASSWORD);
}

- (IBAction)actionMangaStorageChanged:(id)sender {
	PREF_SAVE_UI_STR(self.tfMangaStorage, PREFS_COMMON_MANGA_STORAGE);
}
- (IBAction)actionSimultaneousDownloadsChanged:(id)sender {
	PREF_SAVE_UI_STR(self.tfSimultaneousDownloadsPerStorage, PREFS_DOWNLOAD_PER_STORAGE);
}
- (IBAction)actionDownloadsFullResolveChanged:(id)sender {
	PREF_SAVE_UI_BOOL(self.cbDownloadsFullResolve, PREFS_DOWNLOAD_FULL_RESOLVE);
}

- (IBAction)actionPickFolderForStorage:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	if ([panel runModal] != NSFileHandlingPanelOKButton) return;

	NSURL *storageURL = [[panel URLs] lastObject];
	self.tfMangaStorage.stringValue = [storageURL path];
	[self actionMangaStorageChanged:nil];
}

- (IBAction)actionGroupDownloadsChanged:(id)sender {
	PREF_SAVE_UI_BOOL(self.cbGroupDownloads, PREFS_UI_DOWNLOADS_GROUPPED);
}
- (IBAction)actionHideFinishedDownloadChanged:(id)sender {
	PREF_SAVE_UI_BOOL(self.cbHideFinishedDownloads, PREFS_UI_DOWNLOADS_HIDEFINISHED);
}

- (IBAction)actionWatcherAutocheckIntervalChanged:(id)sender {
	PREF_SAVE_INT([self.tfWatcherAutocheckInterval integerValue], PREFS_WATCHER_AUTOCHECK_INTERVAL);
}
- (IBAction)actionHideDownloadedChaptersChanged:(id)sender {
	PREF_SAVE_UI_BOOL(self.cbHideDownloadedChapters, PREFS_UI_WATCHER_HIDEFINISHED);
}

@end
