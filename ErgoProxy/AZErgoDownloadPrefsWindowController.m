//
//  AZErgoDownloadPrefsWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadPrefsWindowController.h"
#import "AZDownloadParams.h"

#import "AZProxifier.h"

typedef NS_ENUM(NSInteger, AZErgoParamsDialogReturn) {
	AZErgoParamsDialogReturnCancel = 0,
	AZErgoParamsDialogReturnOk = 1,
};

@interface AZErgoDownloadPrefsWindowController () {
	NSDictionary *controlsMapping;
	NSDictionary *prefsMapping;
	NSMutableDictionary *manualPrefs;
}

@property (weak) IBOutlet NSButton *cbUseDefaults;

@property (weak) IBOutlet NSButton *cbCustomWidth;
@property (weak) IBOutlet NSButton *cbCustomHeight;
@property (weak) IBOutlet NSButton *cbCustomQuality;
@property (weak) IBOutlet NSButton *cbCustomIsWebtoon;

@property (weak) IBOutlet NSSlider *sCustomWidth;
@property (weak) IBOutlet NSSlider *sCustomQuality;
@property (weak) IBOutlet NSSlider *sCustomHeight;

@property (weak) IBOutlet NSBox *bConstraintsBox;
@end

@implementation AZErgoDownloadPrefsWindowController

- (id)initWithWindow:(NSWindow *)window {
	if (!(self = [super initWithWindow:window]))
		return self;

	controlsMapping =
	@{
		@"Width": @"Width",
		@"Height": @"Height",
		@"Quality": @"Quality",
		@"IsWebtoon": @"Is a webtoon",
		};

	prefsMapping =
	@{
		@"Width": PREFS_DOWNLOAD_WIDTH,
		@"Height": PREFS_DOWNLOAD_HEIGHT,
		@"Quality": PREFS_DOWNLOAD_QUALITY,
		@"IsWebtoon": PREFS_DOWNLOAD_WEBTOON,
		};

	manualPrefs = [NSMutableDictionary dictionary];
	for (NSString *pref in [prefsMapping allKeys])
		manualPrefs[pref] = @(PREF_INT(prefsMapping[pref]));

	return self;
}

- (void)windowDidLoad {
	[super windowDidLoad];

	[self setUseDefaults:YES];
}

- (AZDownloadParams *) aquireParams:(BOOL)useDefaults {
	if (useDefaults)
		return [AZDownloadParams defaultParams];

	NSWindow *key = [[NSApplication sharedApplication] keyWindow];
	[self window];

	[[NSApplication sharedApplication] beginSheet:self.window
																 modalForWindow:key
																	modalDelegate:self
																 didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
																		contextInfo:nil];

	AZErgoParamsDialogReturn returned = [NSApp runModalForWindow:self.window];

	switch (returned) {
		case AZErgoParamsDialogReturnCancel:
			return nil;

		case AZErgoParamsDialogReturnOk:
		default:
			;
	}

	AZDownloadParams *params = [AZDownloadParams defaultParams];

	if (self.cbCustomWidth.state==NSOnState)
		[params setDownloadParameter:kDownloadParamMaxWidth value:@(self.sCustomWidth.integerValue)];

	if (self.cbCustomHeight.state==NSOnState)
		[params setDownloadParameter:kDownloadParamMaxHeight value:@(self.sCustomHeight.integerValue)];

	if (self.cbCustomQuality.state==NSOnState)
		[params setDownloadParameter:kDownloadParamQuality value:@(self.sCustomQuality.integerValue)];

	if (self.cbCustomIsWebtoon.state==NSOnState)
		[params setDownloadParameter:kDownloadParamIsWebtoon value:@(YES)];

	return params;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
}

- (void) dismissWithReturnCode:(NSInteger)returnCode {
	[NSApp endSheet:self.window returnCode:returnCode];
	[NSApp stopModalWithCode:returnCode];
}

- (IBAction)actionOk:(id)sender {
	[self dismissWithReturnCode:AZErgoParamsDialogReturnOk];
}

- (IBAction)actionCancel:(id)sender {
	[self dismissWithReturnCode:AZErgoParamsDialogReturnCancel];
}

- (BOOL) savePref:(NSString *)pref withParam:(NSString *)param {
	NSButton *checkbox = (id)[self searchControl:[@"c" stringByAppendingString:param]];
	BOOL didSave = checkbox.state == NSOnState;
	if (didSave) {
		NSSlider *value = (id)[self searchControl:[@"s" stringByAppendingString:param]];
		PREF_SAVE_INT(value.integerValue, pref);
	}

	return didSave;
}

- (IBAction)actionSaveDefaults:(id)sender {
	for (NSString *pref in [prefsMapping allKeys])
		[self savePref:prefsMapping[pref] withParam:pref];

	[self setUseDefaults:YES];
}

- (NSControl *) searchControl:(NSString *)identifier {
	for (NSControl *control in [[self.bConstraintsBox contentView] subviews])
		if ([control isKindOfClass:[NSControl class]] && [control.identifier isEqualToString:identifier])
			return control;

	return nil;
}

- (void) setCustom:(id)slider value:(NSInteger)value {
	NSString *identifier = (![slider isKindOfClass:[NSString class]]) ? [((NSSlider *)slider).identifier substringFromIndex:1] : slider;
	NSString *label = controlsMapping[identifier];

	if (label) {
		NSButton *checkbox = (id)[self searchControl:[NSString stringWithFormat:@"c%@",identifier]];
		checkbox.title = [NSString stringWithFormat:@"%@ (%ld):", label, (long)value];

		NSInteger defaultVal = PREF_INT(prefsMapping[identifier]);
		checkbox.state = (value != defaultVal) ? NSOnState : NSOffState;
		((NSSlider *)[self searchControl:[@"s" stringByAppendingString:identifier]]).integerValue = value;

		if (value != defaultVal)
			self.cbUseDefaults.state = NSOffState;
	}
}

- (IBAction)actionCustomValueSlided:(id)sender {
	NSInteger value = [((NSSlider *)sender) integerValue];

	[self setCustom:sender value:value];
}

- (void) setUseDefaults:(BOOL)useDefaults {
	[self.cbUseDefaults setState:useDefaults ? NSOnState : NSOffState];

	if (useDefaults) {
		[self.cbCustomWidth setState:NSOffState];
		[self.cbCustomHeight setState:NSOffState];
		[self.cbCustomQuality setState:NSOffState];
		[self.cbCustomIsWebtoon setState:NSOffState];

		for (NSString *pref in [prefsMapping allKeys])
			[self setCustom:pref value:PREF_INT(prefsMapping[pref])];
	}
}

- (IBAction)actionUseDefaultsCheched:(id)sender {
	[self setUseDefaults:self.cbUseDefaults.state==NSOnState];

	self.cbUseDefaults.state = [self hasCustomSettings] ? NSOffState : NSOnState;
}

- (BOOL) hasCustomSettings {
	BOOL checked = NO;
	for (NSString *label in [controlsMapping allKeys]) {
		NSButton *checkbox = (id)[self searchControl:[@"c" stringByAppendingString:label]];
    checked |= checkbox.state == NSOnState;
	}
	return checked;
}

- (void) cache:(BOOL)cache value:(NSString *)identifier {
	NSSlider *value = (id)[self searchControl:[@"s" stringByAppendingString:identifier]];

	NSInteger restoredValue = PREF_INT(prefsMapping[identifier]);
	if (cache)
		manualPrefs[identifier] = @(value.integerValue);
	else
		restoredValue = [manualPrefs[identifier] integerValue];

	[self setCustom:identifier value:restoredValue];
}

- (IBAction)actionCustomParameterMarked:(id)sender {
	NSButton *checkbox = ((NSButton *) sender);
	[self cache:(checkbox.state != NSOnState) value:[checkbox.identifier substringFromIndex:1]];

	[self setUseDefaults:![self hasCustomSettings]];
}

@end
