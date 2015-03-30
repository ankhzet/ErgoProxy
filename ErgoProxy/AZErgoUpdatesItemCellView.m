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

	self.tfTitle.stringValue = chapter.fullTitle ?: @"<failed to format title>";
	self.tfDate.objectValue = (chapter.date && !chapter.isDummy) ? chapter.date : @"";

	[self checkOV:view downloads:chapter];
}

- (void) checkOV:(NSOutlineView *)view downloads:(AZErgoUpdateChapter *)chapter {
	switch (chapter.state) {
		case AZErgoUpdateChapterDownloadsFailed:
			[self showState:chapter.state];
			[self.ivStatus setHidden:chapter.isDummy];
			[self.bListScans setHidden:chapter.isDummy];
			break;
		case AZErgoUpdateChapterDownloadsUnknown:
			[self showState:chapter.state];
			break;

		default:
			[self.ivStatus setImage:[NSImage imageNamed:NSImageNameStatusNone]];
			[self setNeedsLayout:YES];

			dispatch_async_at_background(^{
				AZErgoUpdateChapterDownloads state = [chapter.watch chapterState:chapter];

				dispatch_sync_at_main(^{
					if (chapter != self.bindedEntity)
						return;

					[self showState:state];
				});
			});
			break;
	}
}

- (void) showState:(AZErgoUpdateChapterDownloads)state {
	NSString *image = NSImageNameStatusNone;

	[self.ivStatus setHidden:NO];
	switch (state) {
		case AZErgoUpdateChapterDownloadsFailed:
			image = NSImageNameStatusUnavailable;
			break;

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
