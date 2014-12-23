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

@interface AZErgoDownloadCellView () <AZErgoDownloadStateListener> {
	AZDownload *_download;
}

@property (weak) IBOutlet NSTextField *tfURL;
@property (weak) IBOutlet NSTextField *tfChapter;
@property (weak) IBOutlet NSTextField *tfPage;
@property (weak) IBOutlet NSImageView *ivState;
@property (weak) IBOutlet AZProgressIndicator *piProgress;

@end

@implementation AZErgoDownloadCellView
@synthesize download = _download;

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	if (_download)
		_download.stateListener = nil;

	_download = entity;

	self.tfURL.stringValue = [_download.sourceURL path];
	self.tfPage.integerValue = _download.page;
	self.tfChapter.floatValue = _download.chapter;

	[self setState:_download.state forDownload:_download];
	[self setProgress:_download];

	_download.stateListener = self;
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
	NSString *image = NSImageNameStatusNone;

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
	
	[self.ivState setImage:[NSImage imageNamed:image]];
}

- (void) setProgress:(AZDownload *)download {
	double downloaded = 0.;

	if (HAS_BIT(download.state, AZErgoDownloadStateAquiring))
		self.piProgress.text = @"<aquiring...>";
	else
		if (HAS_BIT(download.state, AZErgoDownloadStateResolving))
			self.piProgress.text = @"<resolving...>";
		else {
			downloaded = 100 * download.percentProgress;
			self.piProgress.text = [NSString stringWithFormat:@"%@/%@", [NSString cvtFileSize:download.downloaded], [NSString cvtFileSize:download.totalSize]];
		}

	self.piProgress.doubleValue = downloaded;
}

@end
