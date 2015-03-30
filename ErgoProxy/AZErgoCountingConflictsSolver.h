//
//  AZErgoCountingConflictsSolver.h
//  ErgoProxy
//
//  Created by Ankh on 27.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZErgoChapterProtocol.h"

@interface Chapter : NSObject <AZErgoChapterProtocol>

@property (nonatomic) NSInteger volume;
@property (nonatomic) float baseIdx;
@property (nonatomic) float idx;

+ (instancetype) chapter:(float)idx ofVolume:(NSInteger)volume;

@end


@interface AZErgoCountingConflictsSolver : NSObject

@property (nonatomic, readonly) NSArray *ordered;
@property (nonatomic, readonly) NSArray *volumes;
@property (nonatomic, readonly) NSDictionary *conflicts;

+ (instancetype) solverForChapters:(NSArray *)chapters;

- (void) solveConflicts;

@end

@interface AZErgoCountingConflictsSolver (Testing)

- (NSArray *) volumeChapters:(NSInteger)volume;

- (NSInteger) hasConflicts:(NSInteger)idx;
- (NSInteger) delta:(NSInteger)delta conflictsForIDX:(NSInteger)idx;

- (void) changeChapter:(Chapter *)chapter index:(NSInteger)index;

- (NSArray *) hasBonusChapters:(NSInteger)volume;
- (Chapter *) seekLower:(Chapter *)from;
- (NSArray *) between:(Chapter *)left and:(Chapter *)right;

- (void) solveShifts;
- (void) solveVolumeConflicts:(NSInteger)volume;

@end
