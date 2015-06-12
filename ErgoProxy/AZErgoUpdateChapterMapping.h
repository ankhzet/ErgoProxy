//
//  AZErgoUpdateChapterMapping.h
//  ErgoProxy
//
//  Created by Ankh on 02.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

@class AZErgoManga;
@interface AZErgoUpdateChapterMapping : AZCoreDataEntity

@property (nonatomic, retain) AZErgoManga *manga;
@property (nonatomic) NSUInteger volume;
@property (nonatomic) float sourceIDX;
@property (nonatomic) float mappedIDX;

@end
