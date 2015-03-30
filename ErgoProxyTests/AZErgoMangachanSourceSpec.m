//
//  AZErgoMangachanSourceSpec.m
//  ErgoProxy
//  Spec for AZErgoMangachanSource
//
//  Created by Ankh on 03.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZErgoMangachanSource.h"

#import "AZErgoUpdatesAPI.h"
#import "AZErgoUpdatesCommons.h"

@interface AZTestMCUS : AZErgoMangachanSource

@end

@implementation AZTestMCUS

- (NSString *) serverURL {
	return [[self class] serverURL];
}

- (AZErgoUpdatesSourceDescription *) descriptor {
	return (id)self;
}

@end

SPEC_BEGIN(AZErgoMangachanSourceSpec)

describe(@"AZErgoMangachanSource", ^{

	context(@"when parse documents", ^{

		it(@"should proprly perse completeness", ^{
			AZErgoMangachanSource *source = [AZTestMCUS new];

			NSString *g1 = @"20187-shino-chan-wa-jibun-no-namae-ga-ienai";
			NSString *g2 = @"3337-the-qwaser-of-stigmata";

			AZErgoUpdateWatch *watch = [AZErgoUpdateWatch mock];
			[[watch should] receive:@selector(genData) andReturn:g1 withCountAtLeast:1];
			AZErgoUpdateWatch *watch2 = [AZErgoUpdateWatch mock];
			[[watch2 should] receive:@selector(genData) andReturn:g2 withCountAtLeast:1];

			__block BOOL y = NO;
			[AZ_API(ErgoUpdates) updates:source  watch:watch infoWithCompletion:^(BOOL isOk, AZErgoUpdateMangaInfo *info) {

				[[@(info->isComplete) should] beYes];

				y = YES;
			}];

			while (!y);

			y = NO;
			[AZ_API(ErgoUpdates) updates:source  watch:watch2 infoWithCompletion:^(BOOL isOk, AZErgoUpdateMangaInfo *info) {

				[[@(info->isComplete) should] beNo];
				
				y = YES;
			}];
			
			while (!y);
		});
	});

	it(@"should properly parse plain case", ^{
		AZErgoMangachanSource *ms = [AZErgoMangachanSource new];

		NSString *t1 = @"Title 1";
		NSString *t2 = @"Title 2";

		NSSet *p1 = [ms parseTitles:[NSString stringWithFormat:@"%@ (%@)", t1, t2]];
		NSSet *p2 = [ms parseTitles:[NSString stringWithFormat:@"%@ (%@)", t2, t1]];

		[expect(p1) equal:[NSSet setWithArray:@[t1, t2]]];
		[expect(p2) equal:[NSSet setWithArray:@[t1, t2]]];
	});

	it(@"should properly parse difficult case", ^{
		AZErgoMangachanSource *ms = [AZErgoMangachanSource new];

		NSString *t1 = @"Title 1";
		NSString *t2 = @"Title 2";
		NSString *t3 = @"Title 3 (subtitle)";
		NSString *t4 = @"Title 4 (subtitle)";

		NSSet *p1 = [ms parseTitles:[NSString stringWithFormat:@"%@ (%@)", t1, t3]];
		NSSet *p2 = [ms parseTitles:[NSString stringWithFormat:@"%@ (%@)", t2, t3]];
		NSSet *p3 = [ms parseTitles:[NSString stringWithFormat:@"%@ (%@)", t3, t1]];
		NSSet *p4 = [ms parseTitles:[NSString stringWithFormat:@"%@ (%@)", t3, t4]];

		[expect(p1) equal:[NSSet setWithArray:@[t1, t3]]];
		[expect(p2) equal:[NSSet setWithArray:@[t2, t3]]];
		[expect(p3) equal:[NSSet setWithArray:@[t3, t1]]];
		[expect(p4) equal:[NSSet setWithArray:@[t3, t4]]];
	});
});

SPEC_END
