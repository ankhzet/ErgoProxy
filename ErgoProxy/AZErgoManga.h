//
//  AZErgoManga.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

@class AZErgoMangaProgress, AZErgoMangaTag, AZErgoMangaTitle;

@interface AZErgoManga : AZCoreDataEntity

@property (nonatomic, retain) NSString * annotation;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) NSSet *titles;
@property (nonatomic, retain) AZErgoMangaProgress *progress;

- (NSString *) mainTitle;
- (NSArray *) additionalTitles;
- (NSArray *) titleEntities:(BOOL)cyrylic;

- (NSArray *) tagNames;

- (AZErgoMangaTag *) toggle:(BOOL)on tag:(NSUInteger)guid;

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
