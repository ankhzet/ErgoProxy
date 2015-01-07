//
//  AZErgoMangaTitle.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

@class AZErgoManga;

@interface AZErgoMangaTitle : AZCoreDataEntity

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) AZErgoManga *manga;

@end
