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


#import "AZErgoDownloadDetailsPresenter.h"

@implementation AZErgoDownloadDetailsPopover {
	id entity;
	AZErgoDownloadDetailsPresenter *presenter;
}

- (void) showDetailsFor:(id)_entity alignedTo:(NSView *)view {
	entity = _entity;

	if ([entity isKindOfClass:[AZDownload class]])
		presenter = [AZErgoDownloadDetailsPresenter new];
	else
		presenter = [AZErgoChapterDetailsPresenter new];

	[presenter presentEntity:entity detailsIn:self];

	self.behavior = NSPopoverBehaviorTransient;
	[self showRelativeToRect:view.bounds ofView:view preferredEdge:NSMaxYEdge];
}

- (IBAction)actionDropHash:(id)sender {
}

- (IBAction)actionDropDownload:(id)sender {
}

- (IBAction)actionPreviewDownload:(id)sender {
}

@end
