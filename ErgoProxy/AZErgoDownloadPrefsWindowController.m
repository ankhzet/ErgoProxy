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
#import "AZErgoManga.h"

#import "AZDownloadPresets.h"

@interface AZErgoDownloadPrefsWindowController () {
	NSDictionary *controlsMapping;
	NSMutableDictionary *manualPrefs;

	AZErgoManga *prefsForManga;
	AZDownloadPresets *presets;
}

@property (weak) IBOutlet NSButton *cbUseDefaults;

@property (weak) IBOutlet NSButton *cbCustomWidth;
@property (weak) IBOutlet NSButton *cbCustomHeight;
@property (weak) IBOutlet NSButton *cbCustomQuality;
@property (weak) IBOutlet NSButton *cbCustomIsWebtoon;

@property (weak) IBOutlet NSSlider *sCustomWidth;
@property (weak) IBOutlet NSSlider *sCustomQuality;
@property (weak) IBOutlet NSSlider *sCustomHeight;
@property (weak) IBOutlet NSButton *sCustomIsWebtoon;

@property (weak) IBOutlet NSComboBox *cbPresets;

@property (weak) IBOutlet NSBox *bConstraintsBox;

@property (nonatomic) NSString *presetName;

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

	presets = [AZDownloadPresets new];

	return self;
}


- (NSString *) presetName {
	NSString *presetTitle = self.cbPresets.stringValue ?: kDownloadPresetDefault;
	for (NSString *presetName in @[kDownloadPresetDefault, kDownloadPresetComic, kDownloadPresetWebtoon])
    if ([presetTitle isEqualToString:LOC_FORMAT(presetName)])
			return presetName;

	return kDownloadPresetDefault;
}

- (void)windowDidLoad {
	[super windowDidLoad];

	[self.cbPresets removeAllItems];
	[self.cbPresets addItemWithObjectValue:LOC_FORMAT(kDownloadPresetComic)];
	[self.cbPresets addItemWithObjectValue:LOC_FORMAT(kDownloadPresetWebtoon)];
}

- (AZDialogReturnCode) beginSheet {
	[self prepareWindow];

	[self.cbPresets selectItemWithObjectValue:[presets pickPreset:prefsForManga]];
	[self setUseDefaults:YES];

	return [super beginSheet];
}

- (AZDownloadParams *) aquireParams:(BOOL)useDefaults forManga:(AZErgoManga *)manga {
	prefsForManga = manga;
	if (!(useDefaults || [self beginSheet] != AZDialogReturnCancel))
		return nil;

	NSString *preferredPreset = [presets pickPreset:prefsForManga];
	NSDictionary *presetParams = [presets fetchDefaults:preferredPreset];

	AZDownloadParams *params = [AZDownloadParams params:presetParams];
	if (useDefaults)
		return params;

//	if (self.cbCustomWidth.state==NSOnState)
		params = [params setDownloadParameter:kDownloadParamMaxWidth value:@(self.sCustomWidth.integerValue)];

//	if (self.cbCustomHeight.state==NSOnState)
		params = [params setDownloadParameter:kDownloadParamMaxHeight value:@(self.sCustomHeight.integerValue)];

//	if (self.cbCustomQuality.state==NSOnState)
		params = [params setDownloadParameter:kDownloadParamQuality value:@(self.sCustomQuality.integerValue)];

//	if (self.cbCustomIsWebtoon.state==NSOnState)
		params = [params setDownloadParameter:kDownloadParamIsWebtoon value:@(self.sCustomIsWebtoon.state==NSOnState)];

	return params;
}

- (void) setPref:(NSString *)key value:(NSInteger)value {
	[presets setPref:key value:value forPreset:self.presetName];
}

- (NSInteger) pref:(NSString *)key {
	return [presets pref:key forPreset:self.presetName];
}

- (BOOL) applyChanges {
	[presets savePreferences:^NSInteger(NSString *preference, NSString *key, BOOL *skip) {

		NSButton *checkbox = (id)[self searchControl:[@"c" stringByAppendingString:preference]];
		*skip = checkbox.state != NSOnState;
		if (!*skip) {
			NSSlider *valueSlider = (id)[self searchControl:[@"s" stringByAppendingString:preference]];

			return valueSlider.integerValue;
		}

		return 0;
	} forPreset:self.presetName];

	[self setUseDefaults:YES];

	return YES;
}

- (NSControl *) searchControl:(NSString *)identifier {
	return [self searchControl:identifier inContainingView:[self.bConstraintsBox contentView]];
}

- (void) setCustom:(id)slider value:(NSInteger)value {
	NSString *identifier = (![slider isKindOfClass:[NSString class]]) ? [((NSSlider *)slider).identifier substringFromIndex:1] : slider;
	NSString *label = controlsMapping[identifier];

	if (label) {
		NSButton *checkbox = (id)[self searchControl:[NSString stringWithFormat:@"c%@",identifier]];
		checkbox.title = [NSString stringWithFormat:@"%@ (%ld):", label, (long)value];

		NSInteger defaultVal = [self pref:presets.prefsMapping[identifier]];
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

		for (NSString *pref in [presets.prefsMapping allKeys])
			[self setCustom:pref value:[self pref:presets.prefsMapping[pref]]];
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

	NSInteger restoredValue = [self pref:presets.prefsMapping[identifier]];
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

- (IBAction)actionPresetSelected:(id)sender {
	[self setUseDefaults:YES];
}

@end
