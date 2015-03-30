//
//  AZErgoMangaChapter.h
//  ErgoProxy
//
//  Created by Ankh on 25.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AZErgoMangaChapter : NSObject

/*!@brief Returns array of folder names in manga folder. */
+ (NSArray *) fetchChapters:(NSString *)mangaRoot;

/*!@brief Returns number of last chapter, saved in manga folder. */
+ (float) lastChapter:(NSString *)mangaRoot;

/*!@brief Shortcut for PREF_STR(PREFS_COMMON_MANGA_STORAGE). */
+ (NSString *)mangaStorage;

+ (NSString *) formatChapterID:(float)chapter;
+ (float) seekManga:(NSString *)mangaFolder chapter:(float)chapterID withDelta:(NSInteger)delta;

+ (BOOL) same:(float)chap1 as:(float)chap2;

@end
