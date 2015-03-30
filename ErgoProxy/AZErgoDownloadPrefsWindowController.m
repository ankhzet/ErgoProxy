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

#define PRESET_COMIC   @"Comic"
#define PRESET_WEBTOON @"Webtoon"

@interface AZErgoDownloadPrefsWindowController () {
	NSDictionary *controlsMapping;
	NSDictionary *prefsMapping;
	NSMutableDictionary *manualPrefs;
	BOOL forWebtoon;
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

@property (nonatomic) NSString *preset;

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

	return self;
}

- (NSString *) prefKey:(NSString *)pref ofPreset:(NSString *)preset {
	if ((![preset length]) || [preset isCaseInsensitiveLike:@"default"])
		return pref;

	preset = [preset lowercaseString];

	NSCharacterSet *set = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
	do {
		NSRange r = [preset rangeOfCharacterFromSet:set];
		if (!r.length)
			break;

		preset = [preset stringByReplacingCharactersInRange:r withString:@"_"];
	} while (1);

	NSString *temp;
	do {
		temp = preset;
		preset = [temp stringByReplacingOccurrencesOfString:@"__" withString:@"_"];
	} while ([temp length] != [preset length]);

	return [pref stringByAppendingString:[@"." stringByAppendingString:preset]];
}

- (void) setPref:(NSString *)key value:(NSInteger)value {
	PREF_SAVE_INT(value, [self prefKey:key ofPreset:self.preset]);
}

- (NSInteger) pref:(NSString *)key {
	return [self pref:key forPreset:self.preset];
}

- (NSInteger) pref:(NSString *)key forPreset:(NSString *)preset {
	NSString *presetKey = [self prefKey:key ofPreset:preset];
	BOOL hasPref = !![[NSUserDefaults standardUserDefaults] objectForKey:presetKey];
	return PREF_INT(hasPref ? presetKey : key);
}

- (NSString *) preset {
	return self.cbPresets.stringValue ?: @"default";
}

- (void)windowDidLoad {
	[super windowDidLoad];

	[self.cbPresets removeAllItems];
	[self.cbPresets addItemWithObjectValue:PRESET_COMIC];
	[self.cbPresets addItemWithObjectValue:PRESET_WEBTOON];
	[self.cbPresets selectItemWithObjectValue:forWebtoon ? PRESET_WEBTOON : PRESET_COMIC];

	manualPrefs = [NSMutableDictionary dictionary];
	for (NSString *pref in [prefsMapping allKeys])
		manualPrefs[pref] = @([self pref:prefsMapping[pref]]);

	[self setUseDefaults:YES];
}

- (NSDictionary *) fetchDefaults:(NSString *)preset {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	for (NSString *pref in [prefsMapping allKeys])
		result[pref] = @([self pref:prefsMapping[pref] forPreset:preset]);

	return result;
}

- (AZDownloadParams *) aquireParams:(BOOL)useDefaults forManga:(AZErgoManga *)manga {
	forWebtoon = manga.isWebtoon;

	if (useDefaults) {
		return [AZDownloadParams params:[self fetchDefaults:forWebtoon ? PRESET_WEBTOON : PRESET_COMIC]];
	}

	switch ([self beginSheet]) {
		case AZDialogReturnCancel:
			return nil;

		case AZDialogReturnOk:
		default:
			;
	}

	AZDownloadParams *params = [AZDownloadParams defaultParams];

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

- (BOOL) savePref:(NSString *)pref withParam:(NSString *)param {
	NSButton *checkbox = (id)[self searchControl:[@"c" stringByAppendingString:param]];
	BOOL didSave = checkbox.state == NSOnState;
	if (didSave) {
		NSSlider *value = (id)[self searchControl:[@"s" stringByAppendingString:param]];

		[self setPref:pref value:value.integerValue];
	}

	return didSave;
}

- (BOOL) applyChanges {
	for (NSString *pref in [prefsMapping allKeys])
		[self savePref:prefsMapping[pref] withParam:pref];

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

		NSInteger defaultVal = [self pref:prefsMapping[identifier]];
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
			[self setCustom:pref value:[self pref:prefsMapping[pref]]];
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

	NSInteger restoredValue = [self pref:prefsMapping[identifier]];
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
