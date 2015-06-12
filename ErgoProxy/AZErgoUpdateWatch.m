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

MULTIDELEGATED_INJECT_MULTIDELEGATED(AZErgoUpdateWatch)

@implementation AZErgoUpdateWatch {
	NSMutableDictionary *stateCache;
}
@dynamic source, title, manga, genData, updates;
@synthesize checking = _checking;

+ (AZErgoUpdateWatch *) watchByManga:(NSString *)manga {
	return [self any:@"manga ==[c] %@", manga];
}

- (void) setChecking:(BOOL)checking {
	if (_checking == checking)
		return;

	_checking = checking;

	[self.md_delegate watch:self stateChanged:_checking];
}

- (AZErgoManga *) relatedManga {
	return [AZErgoManga mangaByName:self.manga];
}

- (NSArray *) chapterDownloads:(AZErgoUpdateChapter *)chapter {
	return [chapter.downloads allObjects];
//	return [AZDownload manga:self.relatedManga hasChapterDownloads:chapter.idx];
}

- (void) clearChapterState:(AZErgoUpdateChapter *)chapter {
	[stateCache removeObjectForKey:@(chapter.idx)];
}

- (void) clearChaptersState {
	stateCache = nil;
}

- (AZErgoUpdateChapterDownloads) chapterState:(AZErgoUpdateChapter *)chapter {
	AZErgoUpdateChapterDownloads oldState = chapter.state;

	if (oldState != AZErgoUpdateChapterDownloadsUnknown)
		return oldState;

	AZErgoUpdateChapterDownloads state = AZErgoUpdateChapterDownloadsNone;

	float cidx = chapter.idx;

//	if (state == AZErgoUpdateChapterDownloadsNone)
		for (NSNumber *idx in [stateCache allKeys])
			if (([idx floatValue] > cidx) && ([stateCache[idx] unsignedIntegerValue] == AZErgoUpdateChapterDownloadsDownloaded)) {
				state = AZErgoUpdateChapterDownloadsDownloaded;
				break;
			}

	if (state != AZErgoUpdateChapterDownloadsNone) {
//		chapter.state = state;
	} else {
		NSArray *downloads = [self chapterDownloads:chapter];

		NSUInteger total = [downloads count], downloaded = 0;
		for (AZDownload *download in downloads) {
			if (!download.state)
				[download fixState];

			if (HAS_BIT(download.state, AZErgoDownloadStateDownloaded))
				downloaded++;
		}


		if (total) {
			if (total <= downloaded)
				state = AZErgoUpdateChapterDownloadsDownloaded;
			else
				state = AZErgoUpdateChapterDownloadsPartial;
		}
	}

	GET_OR_INIT(stateCache, [NSMutableDictionary new])[@(cidx)] = @(state);

	if (oldState != state)
		chapter.state = state;

	return state;
}

- (NSComparisonResult) compare:(AZErgoUpdateWatch *)another {
	return [self.title caseInsensitiveCompare:another.title];
}

- (BOOL) requiresCheck {
	AZErgoManga *manga = self.relatedManga;
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
	NSInteger firstUpdate = NSIntegerMax;
	for (AZErgoUpdateChapter *chapter in [self.updates allObjects])
		if (firstUpdate > _IDX(chapter.idx)) {
			firstUpdate = _IDX(chapter.idx);
			first = chapter;
		}

	return first;
}

- (AZErgoUpdateChapter *) chapterBefore:(AZErgoUpdateChapter *)next {
	AZErgoUpdateChapter *before = nil;
	NSInteger upperBound = _IDX(next.idx), fittestIDX = 0;

	for (AZErgoUpdateChapter *chapter in [self.updates allObjects]) {
		NSUInteger idx = _IDX(chapter.idx);

		if ((idx < upperBound) && (idx > fittestIDX)) {
			fittestIDX = idx;
			before = chapter;
		}
	}

	return before;
}

- (AZErgoUpdateChapter *) chapterAfter:(AZErgoUpdateChapter *)next {
	AZErgoUpdateChapter *after = nil;
	NSInteger lowerBound = _IDX(next.idx), fittestIDX = NSIntegerMax;

	for (AZErgoUpdateChapter *chapter in [self.updates allObjects]) {
		NSUInteger idx = _IDX(chapter.idx);

		if ((idx > lowerBound) && (idx < fittestIDX)) {
			fittestIDX = idx;
			after = chapter;
		}
	}

	return after;
}

- (AZErgoUpdateChapter *) chapterByIDX:(float)chapter {
	NSInteger idx = _IDX(chapter);
	for (AZErgoUpdateChapter *chapter in [self.updates allObjects])
		if (idx == _IDX(chapter.idx))
			return chapter;

	return nil;
}

#pragma mark - Updates source URL provider proto

- (NSString *) mangaURL {
	return [[self.source relatedSource] mangaURL:self.genData];
}

@end
