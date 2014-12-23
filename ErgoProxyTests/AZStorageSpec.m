//
//  AZStorageSpec.m
//  ErgoProxy
//  Spec for AZStorage
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZStorage.h"

SPEC_BEGIN(AZStorageSpec)

describe(@"AZStorage", ^{
	it(@"should properly initialize", ^{
		AZStorage *instance = [AZStorage new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZStorage class]];
	});

	it(@"should ", ^{
		NSURL *url = [NSURL URLWithString:@"http://server.domen/"];
		AZStorage *instance = [AZStorage serverWithURL:url];

		[[instance.url should] equal:url];
	});
});

SPEC_END
