//
//  AZErgoDownloadDetailsPopover.m
//  ErgoProxy
//
//  Created by Ankh on 04.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadDetailsPopover.h"

#import "AZDownload.h"

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
	[presenter dropHash];
}

- (IBAction)actionDropDownload:(id)sender {
	[presenter deleteEntity];
}

- (IBAction)actionPreviewDownload:(id)sender {
	[presenter previewEntity];
}

- (IBAction)actionPreviewDelete:(id)sender {
	[presenter trashEntity];
}

- (IBAction)actionBrowseStorage:(id)sender {
	[presenter browseEntityStorage];
}

- (IBAction)actionBrowseScan:(id)sender {
	[presenter browseEntity];
}

- (IBAction)actionLockScan:(id)sender {
	[presenter lockEntity];
}


@end
