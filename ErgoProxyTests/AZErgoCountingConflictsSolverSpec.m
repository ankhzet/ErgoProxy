//
//  AZErgoCountingConflictsSolverSpec.m
//  ErgoProxy
//  Spec for AZErgoCountingConflictsSolver
//
//  Created by Ankh on 27.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZErgoCountingConflictsSolver.h"

@interface NSString (ConflictsTestsUtils)

- (NSArray *) chaptersArray;

@end

@implementation NSString (ConflictsTestsUtils)

- (Chapter *) asChapter {
	NSArray *sub = [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
									componentsSeparatedByString:@"-"];
	if ([sub count] < 2)
		return nil;

	float idx = [sub[1] floatValue];
	NSInteger volume = [sub[0] integerValue];
	return [Chapter chapter:idx ofVolume:volume];
}

- (NSArray *) chaptersArray {
	NSMutableArray *result = [NSMutableArray array];

	NSArray *parts = [self componentsSeparatedByString:@","];
	for (NSString *c in parts) {
		Chapter *chapter = [c asChapter];
		if (chapter)
			[result addObject:chapter];
	}

	return result;
}


@end

SPEC_UTILS(AZErgoCountingConflictsSolverSpec)

#define test(chapters1, chapters2) ({\
[[chapters1 shouldNot] beNil];\
[[chapters2 shouldNot] beNil];\
[[chapters1 should] equal:chapters2];\
})

SPEC_BODY

describe(@"AZErgoCountingConflictsSolver", ^{

	it(@"should properly initialize", ^{
		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZErgoCountingConflictsSolver class]];
	});

	it(@"should properly sort chapters", ^{
		NSArray *test1Q1 = [@"1-1,3-2,2-1,1-3,1-2,1-4,3-1,4-0,5-1" chaptersArray];
		NSArray *test1R1 = [@"1-1,1-2,1-3,1-4,2-1,3-1,3-2,4-0,5-1" chaptersArray];

		test([[AZErgoCountingConflictsSolver solverForChapters:test1Q1] ordered], test1R1);


		NSArray *test1Q2 = [@"1-1,1-2.5,1-2,1-4,2-1,5-1,3-1,3-2" chaptersArray];
		NSArray *test1R2 = [@"1-1,1-2,1-2.5,1-4,2-1,3-1,3-2,5-1" chaptersArray];

		test([[AZErgoCountingConflictsSolver solverForChapters:test1Q2] ordered], test1R2);
	});

	it(@"should properly fetch volumes", ^{
		NSArray *test2Q1 = [@"1-1,3-2,2-1,1-3,1-2,1-4,3-1,4-0,5-1" chaptersArray];
		NSArray *test2Q2 = [@"1-1,1-2.5,1-2,1-4,2-1,5-1,3-1,3-2" chaptersArray];

		NSArray *volumes1 = [[AZErgoCountingConflictsSolver solverForChapters:test2Q1] volumes];

		[[volumes1 shouldNot] beNil];
		[[volumes1 should] equal:@[@1, @2, @3, @4, @5]];

		NSArray *volumes2 = [[AZErgoCountingConflictsSolver solverForChapters:test2Q2] volumes];

		[[volumes2 shouldNot] beNil];
		[[volumes2 should] equal:@[@1, @2, @3, @5]];
	});


	it(@"should properly fetch conflicts", ^{
		NSArray *test3Q1 = [@"1-1,1-2,1-3,1-4.5,2-1,3-1.5,3-2,4-0,5-1" chaptersArray];

		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test3Q1];

		NSDictionary *conflicts = [instance conflicts];
		[[conflicts shouldNot] beNil];

		NSArray *sorted = [[conflicts allKeys] sortedArrayUsingSelector:@selector(compare:)];

		[[sorted should] equal:@[@0, @100, @150, @200, @300, @450]];

		NSMutableArray *counts = [NSMutableArray array];
		for (NSNumber *key in sorted)
			[counts addObject:conflicts[key]];

		[[counts should] equal:@[@1, @3, @1, @2, @1, @1]];

	});

	it(@"should detect conflicts on idx change", ^{
		NSArray *test4Q1 = [@"1-1,1-2,1-3,1-4.5,2-1,3-1.5,3-2,4-0,5-1" chaptersArray];

		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test4Q1];

		[[@([instance hasConflicts:_IDX(0)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(1)]) should] equal:@2];
		[[@([instance hasConflicts:_IDX(1.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(2)]) should] equal:@1];
		[[@([instance hasConflicts:_IDX(2.5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(3)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(4)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(4.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(5)]) should] equal:@(-1)];

		[instance delta:1 conflictsForIDX:_IDX(0)];
		[instance delta:1 conflictsForIDX:_IDX(1)];
		[instance delta:1 conflictsForIDX:_IDX(4)];
		[instance delta:1 conflictsForIDX:_IDX(5)];

		[[@([instance hasConflicts:_IDX(0)]) should] equal:@1];
		[[@([instance hasConflicts:_IDX(1)]) should] equal:@3];
		[[@([instance hasConflicts:_IDX(1.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(2)]) should] equal:@1];
		[[@([instance hasConflicts:_IDX(2.5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(3)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(4)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(4.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(5)]) should] equal:@0];

		[instance delta:-1 conflictsForIDX:_IDX(1.5)];
		[instance delta:-1 conflictsForIDX:_IDX(2.5)];
		[instance delta:-1 conflictsForIDX:_IDX(3)];
		[instance delta:-1 conflictsForIDX:_IDX(5)];

		[[@([instance hasConflicts:_IDX(0)]) should] equal:@1];
		[[@([instance hasConflicts:_IDX(1)]) should] equal:@3];
		[[@([instance hasConflicts:_IDX(1.5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(2)]) should] equal:@1];
		[[@([instance hasConflicts:_IDX(2.5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(3)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(4)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(4.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(5)]) should] equal:@(-1)];

		NSArray *chapters = [instance ordered];
		Chapter *c1 = chapters[0];
		Chapter *c2 = chapters[1];
		Chapter *c3 = chapters[2];
		Chapter *c4 = chapters[3];

		[[c1 should] equal:[@"1-1.f" asChapter]];
		[[c2 should] equal:[@"1-2.f" asChapter]];
		[[c3 should] equal:[@"1-3.f" asChapter]];
		[[c4 should] equal:[@"1-4.5f" asChapter]];

		[instance changeChapter:c1 index:_IDX(10)];
		[instance changeChapter:c2 index:_IDX(1)];
		[instance changeChapter:c3 index:_IDX(4)];
		[instance changeChapter:c4 index:_IDX(2.5)];

		[[@([instance hasConflicts:_IDX(0)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(1)]) should] equal:@2];
		[[@([instance hasConflicts:_IDX(1.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(2)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(2.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(3)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(4)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(4.5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(10)]) should] equal:@0];

		[instance changeChapter:c1 index:_IDX(5)];
		[instance changeChapter:c4 index:_IDX(5)];

		[[@([instance hasConflicts:_IDX(0)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(1)]) should] equal:@2];
		[[@([instance hasConflicts:_IDX(1.5)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(2)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(2.5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(3)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(4)]) should] equal:@0];
		[[@([instance hasConflicts:_IDX(4.5)]) should] equal:@(-1)];
		[[@([instance hasConflicts:_IDX(5)]) should] equal:@1];
		[[@([instance hasConflicts:_IDX(10)]) should] equal:@(-1)];

	});

	it(@"should properly fetch volume chapters", ^{
		NSArray *test5Q1 = [@"1-1,1-2,1-3,1-4.5,2-1,3-1.5,3-2,4-0,5-1" chaptersArray];

		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test5Q1];

		[instance delta:1 conflictsForIDX:_IDX(0)];
		[instance delta:1 conflictsForIDX:_IDX(1)];
		[instance delta:1 conflictsForIDX:_IDX(4)];
		[instance delta:1 conflictsForIDX:_IDX(5)];

		test([instance volumeChapters:1], [@"1-1,1-2,1-3,1-4.5" chaptersArray]);
		test([instance volumeChapters:2], [@"2-1" chaptersArray]);
		test([instance volumeChapters:3], [@"3-1.5,3-2" chaptersArray]);
		test([instance volumeChapters:4], [@"4-0" chaptersArray]);
		test([instance volumeChapters:5], [@"5-1" chaptersArray]);

		NSArray *chapters = [instance ordered];
		Chapter *c1 = chapters[0];
		Chapter *c2 = chapters[2];
		Chapter *c3 = chapters[4];
		Chapter *c4 = chapters[6];

		[[c1 should] equal:[@"1-1.f" asChapter]];
		[[c2 should] equal:[@"1-3.f" asChapter]];
		[[c3 should] equal:[@"2-1.f" asChapter]];
		[[c4 should] equal:[@"3-2.f" asChapter]];

		[instance changeChapter:c1 index:_IDX(10)];
		[instance changeChapter:c2 index:_IDX(1)];
		[instance changeChapter:c3 index:_IDX(4)];
		[instance changeChapter:c4 index:_IDX(2.5)];

		test([instance volumeChapters:1], [@"1-10,1-2,1-1,1-4.5" chaptersArray]);
		test([instance volumeChapters:2], [@"2-4" chaptersArray]);
		test([instance volumeChapters:3], [@"3-1.5,3-2.5" chaptersArray]);
		test([instance volumeChapters:4], [@"4-0" chaptersArray]);
		test([instance volumeChapters:5], [@"5-1" chaptersArray]);

		[instance changeChapter:c1 index:_IDX(5)];
		[instance changeChapter:c4 index:_IDX(5)];

		test([instance volumeChapters:1], [@"1-5,1-2,1-1,1-4.5" chaptersArray]);
		test([instance volumeChapters:2], [@"2-4" chaptersArray]);
		test([instance volumeChapters:3], [@"3-1.5,3-5" chaptersArray]);
		test([instance volumeChapters:4], [@"4-0" chaptersArray]);
		test([instance volumeChapters:5], [@"5-1" chaptersArray]);


	});

	it(@"should properly fetch bonus chapters", ^{
		NSArray *test6Q1 = [@"1-1,1-2,1-3,1-4.5,2-1,3-1.5,3-2,4-0,5-1" chaptersArray];

		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test6Q1];

		test([instance volumeChapters:1], [@"1-1,1-2,1-3,1-4.5" chaptersArray]);
		test([instance volumeChapters:2], [@"2-1" chaptersArray]);
		test([instance volumeChapters:3], [@"3-1.5,3-2" chaptersArray]);
		test([instance volumeChapters:4], [@"4-0" chaptersArray]);
		test([instance volumeChapters:5], [@"5-1" chaptersArray]);

		[[[instance hasBonusChapters:1] should] equal:[@"1-4.5" chaptersArray]];
		[[[instance hasBonusChapters:2] should] equal:[@"" chaptersArray]];
		[[[instance hasBonusChapters:3] should] equal:[@"3-1.5" chaptersArray]];
		[[[instance hasBonusChapters:4] should] equal:[@"" chaptersArray]];
		[[[instance hasBonusChapters:5] should] equal:[@"" chaptersArray]];

		NSArray *chapters = [instance ordered];
		Chapter *c1 = chapters[0];
		Chapter *c2 = chapters[2];
		Chapter *c3 = chapters[4];
		Chapter *c4 = chapters[6];

		[[c1 should] equal:[@"1-1.f" asChapter]];
		[[c2 should] equal:[@"1-3.f" asChapter]];
		[[c3 should] equal:[@"2-1.f" asChapter]];
		[[c4 should] equal:[@"3-2.f" asChapter]];

		[instance changeChapter:c1 index:_IDX(10)];
		[instance changeChapter:c2 index:_IDX(1)];
		[instance changeChapter:c3 index:_IDX(4)];
		[instance changeChapter:c4 index:_IDX(2.5)];

		[[[instance hasBonusChapters:1] should] equal:[@"1-4.5" chaptersArray]];
		[[[instance hasBonusChapters:2] should] equal:[@"" chaptersArray]];
		[[[instance hasBonusChapters:3] should] equal:[@"3-1.5,3-2.5" chaptersArray]];
		[[[instance hasBonusChapters:4] should] equal:[@"" chaptersArray]];
		[[[instance hasBonusChapters:5] should] equal:[@"" chaptersArray]];


		[instance changeChapter:c1 index:_IDX(5.1f)];
		[instance changeChapter:c4 index:_IDX(5)];

		[[[instance hasBonusChapters:1] should] equal:[@"1-5.1,1-4.5" chaptersArray]];
		[[[instance hasBonusChapters:2] should] equal:[@"" chaptersArray]];
		[[[instance hasBonusChapters:3] should] equal:[@"3-1.5" chaptersArray]];
		[[[instance hasBonusChapters:4] should] equal:[@"" chaptersArray]];
		[[[instance hasBonusChapters:5] should] equal:[@"" chaptersArray]];

	});

	it(@"should seek to nearest non-bonus", ^{
		NSArray *test7Q1 = [@"0-5,0-5.1,1-1,1-2,1-2.1,1-10,1-3,1-3.1,1-4.5,2-1,3-1.5,3-2,4-0,5-1" chaptersArray];

		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test7Q1];

		NSArray *chapters = [instance ordered];
		Chapter *c0_51 = chapters[1];
		Chapter *c1_20 = chapters[3];
		Chapter *c1_21 = chapters[4];
		Chapter *c1_45 = chapters[7];
		Chapter *c2_10 = chapters[9];

		[[c0_51 should] equal:[@"0-5.1f" asChapter]];
		[[c1_21 should] equal:[@"1-2.1f" asChapter]];
		[[c1_45 should] equal:[@"1-4.5f" asChapter]];
		[[c2_10 should] equal:[@"2-1.0f" asChapter]];

		[expect([instance seekLower:c0_51]) equal:[@"0-5" asChapter]];
		[expect([instance seekLower:c1_21]) equal:[@"1-2" asChapter]];
		[expect([instance seekLower:c1_45]) equal:[@"1-3" asChapter]];
		[expect([instance seekLower:c2_10]) beNil];

		[instance changeChapter:c0_51 index:_IDX(10)];
		[instance changeChapter:c1_20 index:_IDX(2.4)];
		[instance changeChapter:c1_45 index:_IDX(4)];
		[instance changeChapter:c2_10 index:_IDX(2.5)];

		[expect([instance seekLower:c0_51]) equal:[@"0-5" asChapter]];
		[expect([instance seekLower:c1_21]) equal:[@"1-1" asChapter]];
		[expect([instance seekLower:c1_45]) equal:[@"1-3" asChapter]];
		[expect([instance seekLower:c2_10]) beNil];

	});

	it(@"should extract chapters between other two", ^{
		NSArray *test8Q1 = [@"0-5,0-5.1,1-1,1-2,1-2.1,1-10,1-3,1-3.1,1-4.5,2-1,3-1.5,3-2,4-0,5-1" chaptersArray];

		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test8Q1];

		NSArray *chapters = [instance ordered];
		Chapter *c0_50 = chapters[0];
		Chapter *c0_51 = chapters[1];
		Chapter *c1_10 = chapters[2];
		Chapter *c1_20 = chapters[3];
		Chapter *c1_21 = chapters[4];
		Chapter *c1_30 = chapters[5];
		Chapter *c1_31 = chapters[6];
		Chapter *c1_45 = chapters[7];
		Chapter *c1_100= chapters[8];
		Chapter *c2_10 = chapters[9];
		Chapter *c3_15 = chapters[10];
		Chapter *c3_20 = chapters[11];
		Chapter *c4_00 = chapters[12];
		Chapter *c5_10 = chapters[13];

		[[c0_50 should] equal:[@"0-5.0f" asChapter]];
		[[c0_51 should] equal:[@"0-5.1f" asChapter]];
		[[c1_10 should] equal:[@"1-1.0f" asChapter]];
		[[c1_20 should] equal:[@"1-2.0f" asChapter]];
		[[c1_21 should] equal:[@"1-2.1f" asChapter]];
		[[c1_30 should] equal:[@"1-3.0f" asChapter]];
		[[c1_31 should] equal:[@"1-3.1f" asChapter]];
		[[c1_45 should] equal:[@"1-4.5f" asChapter]];
		[[c1_100 should]equal:[@"1-10.0f"asChapter]];
		[[c2_10 should] equal:[@"2-1.0f" asChapter]];
		[[c3_15 should] equal:[@"3-1.5f" asChapter]];
		[[c3_20 should] equal:[@"3-2.0f" asChapter]];
		[[c4_00 should] equal:[@"4-0.0f" asChapter]];
		[[c5_10 should] equal:[@"5-1.0f" asChapter]];

		[[[instance between:c0_50 and:c0_51] should] equal:@[]];
		[[[instance between:c2_10 and:c2_10] should] equal:@[]];
		[[[instance between:c3_15 and:c3_20] should] equal:@[]];
		[[[instance between:c4_00 and:c4_00] should] equal:@[]];
		[[[instance between:c5_10 and:c5_10] should] equal:@[]];

		[[[instance between:c1_10 and:c1_100]should] equal:@[c1_20, c1_21, c1_30, c1_31, c1_45]];
		[[[instance between:c1_100 and:c1_10]should] equal:@[c1_20, c1_21, c1_30, c1_31, c1_45]];

		[[[instance between:c1_20 and:c1_10] should] equal:@[]];
		[[[instance between:c1_21 and:c1_100]should] equal:@[c1_30, c1_31, c1_45]];
		[[[instance between:c1_20 and:c1_31] should] equal:@[c1_21, c1_30]];
		[[[instance between:c1_31 and:c1_10] should] equal:@[c1_20, c1_21, c1_30]];

		[instance changeChapter:c0_51 index:_IDX(10)];
		[instance changeChapter:c1_20 index:_IDX(2.4)];
		[instance changeChapter:c1_45 index:_IDX(4)];

		[[[instance between:c1_10 and:c1_100]should] equal:@[c1_20, c1_21, c1_30, c1_31, c1_45]];
		[[[instance between:c1_100 and:c1_10]should] equal:@[c1_20, c1_21, c1_30, c1_31, c1_45]];

		[[[instance between:c1_20 and:c1_10] should] equal:@[]];
		[[[instance between:c1_21 and:c1_100]should] equal:@[c1_30, c1_31, c1_45]];
		[[[instance between:c1_20 and:c1_31] should] equal:@[c1_21, c1_30]];
		[[[instance between:c1_31 and:c1_10] should] equal:@[c1_20, c1_21, c1_30]];
	});

	it(@"should properly resolve simple tasks", ^{
		NSArray *test9Q1 = [@"1-1,1-2,1-3,1-4  ,1-5  ,2-4,2-5,3-6,3-7,3-8,3-9  ,4-9,4-10" chaptersArray];

		NSArray *test9R1 = [@"1-1,1-2,1-3,1-3.5,1-3.6,2-4,2-5,3-6,3-7,3-8,3-9  ,4-9,4-10" chaptersArray];
		NSArray *test9R2 = [@"1-1,1-2,1-3,1-3.5,1-3.6,2-4,2-5,3-6,3-7,3-8,3-8.5,4-9,4-10" chaptersArray];
		//		NSArray *test9R3 = [@"1-1,1-2,1-3,1-3.5,1-3.6,2-4,2-5,3-6,3-7,3-8,3-8.5,4-9,4-10" chaptersArray];

		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test9Q1];

		[instance solveVolumeConflicts:1];
		[[[instance ordered] should] equal:test9R1];

		[instance solveVolumeConflicts:2];
		[[[instance ordered] should] equal:test9R1];

		[instance solveVolumeConflicts:3];
		[[[instance ordered] should] equal:test9R2];

		[instance solveVolumeConflicts:4];
		[[[instance ordered] should] equal:test9R2];
	});

	it(@"should properly resolve shift errors", ^{
		NSArray *test9Q1 = [@"1-1, 1-2, 2-1, 2-2, 2-3, 3-1, 3-2, 3-3, 4-1, 4-2 , 4-3 , 5-1   , 6-1 , 6-14" chaptersArray];
		NSArray *test9Q2 = [@"1-1, 2-1, 2-2, 2-3, 3-5, 3-1, 3-2, 3-3, 4-1, 4-2 , 4-3 , 5-1   , 6-1 , 6-14" chaptersArray];
		NSArray *test9Q3 = [@"1-1, 2-1, 3-1, 3-2, 3-3, 3-4, 4-1, 4-2, 4-3, 4-4 , 4-5 , 4-13  , 5-1 , 5-12" chaptersArray];

		NSArray *test9R1 = [@"1-1, 1-2, 2-3, 2-4, 2-5, 3-6, 3-7, 3-8, 4-9, 4-10, 4-11, 5-12  , 6-13, 6-14" chaptersArray];
		NSArray *test9R2 = [@"1-1, 2-2, 2-3, 2-4, 3-5, 3-6, 3-7, 3-8, 4-9, 4-10, 4-11, 5-12  , 6-13, 6-14" chaptersArray];
		NSArray *test9R3 = [@"1-1, 2-2, 3-3, 3-4, 3-5, 3-6, 4-6, 4-7, 4-8, 4-9 , 4-10, 4-13  , 5-11, 5-12" chaptersArray];

//		NSLog(@"\n\n B0 -> %@", [test9Q1 componentsJoinedByString:@" "]);
		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test9Q1];
		[instance solveShifts];
//		NSLog(@"\n R0 -> %@\n", [[instance ordered] componentsJoinedByString:@" "]);
//		NSLog(@"\n RX -> %@\n\n", [test9R1 componentsJoinedByString:@" "]);


		[[[instance ordered] should] equal:test9R1];

//		NSLog(@"\n\n B1 -> %@", [test9Q2 componentsJoinedByString:@" "]);
		AZErgoCountingConflictsSolver *instance2 = [AZErgoCountingConflictsSolver solverForChapters:test9Q2];
		[instance2 solveShifts];
//		NSLog(@"\n R1 -> %@\n", [[instance2 ordered] componentsJoinedByString:@" "]);
//		NSLog(@"\n RX -> %@\n\n", [test9R2 componentsJoinedByString:@" "]);


		[[[instance2 ordered] should] equal:test9R2];

//		NSLog(@"\n\n B2 -> %@", [test9Q3 componentsJoinedByString:@" "]);
		AZErgoCountingConflictsSolver *instance3 = [AZErgoCountingConflictsSolver solverForChapters:test9Q3];
		[instance3 solveShifts];
//		NSLog(@"\n R2 -> %@\n", [[instance3 ordered] componentsJoinedByString:@" "]);
//		NSLog(@"\n RX -> %@\n\n", [test9R3 componentsJoinedByString:@" "]);


		[[[instance3 ordered] should] equal:test9R3];
});

	it(@"should properly resolve all errors", ^{
		NSArray *test10Q1 = [@"1-1, 1-2, 2-1, 2-2, 2-3, 3-6, 3-7, 3-8, 3-9  , 3-10 , 4-9, 4-10, 5-11" chaptersArray];

		NSArray *test10Q2 = [@"1-1,1-2,2-3,2-4,2-5,3-6,3-7,3-8,3-9,3-10,4-11,4-12,4-13,4-15, 4-16,5-5,5-6,5-7,5-8,5-9,5-10,5-11,5-12,5-13,5-14,5-15,5-16,5-17" chaptersArray];

		NSArray *test10R1 = [@"1-1, 1-2, 2-3, 2-4, 2-5, 3-6, 3-7, 3-8, 3-8.5, 3-8.6, 4-9, 4-10, 5-11" chaptersArray];

		NSArray *test10R2 = [@"1-1,1-2,2-3,2-3.3,2-3.4,3-3.5,3-3.6,3-3.7,3-3.8,3-3.9,4-4,4-4.5,4-4.6,4-4.7, 4-4.8,5-5,5-6,5-7,5-8,5-9,5-10,5-11,5-12,5-13,5-14,5-15,5-16,5-17" chaptersArray];

		//		NSLog(@"\n\n B0 -> %@", [test10Q1 componentsJoinedByString:@" "]);
		AZErgoCountingConflictsSolver *instance = [AZErgoCountingConflictsSolver solverForChapters:test10Q1];
		[instance solveConflicts];
		//		NSLog(@"\n R0 -> %@\n", [[instance ordered] componentsJoinedByString:@" "]);
		//		NSLog(@"\n RX -> %@\n\n", [test10R1 componentsJoinedByString:@" "]);
		[[[instance ordered] should] equal:test10R1];

		NSLog(@"\n\n B0 -> %@", [test10Q2 componentsJoinedByString:@" "]);
		AZErgoCountingConflictsSolver *instance2 = [AZErgoCountingConflictsSolver solverForChapters:test10Q2];
		[instance2 solveConflicts];
		NSLog(@"\n R0 -> %@\n", [[instance2 ordered] componentsJoinedByString:@" "]);
		NSLog(@"\n RX -> %@\n\n", [test10R2 componentsJoinedByString:@" "]);
		[[[instance2 ordered] should] equal:test10R2];
});
});

SPEC_END
