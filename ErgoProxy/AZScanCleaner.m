//
//  AZScanCleaner.m
//  ErgoProxy
//
//  Created by Ankh on 25.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZScanCleaner.h"
#import "AZImageFloatGaussianBlurFilter.h"

@implementation AZScanCleanPass  {
	AZImageFloatGaussianBlurFilter *gaussian;
	GPUImageBilateralFilter *surface;
	GPUImageLevelsFilter *levels;
	GPUImageSharpenFilter *sharpen, *sharpen2;
}
@synthesize basicBlur, surfaceBlurRadius, surfaceTreshold, levelsLowPass, levelsGamma, levelsHighPass, sharpness;

- (id)init {
	if (!(self = [super init]))
		return self;

	[self addFilter:gaussian = [AZImageFloatGaussianBlurFilter new]];
	[self addFilter:surface = [GPUImageBilateralFilter new]];
	[self addFilter:levels = [GPUImageLevelsFilter new]];
	[self addFilter:sharpen = [GPUImageSharpenFilter new]];

	[gaussian addTarget:surface];
	[surface addTarget:sharpen];
	[sharpen addTarget:levels];

	self.initialFilters = @[gaussian];
	self.terminalFilter = levels;

//	self.basicBlur = 0.95f;
////	scanCleanFilter.cleaner.surfaceBlurRadius = 0.1f;
//	self.surfaceTreshold = 7.f;
//	self.levelsLowPass = 25/255.f;
//	self.levelsGamma = 0.85f;
//	self.levelsHighPass = 230/255.f;
//	self.sharpness = 0.4f;

	return self;
}

- (void) setBasicBlur:(GLfloat)aBasicBlur {
	gaussian.blurRadiusInPixels = basicBlur = aBasicBlur;
}

- (void) setSurfaceBlurRadius:(GLfloat)aSurfaceBlurRadius {
	surface.blurRadiusInPixels = surfaceBlurRadius = aSurfaceBlurRadius;
}

- (void) setSurfaceTreshold:(GLfloat)aSurfaceTreshold {
	surface.distanceNormalizationFactor = surfaceTreshold = aSurfaceTreshold;
}

- (void) setLevelsHighPass:(GLfloat)aLevelsHighPass {
	[levels setMin:levelsLowPass gamma:levelsGamma max:levelsHighPass = aLevelsHighPass];
}

- (void) setLevelsLowPass:(GLfloat)aLevelsLowPass {
	[levels setMin:levelsLowPass = aLevelsLowPass gamma:levelsGamma max:levelsHighPass];
}

- (void) setLevelsGamma:(GLfloat)aLevelsGamma {
	[levels setMin:levelsLowPass gamma:levelsGamma = aLevelsGamma max:levelsHighPass];
}

- (void) setSharpness:(GLfloat)aSharpness {
	sharpen.sharpness = sharpness = aSharpness;
}

@end

@implementation AZScanCleaner
@synthesize basicBlur, surfaceBlurRadius, surfaceTreshold, levelsLowPass, levelsGamma, levelsHighPass, sharpness;

- (AZScanCleanPass *) addPass {
	AZScanCleanPass *pass = [AZScanCleanPass new];

	[self addFilter:pass];

	if (![self.initialFilters count])
		self.initialFilters = @[pass];

	[self.terminalFilter removeAllTargets];
	[self.terminalFilter addTarget:pass];
	self.terminalFilter = pass;

	return pass;
}

#pragma mark - Filter parameters

- (void) setBasicBlur:(GLfloat)aBasicBlur {
	for (AZScanCleanPass *pass in self.filtersEnumerator)
		pass.basicBlur = basicBlur = aBasicBlur;
}

- (void) setSurfaceBlurRadius:(GLfloat)aSurfaceBlurRadius {
	for (AZScanCleanPass *pass in self.filtersEnumerator)
		pass.surfaceBlurRadius = surfaceBlurRadius = aSurfaceBlurRadius;
}

- (void) setSurfaceTreshold:(GLfloat)aSurfaceTreshold {
	for (AZScanCleanPass *pass in self.filtersEnumerator)
		pass.surfaceTreshold = surfaceTreshold = aSurfaceTreshold;
}

- (void) setLevelsHighPass:(GLfloat)aLevelsHighPass {
	for (AZScanCleanPass *pass in self.filtersEnumerator)
		pass.levelsHighPass = levelsHighPass = aLevelsHighPass;
}

- (void) setLevelsGamma:(GLfloat)aLevelsGamma {
	for (AZScanCleanPass *pass in self.filtersEnumerator)
		pass.levelsGamma = levelsGamma = aLevelsGamma;
}

- (void) setLevelsLowPass:(GLfloat)aLevelsLowPass {
	for (AZScanCleanPass *pass in self.filtersEnumerator)
		pass.levelsLowPass = levelsLowPass = aLevelsLowPass;
}

- (void) setSharpness:(GLfloat)aSharpness {
	for (AZScanCleanPass *pass in self.filtersEnumerator)
		pass.sharpness = sharpness = aSharpness;
}

@end
