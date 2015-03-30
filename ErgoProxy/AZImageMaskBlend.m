//
//  AZImageMaskBlend.m
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZImageMaskBlend.h"


NSString *const kGPUImageMaskBlendFragmentShaderString = SHADER_STRING
(
	varying vec2 textureCoordinate;
	varying vec2 textureCoordinate2;
	varying vec2 textureCoordinate3;

	uniform sampler2D inputImageTexture;
	uniform sampler2D inputImageTexture2;
	uniform sampler2D inputImageTexture3;

	uniform float intensity;

	void main() {
		vec4 colorA = texture2D(inputImageTexture, textureCoordinate);
		vec4 colorB = texture2D(inputImageTexture2, textureCoordinate2);
		float mix    = texture2D(inputImageTexture3, textureCoordinate2).r;

		gl_FragColor = mix(colorA, colorB, mix);
	}
);

@implementation AZImageMaskBlend

- (id)init {
	if (!(self = [super initWithFragmentShaderFromString:kGPUImageMaskBlendFragmentShaderString]))
		return self;

	return self;
}

@end

