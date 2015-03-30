//
//  AZImageFloatGaussianBlurFilter.m
//  ErgoProxy
//
//  Created by Ankh on 25.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZImageFloatGaussianBlurFilter.h"

@implementation AZImageFloatGaussianBlurFilter {
	GPUImageGaussianBlurFilter *gauss;
	GPUImageDissolveBlendFilter *dissolveBlend;
}
@synthesize blurRadiusInPixels = _blurRadiusInPixels;

- (id)init {
	if (!(self = [super init]))
		return self;

	dissolveBlend = [GPUImageDissolveBlendFilter new];
	[self addFilter:dissolveBlend];

	gauss = [GPUImageGaussianBlurFilter new];
	[self addFilter:gauss];

	[gauss addTarget:dissolveBlend atTextureLocation:1];

	self.initialFilters = @[gauss, dissolveBlend];
	self.terminalFilter = dissolveBlend;

	self.blurRadiusInPixels = 1.f;

	return self;
}

- (void) setBlurRadiusInPixels:(CGFloat)blurRadiusInPixels {
	CGFloat intPart = floor(blurRadiusInPixels);
	gauss.blurRadiusInPixels = intPart + 1.f;

	CGFloat fracPart = 1.f - (blurRadiusInPixels - intPart);

	dissolveBlend.mix = fracPart;
}

@end
