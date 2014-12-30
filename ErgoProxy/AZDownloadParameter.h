//
//  AZDownloadParameter.h
//  ErgoProxy
//
//  Created by Ankh on 23.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZCoreDataEntity.h"

@class AZDownloadParams;

@interface AZDownloadParameter : AZCoreDataEntity

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDecimalNumber * value;
@property (nonatomic, retain) AZDownloadParams *ownedBy;

+ (instancetype) param:(NSString *)paramName withValue:(NSDecimalNumber *)value;

@end
