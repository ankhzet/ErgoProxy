//
//  AZErgoDownloadCellView.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadCellView.h"

#import "AZDownload.h"
#import "AZProgressIndicator.h"
#import "AZErgoUpdateChapter.h"

@interface AZErgoDownloadCellView () <AZErgoDownloadStateListener>

@property (weak) IBOutlet NSTextField *tfURL;
@property (weak) IBOutlet NSTextField *tfChapter;
@property (weak) IBOutlet NSTextField *tfPage;
@property (weak) IBOutlet NSImageView *ivState;
@property (weak) IBOutlet AZProgressIndicator *piProgress;

@end

@implementation AZErgoDownloadCellView
- (void) configureForEntity:(AZDownload *)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	self.tfURL.stringValue = [[NSURL URLWithString:entity.sourceURL] path];
	self.tfPage.integerValue = entity.page;

  int chapterIDX = _IDX(entity.chapter) % _IDX(1000.);
	double chapter = _IDI(chapterIDX);

	self.tfChapter.stringValue = (!!_FRC(chapter))
	/**/ ? [NSString stringWithFormat:@"%.1f", chapter]
	/**/ : [NSString stringWithFormat:@"%lu", (u_long)chapter];

	[self setState:entity.state forDownload:entity];
	[self setProgress:entity];
}

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state {
	[self setState:download.state forDownload:download];
	[self setProgress:download];
	[self setNeedsDisplay:YES];
}

- (void) download:(AZDownload *)download progressChanged:(double)progress {
	[self setProgress:download];
	[self setNeedsDisplay:YES];
}

- (void) setState:(AZErgoDownloadState)state forDownload:(AZDownload *)download {
	BOOL locked = download.lastDownloadIteration > [NSDate timeIntervalSinceReferenceDate];
	NSString *image = (!locked) ? NSImageNameStatusNone : NSImageNameLockLockedTemplate;

	if (!locked) {
		if (HAS_BIT(state, AZErgoDownloadStateDownloaded))
			image = NSImageNameStatusAvailable;
		else
			if (HAS_BIT(state, AZErgoDownloadStateAquired) || HAS_BIT(state, AZErgoDownloadStateResolved))
				image = NSImageNameStatusPartiallyAvailable;
			else
				if (download.totalSize && (download.downloaded < download.totalSize) && [download isFileCorrupt])
					image = NSImageNameStatusUnavailable;
				else
					if (HAS_BIT(state, AZErgoDownloadStateFailed))
						image = NSImageNameStatusUnavailable;
					else
						;
	}
	
	[self.ivState setImage:[NSImage imageNamed:image]];
//	[self setNeedsDisplay:YES];
}

- (void) setProgress:(AZDownload *)download {
	self.piProgress.maxValue = download.totalSize;
	self.piProgress.doubleValue = download.downloaded;

	if (HAS_BIT(download.state, AZErgoDownloadStateAquiring))
		self.piProgress.text = @"<aquiring...>";
	else
		if (HAS_BIT(download.state, AZErgoDownloadStateResolving))
			self.piProgress.text = @"<resolving...>";
		else {
			self.piProgress.text = nil;
		}
}

@end
