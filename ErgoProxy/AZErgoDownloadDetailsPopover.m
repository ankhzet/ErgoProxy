//
//  AZErgoDownloadDetailsPopover.m
//  ErgoProxy
//
//  Created by Ankh on 04.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadDetailsPopover.h"

#import "AZDownload.h"
#import "AZDownloadParams.h"

@implementation AZErgoDownloadDetailsPopover {
	AZDownload *_download;
}

- (void) showDetailsFor:(AZDownload *)download alignedTo:(NSView *)view {
	_download = download;

	self.tfTitle.stringValue = [NSString stringWithFormat:@"%@ [ch. %.1f, p. %lu]", [download.manga capitalizedString], download.chapter, download.page];
	self.tfURL.stringValue = [download.sourceURL absoluteString];
	self.tfWidth.stringValue = [NSString stringWithFormat:@"Width: %@ or less", [download.downloadParams downloadParameter:kDownloadParamMaxWidth]];
	self.tfHeight.stringValue = [NSString stringWithFormat:@"Height: %@ or less", [download.downloadParams downloadParameter:kDownloadParamMaxHeight]];
	self.tfQuality.stringValue = [NSString stringWithFormat:@"Quality: %@", [download.downloadParams downloadParameter:kDownloadParamQuality]];

	NSNumber *isWebtoon = [download.downloadParams downloadParameter:kDownloadParamIsWebtoon];
	self.tfIsWebtoon.stringValue = [isWebtoon boolValue] ? @"Is a webtoon" : @"";

	self.tfHash.stringValue = download.proxifierHash ? download.proxifierHash : @"<hash not aquired yet>";

	if (!HAS_BIT(download.state, AZErgoDownloadStateFailed)) {
		self.tfError.stringValue = @"";
	} else {
		self.tfError.stringValue = download.error ? download.error : @"";
	}

	self.behavior = NSPopoverBehaviorTransient;
	[self showRelativeToRect:view.bounds ofView:view preferredEdge:NSMaxYEdge];
}

- (IBAction)actionDropHash:(id)sender {
	self.tfHash.stringValue = @"";
	[_download downloadError:nil];
	_download.state ^= AZErgoDownloadStateResolved;
}

- (IBAction)actionDropDownload:(id)sender {
	[_download remove];
}

- (IBAction)actionPreviewDownload:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[_download localFilePath]];
}

@end
