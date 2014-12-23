//
//  AZChapterSpec.m
//  ErgoProxy
//  Spec for AZChapter
//
//  Created by Ankh on 27.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZChapter.h"

SPEC_UTILS(AZChapterSpec)

SPEC_BODY(AZChapterSpec)

describe(@"AZChapter", ^{
	it(@"should properly initialize", ^{
		AZChapter *instance = [AZChapter new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZChapter class]];
	});

	it(@"should properly parse pages chap and index", ^{
		NSDictionary *pages = @{
														@"xxx_31.5_125.ext": @{@0:@31.5, @1:@125},
													 @"xxx_c32_125.ext":   @{@0:@32, @1:@125},
													 @"xxx_c33.5_125.ext": @{@0:@33.5, @1:@125},
													@"xxx_ch34.5_125.ext": @{@0:@34.5, @1:@125},
												@"xxx_chap35_125.ext":   @{@0:@35, @1:@125},

														@"xx123xxx_21.5_125.ext": @{@0:@21.5, @1:@125},
													 @"xx123xxx_c22_125.ext":   @{@0:@22, @1:@125},
													 @"xx123xxx_c23.5_125.ext": @{@0:@23.5, @1:@125},
													@"xx123xxx_ch24.5_125.ext": @{@0:@24.5, @1:@125},
												@"xx123xxx_chap25_125.ext":   @{@0:@25, @1:@125},

														@"xxx_61.5.ext": @{@0:@61.5},
											 @"xx123xxx_62.5.ext": @{@0:@62.5},
													 @"xxx_c63.ext":   @{@0:@63},
											@"xx123xxx_c64.ext":   @{@0:@64},
										 @"xx123xxx_ch65.5.ext": @{@0:@65.5},
									 @"xx123xxx_chap66.ext":   @{@0:@66},
														
													};

		for (NSString *sample in [pages allKeys]) {
			float chap = [pages[sample][@0] floatValue];
			float page = [pages[sample][@1] floatValue];

			AZPageChapterIndex index = [AZChapter decodeIndex:sample hasPageIDX:(pages[sample][@1] ? AZPageChapIDXDepthTillPage : AZPageChapIDXDepthTillChapter)];
			[[@(index.chapter) should] equal:chap withDelta:0.01];
			[[@(index.page) should] equal:page withDelta:0.01];
		}
	});


	it(@"should properly sort pages", ^{
		NSArray *pages = @[
											 @"xxx_ch1_1.ext",
											 @"xxx_ch1_2.ext",
											 @"xxx_ch1_3.5.ext",
											 @"xxx_ch1_4.ext",
											 @"xxx_ch1_5.ext",
											 @"xxx_ch1_6.ext",

											 @"xxx_ch1.5_1.ext",
											 @"xxx_ch1.5_2-4.ext",
											 @"xxx_ch1.6_5.ext",
											 @"xxx_ch1.6_6.ext",
											 @"xxx_ch1.6_7-10.ext",
											 @"xxx_ch1.6_11.ext",

											 @"xxx_ch2_1.ext",
											 @"xxx_ch2_2.ext",
											 @"xxx_ch2_3.ext",
											 @"xxx_ch2_4.ext",

											 @"xxx_ch3_1.ext",
											 @"xxx_ch3_2-7.ext",
											 @"xxx_ch3_8.ext",
											 @"xxx_ch3_9.ext",
											 @"xxx_ch3_10.ext",
											 ];


		NSMutableArray *rand = [NSMutableArray array], *copy = [pages mutableCopy];
		NSUInteger c;
		while ((c = [copy count])) {
			NSUInteger idx = random() % c;
			[rand addObject:copy[idx]];
			[copy removeObjectAtIndex:idx];
		}
		NSArray *sorted = [AZChapter sort:rand];

		[[theValue([pages isEqual:sorted]) should] beYes];
	});
});

SPEC_END
