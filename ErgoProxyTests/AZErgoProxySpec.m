//
//  AZErgoProxySpec.m
//  ErgoProxy
//  Spec for AZErgoProxy
//
//  Created by Ankh on 27.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZErgoProxy.h"

SPEC_BEGIN(AZErgoProxySpec)

describe(@"AZErgoProxy", ^{
	it(@"should properly initialize", ^{
		AZErgoProxy *instance = [AZErgoProxy new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZErgoProxy class]];
	});

	it(@"should ", ^{
//		AZErgoProxy *instance = [AZErgoProxy new];

		
	});
});

SPEC_END
