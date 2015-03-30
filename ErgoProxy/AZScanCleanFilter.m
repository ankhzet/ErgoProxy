//
//  AZScanCleanFilter.m
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZScanCleanFilter.h"
#import "AZImageMaskBlend.h"

@implementation AZScanCleanFilter {
	GPUImageSingleComponentGaussianBlurFilter *edgeGauss;
	GPUImageLuminanceThresholdFilter *edgeThreshold;
	GPUImageCannyEdgeDetectionFilter *canny;
}
@synthesize cleaner;

+ (instancetype) filter {
	AZScanCleaner *cleaner = [AZScanCleaner new];

	NSUInteger passes = 2;

	CGFloat levelsCut = (10.f / 255.f) / (float) passes;

	for (NSUInteger i = 0; i < passes; i++)
		[cleaner addPass];

	cleaner.basicBlur = 0.15f;
	//	cleaner.surfaceBlurRadius = 0.1f;
	cleaner.surfaceTreshold = 7.f;
	cleaner.levelsLowPass = levelsCut;
	cleaner.levelsGamma = 0.85f;
	cleaner.levelsHighPass = 1.f - levelsCut;
	cleaner.sharpness = 0.4f;

	AZScanCleanFilter *filter = [self filterWithCleaner:cleaner];

	filter.edgeBlurRadius = 2.f;
	filter.edgeThreshhold = 0.8f;
	filter.cannyBlurRadius = 2.f;

	return filter;
}

+ (instancetype) filterWithCleaner:(AZScanCleaner *)cleaner {
	return [[self alloc] initWithCleaner:cleaner];
}

- (id)initWithCleaner:(AZScanCleaner *)aCleaner {
	if (!(self = [super init]))
		return self;

	GPUImageGrayscaleFilter *luminance = [GPUImageGrayscaleFilter new];
	[self addFilter:luminance];

	edgeThreshold = [GPUImageLuminanceThresholdFilter new];
	[self addFilter:edgeThreshold];

	edgeGauss = [GPUImageSingleComponentGaussianBlurFilter new];
	[self addFilter:edgeGauss];

	GPUImageSingleComponentGaussianBlurFilter *maskBlur = [GPUImageSingleComponentGaussianBlurFilter new];
	[self addFilter:maskBlur];

	canny = [GPUImageCannyEdgeDetectionFilter new];
	[self addFilter:canny];

	GPUImageColorInvertFilter *invert = [GPUImageColorInvertFilter new];
	[self addFilter:invert];

//	GPUImageColorInvertFilter *invert2 = [GPUImageColorInvertFilter new];
//	[self addFilter:invert];

	AZImageMaskBlend *maskBlend = [AZImageMaskBlend new];
	[self addFilter:maskBlend];

	GPUImageMultiplyBlendFilter *maskBlend2 = [GPUImageMultiplyBlendFilter new];
	[self addFilter:maskBlend2];

	[self addFilter:cleaner = aCleaner];

	GPUImageSharpenFilter *sharpen = [GPUImageSharpenFilter new];
	[self addFilter:sharpen];

	GPUImageGammaFilter *maskGamma = [GPUImageGammaFilter new];
	[self addFilter:maskGamma];

	GPUImageUnsharpMaskFilter *unsharp = [GPUImageUnsharpMaskFilter new];
	[self addFilter:unsharp];

	[luminance addTarget:edgeGauss];
	[edgeGauss addTarget:edgeThreshold];
	[edgeThreshold addTarget:canny];
	[canny addTarget:invert];
	[invert addTarget:maskBlur];

	[maskBlur addTarget:maskGamma];

	[sharpen addTarget:unsharp];

	[unsharp addTarget:maskBlend];
//	[sharpen addTarget:maskBlend];
	[cleaner addTarget:maskBlend atTextureLocation:1];
	[maskGamma addTarget:maskBlend atTextureLocation:2];

	self.initialFilters = @[cleaner, luminance, sharpen];
	self.terminalFilter = maskBlend;

	self.edgeBlurRadius = 2.f;
	self.edgeThreshhold = 0.8f;
	self.cannyBlurRadius = 1.f;

	maskBlur.blurRadiusInPixels = 2.f;
	maskGamma.gamma = 3.f;

	sharpen.sharpness = 0.1f;
	unsharp.blurRadiusInPixels = 3.f;
	unsharp.intensity = 1.f;

	return self;
}

#pragma mark - Property accessors

- (void) setEdgeBlurRadius:(CGFloat)edgeBlurRadius {
	edgeGauss.blurRadiusInPixels = edgeBlurRadius;
}

- (CGFloat) edgeBlurRadius {
	return edgeGauss.blurRadiusInPixels;
}

- (void) setEdgeThreshhold:(CGFloat)edgeThreshhold {
	edgeThreshold.threshold = edgeThreshhold;
}

- (CGFloat) edgeThreshhold {
	return edgeThreshold.threshold;
}

- (void) setCannyBlurRadius:(CGFloat)cannyBlurRadius {
	canny.blurRadiusInPixels = cannyBlurRadius;
}

- (CGFloat) cannyBlurRadius {
	return canny.blurRadiusInPixels;
}

@end
