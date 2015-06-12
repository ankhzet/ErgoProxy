//
//  AZErgoMangaChapter.m
//  ErgoProxy
//
//  Created by Ankh on 25.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaChapter.h"
#import "AZErgoChapterProtocol.h"

@implementation AZErgoMangaChapter

+ (BOOL) same:(float)chap1 as:(float)chap2 {
	return _IDX(chap1) == _IDX(chap2);
}

+ (NSArray *) fetchChapters:(NSString *)mangaRoot {
	NSArray *dirs = [AZUtils fetchDirs:[[self mangaStorage] stringByAppendingPathComponent:mangaRoot]];

	NSMutableSet *err = [NSMutableSet new];

	NSCharacterSet *nonNumeric = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
	NSMutableArray *sorted = [[dirs sortedArrayUsingComparator:^NSComparisonResult(NSString *chName1, NSString *chName2) {
		if ([chName1 rangeOfCharacterFromSet:nonNumeric].location != NSNotFound) {
			[err addObject:chName1];
			return NSOrderedAscending;
		}

		return SIGN([chName2 floatValue] - [chName1 floatValue]);
	}] mutableCopy];

	[sorted removeObjectsInArray:[err allObjects]];

	return sorted;
}

+ (float) lastChapter:(NSString *)mangaRoot {
	NSArray *chapters = [self fetchChapters:mangaRoot];
	NSString *last = [chapters firstObject];
	return [last floatValue];
}

+ (NSString *)mangaStorage {
	return PREF_STR(PREFS_COMMON_MANGA_STORAGE);
}

+ (NSString *)pad:(NSString *)str toLen:(NSInteger)len {
	len = len - [str length];
	if (len > 0)
		str = [[@"" stringByPaddingToLength:len withString:@"0" startingAtIndex:0] stringByAppendingString:str];

	return str;
}

+ (NSString *) formatChapterID:(float)chapter {
	int isBonus = !!_FRC(chapter);

	NSString *string = isBonus ? [NSString stringWithFormat:@"%.1f", chapter] : [NSString stringWithFormat:@"%d", (int)chapter];

	return [self pad:string toLen:isBonus ? 6 : 4];
}

+ (float) seekManga:(NSString *)mangaFolder chapter:(float)chapterID withDelta:(NSInteger)delta {
	int chapter = _IDX(chapterID);

	NSArray *chapters = [AZErgoMangaChapter fetchChapters:mangaFolder];

	NSNumber *prev = nil, *next = nil;

	for (NSNumber *ch in chapters) {
		int f = _IDX([ch floatValue]);

		if (f < chapter)
			if (f > [prev intValue])
				prev = @(f);

		if (f > chapter)
			if (f < (next ? [next intValue] : MAXFLOAT))
				next = @(f);
	}

	int old = chapter;

	if (delta > 0) {
		chapter = next ? [next intValue] : chapter;
		if (chapter == old) {
			int last = _IDX([[chapters firstObject] floatValue]);
			chapter = (last - _FRC(_IDI(last))) + _IDX(1);
		}
	} else
		if (delta < 0) {
			chapter = prev ? [prev intValue] : chapter;
		}

	return _IDI(chapter);
}

@end
