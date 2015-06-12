//
//  AZDownloadPresets.m
//  ErgoProxy
//
//  Created by Ankh on 08.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZDownloadPresets.h"
#import "AZErgoManga.h"

NSString *const kDownloadPresetDefault = @"default";
NSString *const kDownloadPresetComic = @"Comic";
NSString *const kDownloadPresetWebtoon = @"Webtoon";

NSString *const kDownloadParamNameWidth = @"Width";
NSString *const kDownloadParamNameHeight = @"Height";
NSString *const kDownloadParamNameQuality = @"Quality";
NSString *const kDownloadParamNameIsWebtoon = @"IsWebtoon";


@protocol AZDownloadPresetsDeletage <NSObject>

- (NSString *) preset;

@end

@interface AZDownloadPreset : NSObject

@property (nonatomic) NSString *presetName;

@end

@implementation AZDownloadPreset

@end

@interface AZDownloadPresets () {
	NSDictionary *prefsMapping;
	NSMutableDictionary *manualPrefs;
}

@end

@implementation AZDownloadPresets

- (id)init {
	if (!(self = [super init]))
		return self;

	prefsMapping =
	@{
		kDownloadParamNameWidth: PREFS_DOWNLOAD_WIDTH,
		kDownloadParamNameHeight: PREFS_DOWNLOAD_HEIGHT,
		kDownloadParamNameQuality: PREFS_DOWNLOAD_QUALITY,
		kDownloadParamNameIsWebtoon: PREFS_DOWNLOAD_WEBTOON,
		};

	return self;
}

- (NSString *) prefKey:(NSString *)pref ofPreset:(NSString *)preset {
	if ((![preset length]) || preset == kDownloadPresetDefault)
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

- (NSInteger) pref:(NSString *)key forPreset:(NSString *)presetName {
	NSString *presetKey = [self prefKey:key ofPreset:presetName];
	BOOL hasPref = !![[NSUserDefaults standardUserDefaults] objectForKey:presetKey];
	return PREF_INT(hasPref ? presetKey : key);
}

- (void) setPref:(NSString *)key value:(NSInteger)value forPreset:(NSString *)presetName {
	PREF_SAVE_INT(value, [self prefKey:key ofPreset:presetName]);
}

- (NSDictionary *) fetchDefaults:(NSString *)presetName {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	for (NSString *pref in [prefsMapping allKeys])
		result[pref] = @([self pref:prefsMapping[pref] forPreset:presetName]);

	return result;
}

- (NSString *) pickPreset:(AZErgoManga *)manga {
	BOOL forWebtoon = manga.isWebtoon;

	return forWebtoon ? kDownloadPresetWebtoon : kDownloadPresetComic;
}

- (NSDictionary *) prefsMapping {
	return prefsMapping;
}

- (void) savePreferences:(AZDownloadPresetPrefEnumBlock)enumBlock forPreset:(NSString *)presetName {
	for (NSString *preference in [prefsMapping allKeys]) {
		BOOL skip = NO;
    NSInteger value = enumBlock(preference, prefsMapping[preference], &skip);
		if (skip)
			continue;

		[self setPref:prefsMapping[preference] value:value forPreset:presetName];
	}
}

@end
