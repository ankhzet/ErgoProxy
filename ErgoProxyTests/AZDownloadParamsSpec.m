//
//  AZDownloadParamsSpec.m
//  ErgoProxy
//  Spec for AZDownloadParams
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZDownloadParams.h"

SPEC_BEGIN(AZDownloadParamsSpec)

describe(@"AZDownloadParams", ^{
	it(@"should properly initialize", ^{
		AZDownloadParams *instance = [AZDownloadParams new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZDownloadParams class]];
	});

	it(@"should ", ^{
		NSNumber *maxW1 = @1600, *maxH1 = @1300, *quality1 = @60;
		NSNumber *maxW2 = @1500, *maxH2 = @1200, *quality2 = @50;

		AZDownloadParams *params1 = [AZDownloadParams params:@{
																													 kDownloadParamMaxWidth: maxW1,
																													 kDownloadParamMaxHeight: maxH1,
																													 kDownloadParamQuality: quality1,
																													 }];

		[[[params1 downloadParameter:kDownloadParamMaxWidth] should] equal:maxW1];
		[[[params1 downloadParameter:kDownloadParamMaxHeight] should] equal:maxH1];
		[[[params1 downloadParameter:kDownloadParamQuality] should] equal:quality1];

		AZDownloadParams *params2 = [AZDownloadParams params:@{
																													 kDownloadParamMaxWidth: maxW2,
																													 kDownloadParamMaxHeight: maxH2,
																													 kDownloadParamQuality: quality2,
																													 }];

		[[[params2 downloadParameter:kDownloadParamMaxWidth] should] equal:maxW2];
		[[[params2 downloadParameter:kDownloadParamMaxHeight] should] equal:maxH2];
		[[[params2 downloadParameter:kDownloadParamQuality] should] equal:quality2];

		[[[params1 hashed] shouldNot] beNil];
		[[[params2 hashed] shouldNot] beNil];

		[[[params1 hashed] shouldNot] equal:[params2 hashed]];
});
});

SPEC_END
