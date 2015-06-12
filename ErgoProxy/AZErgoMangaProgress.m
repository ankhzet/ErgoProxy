//
//  AZErgoMangaProgress.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaProgress.h"
#import "AZErgoManga.h"
#import "AZErgoMangaChapter.h"
#import "AZErgoChapterProtocol.h"

@implementation AZErgoMangaProgress
@dynamic chapter, chapters;
@dynamic page;
@dynamic manga;
@dynamic updated;

+ (instancetype) progressInMangaNamed:(NSString *)mangaName {
	AZErgoManga *manga = [AZErgoManga mangaByName:mangaName];
	return manga.progress;
}

- (void) setChapter:(float)current andPage:(NSUInteger)page {
	self.chapter = current;
	self.page = page;

	self.updated = [NSDate date];
}

- (BOOL) has:(float)lastChapter readed:(BOOL *)readed chapters:(float *)currentChapter {
	NSUInteger
	last = _IDX(lastChapter),
	current = _IDX(self.chapter);

	BOOL hasPage = self.page > 1;
	BOOL afterLast = self.manga.isWebtoon || !hasPage;

//	if (afterLast)

	if (_FRC(lastChapter)) {
		float idx = _IDI(current);
		float prev = [AZErgoMangaChapter seekManga:self.manga.name chapter:idx withDelta:-1];
		if ([AZErgoMangaChapter same:idx as:prev])
			idx -= 1.f;

		current = _IDX(idx);

	} else
		current -= _IDX(1.f);

	BOOL hasChapter = current > 0;
	BOOL readedEarlier = afterLast || (hasChapter && hasPage) || (current > last);

	if (currentChapter != NULL)
		*currentChapter = _IDI(current);

	if (readed != NULL)
		*readed = readedEarlier;

	return readedEarlier && hasChapter;
}

- (BOOL) hasReaded {
	return [self has:self.chapters readed:NULL chapters:NULL];
}

- (BOOL) hasReadedAndUnreaded {
	float last = self.chapters, current = 0.f;
	if ([self has:last readed:NULL chapters:&current])
		return current < last;
	else
		return NO;
}

- (BOOL) hasUnreaded {
	float last = self.chapters, current = 0.f;

	[self has:last readed:NULL chapters:&current];

	return (last < 1) || (current < last);
}

@end
