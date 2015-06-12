//
//  AZErgoMangaDetailsPopover.m
//  ErgoProxy
//
//  Created by Ankh on 05.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaDetailsPopover.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"

#import "AZErgoBrowserTab.h"
#import "AZErgoMangaInfoTab.h"
#import "AZProxifier.h"

#import "AZErgoChapterStateWindowController.h"
#import "AZErgoDownloadPrefsWindowController.h"

@interface AZErgoMangaDetailsPopover ()

@property (weak) IBOutlet NSTextField *tfFolderPath;
@property (weak) IBOutlet NSTextField *tfSourceURL;
@property (weak) IBOutlet NSTextField *tfTitle;
@property (weak) IBOutlet NSButton *cbComplete;
@property (weak) IBOutlet NSButton *cbDownloaded;
@property (weak) IBOutlet NSButton *cbReaded;
@property (weak) IBOutlet NSButton *cbWebtoon;

@property (weak) IBOutlet NSButton *bLock;

@property (nonatomic) AZErgoManga *associatedData;

@property (nonatomic) BOOL locked;

@end

@implementation AZErgoMangaDetailsPopover

+ (NSString *) nibName {
	return @"MangaStatesPopover";
}

- (NSRectEdge) preferredEdge {
	return NSMaxXEdge;
}

- (void) setAssociatedData:(AZErgoManga *)manga {
	[super setAssociatedData:manga];

	self.tfTitle.stringValue = manga.mainTitle ?: @"<no title>";

	self.tfFolderPath.stringValue = manga.mangaFolder ?: @"<...>";
	self.tfSourceURL.stringValue = self.watch.mangaURL ?: @"<...>";

	self.cbComplete.state = manga.isComplete ? NSOnState : NSOffState;
	self.cbDownloaded.state = manga.isDownloaded ? NSOnState : NSOffState;
	self.cbReaded.state = manga.isReaded ? NSOnState : NSOffState;
	self.cbWebtoon.state = manga.isWebtoon ? NSOnState : NSOffState;
}

- (AZErgoUpdateWatch *) watch {
	return [AZErgoUpdateWatch watchByManga:self.associatedData.name];
}

- (BOOL) locked {
	return [self.bLock.image.name isEqualToString:NSImageNameLockLockedTemplate];
}

- (void) setLocked:(BOOL)locked {
	[self.bLock setImage:[NSImage imageNamed:locked ? NSImageNameLockLockedTemplate : NSImageNameLockUnlockedTemplate]];
}

- (IBAction)actionReadManga:(id)sender {
	[AZErgoBrowserTab navigateToWithData:self.associatedData];
}

- (IBAction)actionShowMangaInfo:(id)sender {
	[AZErgoMangaInfoTab navigateToWithData:self.associatedData];
}

- (IBAction)actionBrowseChapters:(id)sender {
	[[AZErgoChapterStateWindowController sharedController] showStateController:self.associatedData];
}

- (IBAction)actionBrowseFolder:(id)sender {
	NSString *path = self.associatedData.mangaFolder;

	[[NSWorkspace sharedWorkspace] openFile:path];
}

- (IBAction)actionBrowseSourceURL:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.watch.mangaURL]];
}

- (IBAction)actionResetDownloads:(id)sender {
	BOOL keepParams = !AZ_KEYDOWN(Command);
	BOOL peekSpecificParams = (!keepParams) && AZ_KEYDOWN(Shift);

	AZDownloadParams *prefs = keepParams ? nil : [[AZErgoDownloadPrefsWindowController sharedController] aquireParams:!peekSpecificParams
																																																					 forManga:self.associatedData];
	NSSet *downloads = [NSSet setWithArray:[AZDownload all:@"forManga == %@", self.associatedData]];

	AZProxifier *proxifier = [AZProxifier sharedProxifier];
	[proxifier reRegisterDownloads:^BOOL(AZDownload *download) {
		if (![downloads containsObject:download])
			return YES;

		[download reset:prefs];

		return YES;
	}];
}

- (IBAction)actionLockDownloads:(id)sender {
	BOOL lock = !self.locked;

	NSTimeInterval distantFuture = [[NSDate distantFuture] timeIntervalSinceReferenceDate];

	AZProxifier *proxifier = [AZProxifier sharedProxifier];

	NSSet *downloads = [NSSet setWithArray:[AZDownload all:@"forManga == %@", self.associatedData]];
	[proxifier reRegisterDownloads:^BOOL(AZDownload *download) {
		if (![downloads containsObject:download])
			return YES;

		if (lock) // paused already
			download.lastDownloadIteration = distantFuture;
		else {
			download.lastDownloadIteration = 0;
		}

		[download notifyStateChanged];

		return YES;
	}];

	self.locked = lock;
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
	AZErgoManga *manga = self.associatedData;

	if (!!guid)
		[manga toggle:on tagWithGUID:guid];

	self.cbComplete.state = manga.isComplete ? NSOnState : NSOffState;
	self.cbDownloaded.state = manga.isDownloaded ? NSOnState : NSOffState;
	self.cbReaded.state = manga.isReaded ? NSOnState : NSOffState;
}

@end
