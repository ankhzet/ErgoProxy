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

#import "AZMultipleTargetDelegate.h"

MULTIDELEGATED_INJECT_LISTENER(AZErgoDownloadDetailsPopover)

@implementation AZErgoDownloadDetailsPopover {
	id entity;
	AZErgoDownloadDetailsPresenter *presenter;
	NSView *alignView;
}

- (void) showDetailsFor:(id)_entity alignedTo:(NSView *)view {
	@synchronized(self) {
		entity = _entity;
		alignView = view;

		//TODO: fix deadlocks
		/*
		if ([entity supportsMultiDelegating])
			[self bindAsDelegateTo:entity solo:YES];
		*/

		if ([entity isKindOfClass:[AZDownload class]])
			presenter = [AZErgoDownloadDetailsPresenter new];
		else
			presenter = [AZErgoChapterDetailsPresenter new];

		[presenter presentEntity:entity detailsIn:self];
	}

	self.behavior = NSPopoverBehaviorTransient;
	[self showRelativeToRect:view.bounds ofView:view preferredEdge:NSMaxYEdge];
}

- (IBAction)actionDropHash:(id)sender {
	[presenter presentAction:^(AZErgoEntityDetailsPresenter *detailsPresenter) {
		[presenter dropHash];
	}];
}

- (IBAction)actionDropDownload:(id)sender {
	[presenter presentAction:^(AZErgoEntityDetailsPresenter *detailsPresenter) {
		[presenter deleteEntity];
	}];
}

- (IBAction)actionPreviewDownload:(id)sender {
	[presenter presentAction:^(AZErgoEntityDetailsPresenter *detailsPresenter) {
		[presenter previewEntity];
	}];
}

- (IBAction)actionPreviewDelete:(id)sender {
	[presenter presentAction:^(AZErgoEntityDetailsPresenter *detailsPresenter) {
		[presenter trashEntity];
	}];
}

- (IBAction)actionBrowseStorage:(id)sender {
	[presenter presentAction:^(AZErgoEntityDetailsPresenter *detailsPresenter) {
		[presenter browseEntityStorage];
	}];
}

- (IBAction)actionBrowseScan:(id)sender {
	[presenter presentAction:^(AZErgoEntityDetailsPresenter *detailsPresenter) {
		[presenter browseEntity];
	}];
}

- (IBAction)actionLockScan:(id)sender {
	[presenter presentAction:^(AZErgoEntityDetailsPresenter *detailsPresenter) {
		[detailsPresenter lockEntity];
	}];
}

- (void) popoverDidClose:(NSNotification *)notification {
	[self unbindDelegate];
}

@end

@interface AZErgoDownloadDetailsPopover (Delegated) <AZErgoDownloadStateListener>

@end

@implementation AZErgoDownloadDetailsPopover (Delegated)

- (void) download:(AZDownload *)download progressChanged:(double)progress {

}

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state {
	[presenter presentEntity:download detailsIn:self];
}

@end
