//
//  AZErgoManga.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

@class AZErgoMangaProgress, AZErgoMangaTag, AZErgoMangaTitle, AZErgoUpdateChapterMapping;

@interface AZErgoManga : AZCoreDataEntity

@property (nonatomic, retain) NSString *annotation;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *preview;
@property (nonatomic) NSUInteger order;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) NSSet *titles;
@property (nonatomic, retain) AZErgoMangaProgress *progress;
@property (nonatomic, retain) NSSet *downloads;
@property (nonatomic, retain) NSDate *fsCheck;

@property (nonatomic, retain) NSSet *chapterMappings;

+ (instancetype) mangaWithName:(NSString *)name;
+ (instancetype) mangaByName:(NSString *)name;

+ (NSArray *) allDownloaded:(BOOL)downloaded;

- (NSComparisonResult) compare:(AZErgoManga *)another;
- (NSComparisonResult) orderedCompare:(AZErgoManga *)another;

- (NSString *) previewFile;
- (NSString *) mangaFolder;

- (BOOL) hasToCheckFS;
- (void) checkFSWithCompletion:(void(^)(AZErgoManga *manga))complete;

- (NSUInteger) remapChapters:(NSArray *)chapters;
- (AZErgoUpdateChapterMapping *) mappingForChapter:(float)chapter inVolume:(NSUInteger)volume;

@end

@interface AZErgoManga (Titles)

+ (NSString *) mainTitle:(NSArray *)titles;

- (NSString *) mainTitle;
- (NSArray *) additionalTitles;
- (NSArray *) titleEntities;
+ (NSArray *) titleEntities:(NSArray *)titles cyrylic:(BOOL)cyrylic;

- (void) removeAllTitles;
- (void) setAllTitles:(NSArray *)titles;

@end

@interface AZErgoManga (Tags)

- (NSArray *) tagNames;

- (void) removeAllTags;
- (void) toggle:(BOOL)on tag:(AZErgoMangaTag *)tag;
- (AZErgoMangaTag *) toggle:(BOOL)on tagWithGUID:(NSUInteger)guid;
- (AZErgoMangaTag *) toggle:(BOOL)on tagWithName:(NSString *)name;

- (BOOL) isComplete;
- (BOOL) isReaded;
- (BOOL) isDownloaded;
- (BOOL) isWebtoon;

@end

@interface AZErgoManga (CoreDataGeneratedAccessors)

- (void)addTagsObject:(AZErgoMangaTag *)value;
- (void)removeTagsObject:(AZErgoMangaTag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

- (void)addTitlesObject:(AZErgoMangaTitle *)value;
- (void)removeTitlesObject:(AZErgoMangaTitle *)value;
- (void)addTitles:(NSSet *)values;
- (void)removeTitles:(NSSet *)values;

@end
