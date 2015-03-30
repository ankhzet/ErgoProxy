//
//  AZScanCleanFilter.h
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <GPUImage/GPUImage.h>
#import "AZScanCleaner.h"

@interface AZScanCleanFilter : GPUImageFilterGroup

@property (nonatomic) CGFloat edgeBlurRadius;
@property (nonatomic) CGFloat edgeThreshhold;
@property (nonatomic) CGFloat cannyBlurRadius;

@property (nonatomic, readonly) AZScanCleaner *cleaner;

+ (instancetype) filterWithCleaner:(AZScanCleaner *)cleaner;
+ (instancetype) filter;

@end
