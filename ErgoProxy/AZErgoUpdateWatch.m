//
//  AZErgoUpdateWatch.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdateWatch.h"
#import "AZDownload.h"
#import "AZErgoUpdateChapter.h"

@implementation AZErgoUpdateWatch {
	NSMutableDictionary *stateCache;
}
@dynamic source, title, manga, genData, updates;
@synthesize checking = _checking, delegate;

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
	if (chapter.state != AZErgoUpdateChapterDownloadsUnknown)
		return chapter.state;

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

	return chapter.state = state;
}

- (NSComparisonResult) compare:(AZErgoUpdateWatch *)another {
	return [self.title compare:another.title];
}
@end
