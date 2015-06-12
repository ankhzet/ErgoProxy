//
//  AZErgoUpdateChapter.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdateChapter.h"
#import "AZErgoMangaCommons.h"
#import "AZDownload.h"
#import "AZDataProxy.h"

MULTIDELEGATED_INJECT_MULTIDELEGATED(AZErgoUpdateChapter)

@implementation AZErgoUpdateChapter
@dynamic watch, title, genData, persistentState, persistentIdx, volume, date, downloads;
@synthesize mangaName, baseIdx = _baseIdx, idx = _idx, state = _state;

+ (instancetype) updateChapterForManga:(AZErgoManga *)manga chapter:(float)chapterID {
	AZErgoUpdateChapter *chapter;

	AZErgoUpdateWatch *watch = [AZErgoUpdateWatch watchByManga:manga.name];
	if (watch) {
		chapter = [watch chapterByIDX:chapterID];
	} else {
		watch = [AZErgoUpdateWatch insertNew];
		watch.manga = manga.name;
	}

	if (!chapter) {
		chapter = [AZErgoUpdateChapter insertNew];
		chapter.volume = 1;
		chapter.idx = chapterID;
		chapter.title = chapter.fullTitle;
		chapter.date = [NSDate date];
		chapter.watch = watch;
		chapter.state = AZErgoUpdateChapterDownloadsUnknown;

		[watch chapterState:chapter];
	}

	return chapter;
}

- (AZErgoUpdateChapterDownloads) state {
	return self.persistentState;
}

- (void) setState:(AZErgoUpdateChapterDownloads)state {
	if (state == self.persistentState)
		return;

	self.persistentState = state;

	[self.md_delegate update:self stateChanged:state];
}

- (float) idx {
	return self.persistentIdx;
}

- (void) setIdx:(float)idx {
	if (!_IDX(_baseIdx)) {
		_baseIdx = idx;
	}

//	if (idx == self.persistentIdx)
//		return;

	self.persistentIdx = idx;

	[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context
		for (AZDownload *download in [self.downloads allObjects])
			download.chapter = idx;
	}];
}

- (float) baseIdx {
	return (!_IDX(_baseIdx)) ? self.persistentIdx : _baseIdx;
}

- (NSString *) mangaName {
	return self.watch.manga ?: mangaName;
}

- (BOOL) isDummy {
	return self.persistentIdx < 0;
}

- (BOOL) isBonus {
	return !!((int)(self.persistentIdx * 10) % 10);
}

- (NSComparisonResult) compare:(AZErgoUpdateChapter *)another {
	return (!!another) ? SIGN(self.persistentIdx - another.persistentIdx) : NSOrderedAscending;
}

@end

@implementation AZErgoUpdateChapter (Formatting)

- (NSString *) formattedString {
	return self.isBonus ? [NSString stringWithFormat:@"%.1f", self.idx] : [@((int)(self.idx)) stringValue];
}

- (NSString *) fullTitle {
	BOOL dummy = self.isDummy;

	NSString *title = self.title;

//	if (!![title length]) {
//		if (!dummy)
//			title = [@"\t  - " stringByAppendingString:title];
//	} else
//			title = @"";

	if (!dummy) {
		NSString *idx = [NSString stringWithFormat:@"v%d ch %@", (int)self.volume, [self formattedString]];
		if (title && ![title isLike:@"v*"]) {
			NSUInteger l = 12;
			idx = [idx stringByPaddingToLength:l withString:@" " startingAtIndex:0];
			title = [idx stringByAppendingString:[@"\t- " stringByAppendingString:title]];
		}
		else
			title = idx;
	}

	return title;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ - %@", self.watch.relatedManga ?: self.mangaName, self.fullTitle];
}

@end