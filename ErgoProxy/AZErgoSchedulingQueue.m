//
//  AZErgoSchedulingQueue.m
//  ErgoProxy
//
//  Created by Ankh on 19.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoSchedulingQueue.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"
#import "AZDownload.h"
#import "AZProxifier.h"
#import "AZWaitableTask.h"
#import "AZErgoDownloadPrefsWindowController.h"
#import "AZErgoChapterDownloadParams.h"
#import "AZDataProxy.h"

@implementation AZErgoSchedulingQueue

+ (instancetype) sharedQueue {
	static AZErgoSchedulingQueue *queue;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    queue = [self new];
	});

	return queue;
}

- (void) checkWatch:(AZErgoUpdateWatch *)watch {
	[self enqueue:^(BOOL *requeue, AZErgoUpdateWatch *associatedObject) {
		AZErgoUpdateWatch *watch = [associatedObject inContext:nil];

		[[watch.source relatedSource] checkWatch:watch];
	} withAssociatedObject:watch];
}

- (void) queueChapterDownloadTask:(AZErgoUpdateChapter *)chapter {
	[self enqueue:^(BOOL *requeue, AZErgoUpdateChapter *aChapter) {
		AZErgoUpdateChapter *chapter = [aChapter inContext:nil];

		AZErgoUpdateWatch *checkable = [chapter.watch deepSearch:^BOOL(AZErgoUpdateWatch *entity) {
			return [[(id)entity md_delegate] hasDelegates];
		}];
		checkable.checking = YES;
		[self checkChapter:chapter requeue:requeue];
		checkable.checking = NO;
	} withAssociatedObject:chapter];
}

- (void) checkChapter:(AZErgoUpdateChapter *)aChapter requeue:(BOOL *)requeue {

	[AZWaitableTask executeTask:^(AZWaitableTask *task) {
		AZErgoUpdateChapter *chapter = [aChapter inContext:nil];

		AZErgoUpdatesSource *source = [chapter.watch.source relatedSource];
		[source checkUpdate:chapter withBlock:^(NSArray *scans) {
			AZErgoUpdateChapter *chapter = [aChapter inContext:nil];

			if (!(*requeue = ![scans count]))
				*requeue = ![self chapter:chapter infoRetrived:scans];
			else
				AZErrorTip(LOC_FORMAT(@"Scans aquire failed for %@!", chapter.genData));

			[task break];
		}];

	}];
}

- (BOOL) chapter:(AZErgoUpdateChapter *)chapter infoRetrived:(NSArray *)scans {
	chapter = [chapter inContext:nil];

	AZErgoUpdateChapter *configured = [chapter.watch lastChapter];
	AZDownload *anyDownload = nil;

	do {
		configured = [chapter.watch chapterBefore:configured];
		anyDownload = [configured.downloads anyObject];
	} while (!(anyDownload || !configured));

	AZErgoManga *manga = chapter.watch.relatedManga;
	AZDownloadParams *params;
	if (anyDownload)
		params = anyDownload.downloadParameters;
	else
		params = [[AZErgoDownloadPrefsWindowController sharedController] aquireParams:NO forManga:manga];

	if (!params) {
		chapter.state = AZErgoUpdateChapterDownloadsFailed;
		AZErrorTip(LOC_FORMAT(@"Download params not aquired!"));
		return NO;
	}

	AZ_CDDetatch({
		AZProxifier *proxifier = [AZProxifier sharedProxifier];

		AZErgoChapterDownloadParams *downloads = [AZErgoChapterDownloadParams new];
		downloads.manga = manga;
		downloads.chapterID = chapter.idx;
		downloads.scanDownloadParams = [params inContext:nil];
		downloads.scans = scans;
		[downloads registerDownloads:proxifier];
	});

	self.hasNewChapters = YES;
	return YES;
}


@end
