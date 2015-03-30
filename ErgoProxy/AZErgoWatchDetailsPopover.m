//
//  AZErgoWatchDetailsPopover.m
//  ErgoProxy
//
//  Created by Ankh on 05.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoWatchDetailsPopover.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"

@interface AZErgoWatchDetailsPopover ()

@property (weak) IBOutlet NSTextField *tfFolderPath;
@property (weak) IBOutlet NSTextField *tfTitle;
@property (weak) IBOutlet NSButton *cbComplete;
@property (weak) IBOutlet NSButton *cbDownloaded;
@property (weak) IBOutlet NSButton *cbReaded;
@property (weak) IBOutlet NSButton *cbWebtoon;

@property (weak, nonatomic) NSView *alignedTo;
@property (weak, nonatomic) AZErgoUpdateWatch *watch;

@end

@implementation AZErgoWatchDetailsPopover
@synthesize watch = _watch, alignedTo = _alignedTo;

- (void) showDetailsOf:(AZErgoUpdateWatch *)watch alignedTo:(NSView *)view {
	self.watch = watch;
	self.alignedTo = view;
}

- (void) setWatch:(AZErgoUpdateWatch *)watch {
	_watch = watch;

	AZErgoManga *manga = [self watchedManga];
	self.tfTitle.stringValue = [manga mainTitle] ?: @"<no title>";
	self.tfFolderPath.stringValue = [manga mangaFolder] ?: @"<...>";
	self.cbComplete.state = manga.isComplete ? NSOnState : NSOffState;
	self.cbDownloaded.state = manga.isDownloaded ? NSOnState : NSOffState;
	self.cbReaded.state = manga.isReaded ? NSOnState : NSOffState;
	self.cbWebtoon.state = manga.isWebtoon ? NSOnState : NSOffState;
}

- (void) setAlignedTo:(NSView *)alignedTo {
	_alignedTo = alignedTo;
	self.behavior = NSPopoverBehaviorTransient;
	if (alignedTo)
		[self showRelativeToRect:alignedTo.bounds ofView:alignedTo preferredEdge:NSMaxYEdge];
}

- (AZErgoManga *) watchedManga {
	return [AZErgoManga mangaByName:self.watch.manga];
}

- (IBAction)actionBrowseFolder:(id)sender {
	NSString *path = [[self watchedManga] mangaFolder];

	[[NSWorkspace sharedWorkspace] openFile:path];
}

- (IBAction)actionCompleteTagChanged:(id)sender {
	BOOL isCompleted = self.cbComplete.state == NSOnState;
	[self toggle:isCompleted tag:AZErgoTagGroupComplete];
}

- (IBAction)actionDownloadedTagChanged:(id)sender {
	BOOL isDownloaded = self.cbDownloaded.state == NSOnState;
	[self toggle:isDownloaded tag:AZErgoTagGroupDownloaded];
}

- (IBAction)actionReadedTagChanged:(id)sender {
	BOOL isReaded = self.cbReaded.state == NSOnState;
	[self toggle:isReaded tag:AZErgoTagGroupReaded];
}

- (void) toggle:(BOOL)on tag:(AZErgoTagGroup)guid {
	AZErgoManga *manga = [self watchedManga];

	if (!!guid)
		[manga toggle:on tagWithGUID:guid];

	self.cbComplete.state = manga.isComplete ? NSOnState : NSOffState;
	self.cbDownloaded.state = manga.isDownloaded ? NSOnState : NSOffState;
	self.cbReaded.state = manga.isReaded ? NSOnState : NSOffState;
}

@end
