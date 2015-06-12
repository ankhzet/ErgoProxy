//
//  AZErgoCountingConflictsSolver.m
//  ErgoProxy
//
//  Created by Ankh on 27.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoCountingConflictsSolver.h"

@implementation Chapter
@synthesize volume = _volume, baseIdx = _baseIdx, idx = _idx, date, genData, mangaName, title;

+ (instancetype) chapter:(float)idx ofVolume:(NSInteger)volume {
	Chapter *i = [self new];
	i.baseIdx = idx;
	i.volume = volume;
	return i;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%ld-%.2f", (long)_volume, ((int)(_idx*1000))/1000.];
}

- (void) setBaseIdx:(float)baseIdx {
	_baseIdx = baseIdx;
	_idx = baseIdx;
}

- (BOOL) isEqual:(Chapter *)object {
	return (!!object) && (_volume == object->_volume) && (ABS(_idx - object->_idx) < 0.0001);
}

- (BOOL) isBonus {
	return !!_FRC(_idx);
}


@end


@implementation AZErgoCountingConflictsSolver {
	NSMutableDictionary *_conflicts;
	NSArray *_ordered;
	NSMutableArray *_volumes;
	NSArray *_chapters;

	BOOL orderChanged, conflictsChanged, volumesChanged;
}

+ (instancetype) solverForChapters:(NSArray *)chapters {
	AZErgoCountingConflictsSolver *i = [self new];
	i->_chapters = chapters;
	return i;
}

- (NSArray *) ordered {
	if (_ordered && !orderChanged)
		return _ordered;

	orderChanged = NO;

	return _ordered = [_chapters sortedArrayUsingComparator:^NSComparisonResult(Chapter *c1, Chapter *c2) {
		double v1 = c1.volume + c1.baseIdx / 10000.f;
		double v2 = c2.volume + c2.baseIdx / 10000.f;
		return SIGN(v1 - v2);
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

- (NSUInteger) bonus:(NSUInteger)idx fromCount:(NSUInteger)total {
	NSInteger result;

	if (idx < 9) {
		total = MIN(9, total);

		NSInteger offset = _IDX(idx) / 10.f;
		if (total > 5) {
			offset -= _IDX(total - 5) / 10.f;
		}

		result = _IDX(0.5f) + offset;
		return result;
	}

	NSUInteger offset = [self bonus:idx-9 fromCount:total-9];
	result = _IDX(0.9f) + offset / 10.f;
	return result;
}

- (BOOL) hasConflicts {
	NSUInteger conflicts = 0;
	for (NSNumber *c in [self.conflicts allValues])
		if ([c unsignedIntegerValue] > 1)
			conflicts++;

	return conflicts > 0;
}

- (void) solveConflicts {

	int tries = 20;

	while (tries--) {
		if (![self hasConflicts])
			return;

		if ([self isSeasoned])
			[self seasonedShifts];

		if ([self.volumes count] > 1)
			[self solveShifts];

		for (NSNumber *volume in self.volumes)
			[self solveVolumeConflicts:[volume integerValue]];

		NSUInteger conflicts = 0;
		for (NSNumber *c in [self.conflicts allValues])
			if ([c unsignedIntegerValue] > 1)
				conflicts++;

		if (!conflicts) {
			conflictsChanged = YES;
			[self conflicts];

			conflicts = 0;
			NSUInteger max = 0;
			Chapter *prev = nil;
			for (Chapter *c in self.ordered) {
				NSUInteger current = _IDX(c.idx);
				if (max < current)
					max = current;

				if (current < max) {
					conflicts++;
					Chapter *c2 = [self seekLower:prev sameVolume:NO];
					c2 = [self seekLower:c2 sameVolume:NO];
					if (!c2) c2 = [self.ordered firstObject];


					NSArray *range = [self between:c2 and:prev];
//					range = [@[c2] arrayByAddingObjectsFromArray:range];
					NSUInteger idx = _IDX(c2.idx);
					for (Chapter *b in range)
						b.idx = _IDI(idx + [self bonus:[range indexOfObjectIdenticalTo:b] fromCount:[range count]]);
				}

				prev = c;
			}

			if (!conflicts) {
				Chapter *wait = nil;
				for (Chapter *c in self.ordered) {
					if ((wait && (c != wait)) || !c.isBonus)
						continue;

					wait = nil;

					Chapter *next = [self seekHigher:c sameVolume:NO];
					BOOL lastPart = !next;
					if (lastPart)
						next = [self.ordered lastObject];
					else
						wait = next;

					NSArray *bonuses = [@[c] arrayByAddingObjectsFromArray:[self between:c and:next]];
					if (lastPart) bonuses = [bonuses arrayByAddingObject:next];

					if (![bonuses count])
						continue;

					NSUInteger min = _IDX(99999), max = _IDX(0);
					for (Chapter *c in bonuses) {
						NSUInteger idx = _FRC(c.idx);
						if (idx > max) max = idx;
						if (idx < min) min = idx;
					}

					if ((min == _IDX(0.5f)) || (max >= _IDX(0.9f)))
						continue;

					NSInteger delta = _IDX(0.9f) - max;
					if (min > _IDX(0.5f)) delta = -delta;

					for (Chapter *c in bonuses)
						[self changeChapter:c index:_IDX(c.idx) + delta];
				}

				break;
			}

//			for (Chapter *c in self.ordered)
//				c.idx = c.baseIdx;

			orderChanged = YES;
		}

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

	_volumes = [[_volumes sortedArrayUsingSelector:@selector(compare:)] mutableCopy];

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

- (BOOL) isSeasoned {
	NSMutableArray *volumes = [[self volumes] mutableCopy];
	[volumes removeObject:[volumes firstObject]];

	for (NSNumber *volumeN in volumes) {
		NSInteger volume = [volumeN integerValue];
		NSArray *conflicted = [self hasConflictedChapters:volume];
		if ([conflicted count] > 5) {
			NSArray *chapters = [self volumeChapters:volume];
			Chapter *first = [chapters firstObject];
			NSInteger idx = _IDX(first.idx);
			if ((idx) <= _IDX(1.f))
				return YES;
		}
	}

	return NO;
}

- (void) seasonedShifts {
	for (NSNumber *volumeN in self.volumes) {
    NSInteger volume = [volumeN integerValue];

		for (Chapter *c in [self volumeChapters:volume]) {
			NSInteger bonus = _FRC(c.idx);
			NSInteger idx = _IDX(c.idx) - bonus;
			idx += _IDX(1000 * volume) + bonus;

			[self changeChapter:c index:idx];
		}
	}
}

- (void) solveShifts {
	NSUInteger nextLoverBound = NSUIntegerMax;
	for (NSNumber *v in [self.volumes reverseObjectEnumerator]) {
		NSInteger volume = [v unsignedIntegerValue];
		NSInteger vIdx = _IDX(MAX(volume, 1));

    NSArray *vChapters = [self volumeChapters:volume];

		NSInteger selfUpperBound = nextLoverBound;

		Chapter *first = [vChapters firstObject];
		Chapter *last = [vChapters lastObject];
		NSInteger firstIdx = _IDX(first.idx);
		NSInteger lastIdx = _IDX(last.idx);
		if ((firstIdx < vIdx) || (lastIdx >= nextLoverBound)) {
			NSInteger newIdx = selfUpperBound;
			for (Chapter *c in [vChapters reverseObjectEnumerator]) {
				NSInteger last = _IDX(c.idx);

				if (selfUpperBound == NSUIntegerMax)
					selfUpperBound = (newIdx = last);

				if (last >= selfUpperBound) {
					NSInteger tryIdx = MIN(last, selfUpperBound);
					if ((tryIdx == newIdx) && ([[self hasConflictedChapters:volume + 1] count] == 1)) {
						tryIdx -= _IDX(0.1f);
						[self changeChapter:c index:tryIdx];
					} else
						newIdx = tryIdx;

				} else {
					newIdx = MAX(newIdx - _IDX(1.f), _IDX(1.f));
					[self changeChapter:c index:newIdx];
				}
			}

			NSInteger delta = vIdx - newIdx;
			if (delta > 0) {
				newIdx = vIdx;
				NSInteger fixIdx = volume;
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

			NSInteger bCount = [between count];
			NSInteger origin = _IDX(0.5f + bCount / 10.f);
			while (origin >= _IDX(1.f)) {
				NSInteger delta = origin - _IDX(0.9f);
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
		if (chapter.isBonus) // can be translated to bonus chapter
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
	return [self seekLower:from sameVolume:YES];
}

- (Chapter *) seekLower:(Chapter *)from sameVolume:(BOOL)sameVol {
	NSUInteger index = [self.ordered indexOfObjectIdenticalTo:from];

	if (index != NSNotFound)
		while (index-- > 0) {
			Chapter *candidate = [self.ordered objectAtIndex:index];

			if (sameVol && (candidate.volume != from.volume))
				break;

			if (!_FRC(candidate.idx))
				return candidate;
		}

	return nil;
}

- (Chapter *) seekHigher:(Chapter *)from sameVolume:(BOOL)sameVol {
	NSArray *ordered = self.ordered;

	NSUInteger index = [ordered indexOfObjectIdenticalTo:from];

	if (index != NSNotFound) {
		NSUInteger count = [ordered count];
		while (++index < count) {
			Chapter *candidate = [ordered objectAtIndex:index];

			if (sameVol && (candidate.volume != from.volume))
				break;

			if (!_FRC(candidate.idx))
				return candidate;
		}
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
