//
//  AZErgoDownloadsPriority.h
//  ErgoProxy
//
//  Created by Ankh on 04.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"

@class AZErgoManga;

@interface AZErgoDownloadsPriority : AZCoreDataEntity

@property (nonatomic, retain) AZErgoManga *manga;
@property (nonatomic) NSUInteger order;

@end
