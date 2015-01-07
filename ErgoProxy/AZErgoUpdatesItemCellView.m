//
//  AZErgoUpdateItemView.m
//  ErgoProxy
//
//  Created by Ankh on 25.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesItemCellView.h"

#import "AZErgoUpdateChapter.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdatesSource.h"
#import "AZErgoUpdatesSourceDescription.h"
#import "AZDownload.h"

@implementation AZErgoUpdatesItemCellView

- (void) configureForEntity:(AZErgoUpdateChapter *)chapter inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = chapter;

	BOOL dummy = chapter.idx < 0;
	NSString *title;
	if ([chapter.title length])
		if (dummy)
			title = chapter.title;
		else
			title = [@"- " stringByAppendingString:chapter.title];
	else
		title = @"";

	if (!dummy) {
		NSString *chap = (!!((int)(chapter.idx * 10) % 10)) ? [NSString stringWithFormat:@"%.1f\t", chapter.idx] : [NSString stringWithFormat:@"%d\t  ", (int)(chapter.idx)];

		title = [NSString stringWithFormat:@"v %d\t  ch %@%@", (int)chapter.volume, chap, title];
	}

	self.tfTitle.stringValue = title;
	self.tfDate.objectValue = (chapter.date && !dummy) ? chapter.date : @"";

	[self checkOV:view downloads:chapter];
}

- (void) checkOV:(NSOutlineView *)view downloads:(AZErgoUpdateChapter *)chapter {
	if (chapter.state != AZErgoUpdateChapterDownloadsUnknown)
		[self showState:chapter.state];
	else {
		[self.ivStatus setImage:[NSImage imageNamed:NSImageNameStatusNone]];
		[self setNeedsLayout:YES];

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			AZErgoUpdateChapterDownloads state = [chapter.watch chapterState:chapter];

			dispatch_sync(dispatch_get_main_queue(), ^{
				if (chapter != self.bindedEntity)
					return;

				[self showState:state];
			});
		});
	}
}

- (void) showState:(AZErgoUpdateChapterDownloads)state {
	NSString *image = NSImageNameStatusNone;

	[self.ivStatus setHidden:NO];
	switch (state) {
		case AZErgoUpdateChapterDownloadsFailed:
			[self.ivStatus setHidden:YES];

		case AZErgoUpdateChapterDownloadsDownloaded:
			image = NSImageNameStatusAvailable;
			[self.bListScans setHidden:YES];
			break;

		case AZErgoUpdateChapterDownloadsPartial:
			image = NSImageNameStatusPartiallyAvailable;

		default:
			[self.bListScans setHidden:NO];
			break;
	}

	[self.ivStatus setImage:[NSImage imageNamed:image]];
	[self setNeedsLayout:YES];
}

@end
