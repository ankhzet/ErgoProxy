//
//  AZImageFloatGaussianBlurFilter.h
//  ErgoProxy
//
//  Created by Ankh on 25.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface AZImageFloatGaussianBlurFilter : GPUImageFilterGroup

@property (readwrite, nonatomic) CGFloat blurRadiusInPixels;

@end
