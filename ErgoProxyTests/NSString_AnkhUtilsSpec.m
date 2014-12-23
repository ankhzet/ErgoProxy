//
//  NSString_AnkhUtilsSpec.m
//  ErgoProxy
//  Spec for NSString+AnkhUtils
//
//  Created by Ankh on 12.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "NSString+AnkhUtils.h"

SPEC_BEGIN(NSString_AnkhUtilsSpec)

describe(@"NSString+AnkhUtils", ^{
	it(@"should properly convert bytesizes with precission of 1", ^{
		NSDictionary *convertables =
		@{
			@(10): @"10.0B",
			@(1023): @"1023.0B",
			@(1024): @"1.0KB",
			@(1025): @"1.0KB",
			@(2024): @"1.9KB",
			@(2048): @"2.0KB",
			@(202020): @"197.2KB",
			};

		for (NSNumber *number in [convertables allKeys]) {
			NSString *cvt = [NSString cvtFileSize:[number unsignedIntegerValue] withPrec:1];
			[[cvt should] equal:convertables[number]];
		}
	});

	it(@"should properly convert bytesizes with precission of 2", ^{
		NSDictionary *convertables =
		@{
			@(10): @"10.00B",
			@(1023): @"1023.00B",
			@(1024): @"1.00KB",
			@(1025): @"1.00KB",
			@(2024): @"1.97KB",
			@(2048): @"2.00KB",
			@(202020): @"197.28KB",
			};

		for (NSNumber *number in [convertables allKeys]) {
			NSString *cvt = [NSString cvtFileSize:[number unsignedIntegerValue] withPrec:2];
			[[cvt should] equal:convertables[number]];
		}
	});

	it(@"should properly convert bytesizes with precission of 3", ^{
		NSDictionary *convertables =
		@{
			@(10): @"10.000B",
			@(1023): @"1023.000B",
			@(1024): @"1.000KB",
			@(1025): @"1.000KB",
			@(2024): @"1.976KB",
			@(2048): @"2.000KB",
			@(202020): @"197.285KB",
			};

		for (NSNumber *number in [convertables allKeys]) {
			NSString *cvt = [NSString cvtFileSize:[number unsignedIntegerValue] withPrec:3];
			[[cvt should] equal:convertables[number]];
		}
	});
});

SPEC_END
