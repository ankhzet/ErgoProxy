//
//  AZDownloadPresets.h
//  ErgoProxy
//
//  Created by Ankh on 08.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kDownloadPresetDefault;
extern NSString *const kDownloadPresetComic;
extern NSString *const kDownloadPresetWebtoon;

extern NSString *const kDownloadParamNameWidth;
extern NSString *const kDownloadParamNameHeight;
extern NSString *const kDownloadParamNameQuality;
extern NSString *const kDownloadParamNameIsWebtoon;

@class AZErgoManga;
@interface AZDownloadPresets : NSObject

- (NSString *) pickPreset:(AZErgoManga *)manga;

- (NSDictionary *) prefsMapping;
- (NSDictionary *) fetchDefaults:(NSString *)presetName;

- (NSInteger) pref:(NSString *)key forPreset:(NSString *)presetName;
- (void) setPref:(NSString *)key value:(NSInteger)value forPreset:(NSString *)presetName;

typedef NSInteger(^AZDownloadPresetPrefEnumBlock)(NSString *preference, NSString *key, BOOL *skip);

- (void) savePreferences:(AZDownloadPresetPrefEnumBlock)enumBlock forPreset:(NSString *)presetName;

@end
