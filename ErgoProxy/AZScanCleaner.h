//
//  AZScanCleaner.h
//  ErgoProxy
//
//  Created by Ankh on 25.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@interface AZScanCleanPass : GPUImageFilterGroup

@property (nonatomic) GLfloat basicBlur;

@property (nonatomic) GLfloat surfaceBlurRadius;
@property (nonatomic) GLfloat surfaceTreshold;

@property (nonatomic) GLfloat levelsLowPass;
@property (nonatomic) GLfloat levelsGamma;
@property (nonatomic) GLfloat levelsHighPass;

@property (nonatomic) GLfloat sharpness;


@end

@interface AZScanCleaner : GPUImageFilterGroup

@property (nonatomic) GLfloat basicBlur;

@property (nonatomic) GLfloat surfaceBlurRadius;
@property (nonatomic) GLfloat surfaceTreshold;

@property (nonatomic) GLfloat levelsLowPass;
@property (nonatomic) GLfloat levelsGamma;
@property (nonatomic) GLfloat levelsHighPass;

@property (nonatomic) GLfloat sharpness;

- (id) addPass;

@end
