//
//  AZErgoMangaProgress.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

@class AZErgoManga;

@interface AZErgoMangaProgress : AZCoreDataEntity

@property (nonatomic, retain) AZErgoManga *manga;

@property (nonatomic) float chapter;
@property (nonatomic) float chapters;
@property (nonatomic) NSUInteger page;
@property (nonatomic, retain) NSDate *updated;

+ (instancetype) progressInMangaNamed:(NSString *)mangaName;

- (void) setChapter:(float)current andPage:(NSUInteger)page;

- (BOOL) has:(float)lastChapter readed:(BOOL *)readed chapters:(float *)currentChapter;
- (BOOL) hasReaded;
- (BOOL) hasUnreaded;
- (BOOL) hasReadedAndUnreaded;

@end
