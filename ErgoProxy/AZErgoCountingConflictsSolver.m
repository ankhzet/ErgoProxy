//
//  AZErgoCountingConflictsSolver.m
//  ErgoProxy
//
//  Created by Ankh on 27.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoCountingConflictsSolver.h"

@implementation Chapter

+ (instancetype) chapter:(float)idx ofVolume:(NSInteger)volume {
	Chapter *i = [self new];
	i.baseIdx = idx;
	i.volume = volume;
	return i;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%ld-%.2f", (long)_volume, _idx];
}

- (void) setBaseIdx:(float)baseIdx {
	_baseIdx = baseIdx;
	_idx = baseIdx;
}

- (BOOL) isEqual:(Chapter *)object {
	return (!!object) && (_volume == object->_volume) && (ABS(_idx - object->_idx) < 0.01);
}

@end


@implementation AZErgoCountingConflictsSolver {
	NSMutableDictionary *_conflicts;
	NSArray *_ordered;
	NSMutableArray *_volumes;
	NSArray *chapters;

	BOOL orderChanged, conflictsChanged, volumesChanged;
}

+ (instancetype) solverForChapters:(NSArray *)chapters {
	AZErgoCountingConflictsSolver *i = [self new];
	i->chapters = chapters;
	return i;
}

- (NSArray *) ordered {
	if (_ordered && !orderChanged)
		return _ordered;

	orderChanged = NO;

	return _ordered = [chapters sortedArrayUsingComparator:^NSComparisonResult(Chapter *c1, Chapter *c2) {
		return [@(c1.volume + c1.baseIdx / 10000.f) compare:@(c2.volume + c2.baseIdx / 10000.f)];
	}];
}

- (NSMutableDictionary *) conflicts {
	if (_conflicts && !conflictsChanged)
		return _conflicts;

	conflictsChanged = NO;

	_conflicts = [NSMutableDictionary dictionary];

	for (Chapter *chapter in self.ordered) {
		id chapID = @(_IDX(chapter.idx));

		NSNumber *has = _conflicts[chapID];
		_conflicts[chapID] = @([has integerValue] + 1);
	}

	return _conflicts;
}

- (void) solveConflicts {
	int tries = 5;

	while (tries--) {
		[self solveShifts];
		for (NSNumber *volume in self.volumes)
			[self solveVolumeConflicts:[volume integerValue]];

		NSUInteger conflicts = 0;
		for (NSNumber *c in self.conflicts)
			if ([c unsignedIntegerValue] > 1)
				conflicts++;

		if (!conflicts)
			break;
	}
}

- (NSArray *) volumes {
	if (_volumes && !volumesChanged)
		return _volumes;

	volumesChanged = NO;

	_volumes = [NSMutableArray array];
	NSMutableSet *s = [NSMutableSet setWithCapacity:[self.ordered count]];

	for (Chapter *chapter in self.ordered)
		if (![s containsObject:@(chapter.volume)]) {
			[s addObject:@(chapter.volume)];
			[_volumes addObject:@(chapter.volume)];
		}

	return _volumes;
}

- (NSArray *) volumeChapters:(NSInteger)volume {
	NSMutableArray *vChapters = [NSMutableArray array];
	for (Chapter *chapter in self.ordered)
		if (chapter.volume == volume)
			[vChapters addObject:chapter];

	return vChapters;
}

- (NSInteger) hasConflicts:(NSInteger)idx {
	return [self.conflicts[@(idx)] integerValue] - 1;
}

- (NSInteger) delta:(NSInteger)delta conflictsForIDX:(NSInteger)idx {
	id uid = @(idx);

	NSNumber *has = self.conflicts[uid];
	NSInteger value = MAX(0, [has integerValue] + delta);
	if (!value)
		[_conflicts removeObjectForKey:uid];
	else
		_conflicts[uid] = @(value);

	return value;
}

- (void) solveShifts {
	NSUInteger nextLoverBound = NSUIntegerMax;
	for (NSNumber *v in [self.volumes reverseObjectEnumerator]) {
		NSUInteger volume = [v unsignedIntegerValue];
		NSUInteger vIdx = _IDX(volume);

    NSArray *vChapters = [self volumeChapters:volume];

		NSUInteger selfUpperBound = nextLoverBound;

		Chapter *first = [vChapters firstObject];
		NSUInteger firstIdx = _IDX(first.idx);
		if (firstIdx < vIdx) {
			NSUInteger newIdx = selfUpperBound;
			for (Chapter *c in [vChapters reverseObjectEnumerator]) {
				NSUInteger last = _IDX(c.idx);

				if (selfUpperBound == NSUIntegerMax)
					selfUpperBound = (newIdx = last);

				if (last >= selfUpperBound)
					newIdx = MIN(last, selfUpperBound);
				else {
					newIdx -= _IDX(1);
					[self changeChapter:c index:newIdx];
				}
			}

			NSInteger delta = vIdx - newIdx;
			if (delta > 0) {
				newIdx = vIdx;
				NSUInteger fixIdx = volume;
				for (Chapter *c in vChapters)
					if (_IDX(c.idx) < selfUpperBound)
						[self changeChapter:c index:_IDX(fixIdx++)];
			}

			nextLoverBound = newIdx;
		} else
			nextLoverBound = firstIdx;

	}
}

- (void) solveVolumeConflicts:(NSInteger)volume {
	NSArray *conflicted = [self hasConflictedChapters:volume];
	for (Chapter *chapter in conflicted) {
    Chapter *lower = [self seekLower:chapter];

		if (lower) {
			NSArray *between = [self between:lower and:chapter];

			NSInteger bCount = [between count], origin = 5 + bCount;
			if (origin > 9) {
				NSInteger delta = origin - 9;
				origin -= delta;

				for (Chapter *bonuses in between)
					[self changeChapter:bonuses index:_IDX(bonuses.idx) - delta];
			}

			[self changeChapter:chapter index:_IDX(lower.idx) + origin];
		}
	}
}

- (NSArray *) hasBonusChapters:(NSInteger)volume {
	NSArray *bChapters = [self volumeChapters:volume];

	NSMutableArray *bonus = [NSMutableArray arrayWithCapacity:[bChapters count]];

	for (Chapter *chapter in bChapters)
		if (_FRC(chapter.idx)) // can be translated to bonus chapter
			[bonus addObject:chapter];

	return bonus;
}

- (NSArray *) hasConflictedChapters:(NSInteger)volume {
	NSArray *cChapters = [self volumeChapters:volume];

	NSMutableArray *conflicted = [NSMutableArray arrayWithCapacity:[cChapters count]];

	for (Chapter *chapter in cChapters) {
		NSInteger conflict = [self hasConflicts:_IDX(chapter.idx)];
		if (conflict >= 1)
			[conflicted addObject:chapter];
	}

	return conflicted;
}

- (Chapter *) seekLower:(Chapter *)from {
	NSUInteger index = [self.ordered indexOfObjectIdenticalTo:from];

	while (index-- > 0) {
		Chapter *candidate = [self.ordered objectAtIndex:index];

		if (candidate.volume != from.volume)
			break;

		if (!_FRC(candidate.idx))
			return candidate;
	}

	return nil;
}

- (NSArray *) between:(Chapter *)left and:(Chapter *)right {
	NSUInteger iLeft = [self.ordered indexOfObjectIdenticalTo:left];
	NSUInteger iRight = [self.ordered indexOfObjectIdenticalTo:right];

	if (iRight < iLeft) {
		NSUInteger t = iLeft;
		iLeft = iRight;
		iRight = t;
	}

	return ((iRight - iLeft) > 1) ? [self.ordered subarrayWithRange:NSMakeRange(iLeft + 1, iRight - iLeft - 1)] : @[];
}

- (void) changeChapter:(Chapter *)chapter index:(NSInteger)index {
	[self delta:-1 conflictsForIDX:_IDX(chapter.idx)];
	[self delta:+1 conflictsForIDX:index];
	chapter.idx = _IDI(index);
	orderChanged = YES;
	volumesChanged = YES;
	conflictsChanged = YES;
}

@end
