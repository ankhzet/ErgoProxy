//
//  AZErgoUpdateWatch.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdateWatch.h"
#import "AZDownload.h"
#import "AZErgoMangaCommons.h"
#import "AZErgoUpdateChapter.h"

@implementation AZErgoUpdateWatch {
	NSMutableDictionary *stateCache;
}
@dynamic source, title, manga, genData, updates;
@synthesize checking = _checking, delegate;

+ (AZErgoUpdateWatch *) watchByManga:(NSString *)manga {
	return [self any:@"manga ==[c] %@", manga];
}

- (void) setChecking:(BOOL)checking {
	if (_checking == checking)
		return;

	_checking = checking;

	if (self.delegate)
		[self.delegate watch:self stateChanged:_checking];
}

- (NSArray *) chapterDownloads:(AZErgoUpdateChapter *)chapter {
	return [AZDownload manga:self.manga hasChapterDownloads:chapter.idx];
}

- (void) clearChapterState:(AZErgoUpdateChapter *)chapter {
	[stateCache removeObjectForKey:@(chapter.idx)];
}

- (AZErgoUpdateChapterDownloads) chapterState:(AZErgoUpdateChapter *)chapter {
	AZErgoUpdateChapterDownloads oldState = chapter.state;

	if (oldState != AZErgoUpdateChapterDownloadsUnknown)
		return oldState;

	NSArray *downloads = [self chapterDownloads:chapter];

	NSUInteger total = [downloads count], downloaded = 0;
	for (AZDownload *download in downloads)
		if (HAS_BIT(download.state, AZErgoDownloadStateDownloaded))
			downloaded++;

	AZErgoUpdateChapterDownloads state = AZErgoUpdateChapterDownloadsNone;

	if (total) {
		if (total <= downloaded)
			state = AZErgoUpdateChapterDownloadsDownloaded;
		else
			state = AZErgoUpdateChapterDownloadsPartial;
	}

	float cidx = chapter.idx;

	if (state == AZErgoUpdateChapterDownloadsNone)
		for (NSNumber *idx in [stateCache allKeys])
			if (([idx floatValue] > cidx) && ([stateCache[idx] unsignedIntegerValue] == AZErgoUpdateChapterDownloadsDownloaded)) {
				state = AZErgoUpdateChapterDownloadsDownloaded;
				break;
			}

	(stateCache ?: (stateCache = [NSMutableDictionary dictionary]))[@(cidx)] = @(state);

	if (oldState != state)
		chapter.state = state;

	return state;
}

- (NSComparisonResult) compare:(AZErgoUpdateWatch *)another {
	return [self.title compare:another.title];
}

- (BOOL) requiresCheck {
	AZErgoManga *manga = [AZErgoManga mangaByName:self.manga];
	if (manga.isDownloaded || manga.isReaded)
		return NO;

	if (!manga.isComplete)
		return YES;

	float lastDownloaded = [AZErgoMangaChapter lastChapter:manga.name];
	if ([AZErgoMangaChapter same:0.f as:lastDownloaded])
		return YES;

	float lastUpdate = [[self lastChapter] idx];

	BOOL same = [AZErgoMangaChapter same:lastUpdate as:lastDownloaded];
	if (same) {
		[manga toggle:YES tagWithGUID:AZErgoTagGroupDownloaded];
	}

	return !same;
}

- (AZErgoUpdateChapter *) lastChapter {
	AZErgoUpdateChapter *last = nil;
	NSInteger lastUpdate = 0;
	for (AZErgoUpdateChapter *chapter in [self.updates allObjects])
		if (lastUpdate < _IDX(chapter.idx)) {
			lastUpdate = _IDX(chapter.idx);
			last = chapter;
		}

	return last;
}

- (AZErgoUpdateChapter *) firstChapter {
	AZErgoUpdateChapter *first = nil;
	NSInteger firstUpdate = 0;
	for (AZErgoUpdateChapter *chapter in [self.updates allObjects])
		if (firstUpdate > _IDX(chapter.idx)) {
			firstUpdate = _IDX(chapter.idx);
			first = chapter;
		}

	return first;
}

- (AZErgoUpdateChapter *) chapterByIDX:(float)chapter {
	NSInteger idx = _IDX(chapter);
	for (AZErgoUpdateChapter *chapter in [self.updates allObjects])
		if (idx == _IDX(chapter.idx))
			return chapter;

	return nil;
}


@end
