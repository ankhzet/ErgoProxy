//
//  AZErgoChapterDownloadParams.m
//  ErgoProxy
//
//  Created by Ankh on 20.05.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChapterDownloadParams.h"
#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"
#import "AZDownload.h"
#import "AZProxifier.h"

@implementation NSString (ScanOrdering)

- (NSString *) cleanName {
	return [[self lastPathComponent] stringByDeletingPathExtension];
}

- (NSComparisonResult) compareScan:(NSString *)otherScan {
	return [[self cleanName] compare:[otherScan cleanName] options:NSCaseInsensitiveSearch | NSNumericSearch];
}

@end

@implementation AZErgoChapterDownloadParams
@synthesize scans = _scans;

- (void) registerDownloads:(AZProxifier *)proxifier {
	AZErgoUpdateChapter *chapter = [AZErgoUpdateChapter updateChapterForManga:self.manga chapter:self.chapterID];

	NSArray *scans = self.scans;
	for (NSString *scan in scans) {
		AZDownload *download = [proxifier downloadForURL:scan withParams:self.scanDownloadParams];
		download.forManga = [self.manga inContext:download.managedObjectContext];

		if (download.updateChapter && ![download.updateChapter isEqual:chapter])
			[download.updateChapter delete];

		download.updateChapter = [chapter inContext:download.managedObjectContext];

		download.chapter = self.chapterID;
		download.page = [self.scans indexOfObject:scan] + 1;
		download.state = AZErgoDownloadStateNone;
	}

	[chapter.watch clearChapterState:chapter];
	chapter.state = AZErgoUpdateChapterDownloadsPartial;
}

- (NSArray *) scans {
	return [_scans sortedArrayUsingSelector:@selector(compareScan:)];
}

@end

