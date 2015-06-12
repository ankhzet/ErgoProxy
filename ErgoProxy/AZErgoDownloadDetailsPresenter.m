//
//  AZErgoDownloadDetailsPresenter.m
//  ErgoProxy
//
//  Created by Ankh on 26.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadDetailsPresenter.h"
#import "AZErgoDownloadDetailsPopover.h"
#import "AZCollapsingView.h"

#import "AZProxifier.h"
#import "AZStorage.h"
#import "AZDownload.h"
#import "AZDownloadParameter.h"
#import "AZDownloadParams.h"

#import "AZErgoDownloadPrefsWindowController.h"

#import "AZDataProxy.h"

#import "AZErgoDownloadsDataSource.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"

@implementation AZErgoEntityDetailsPresenter {
@public
	id _entity;
}
@synthesize entity = _entity, popover = _popover;

- (instancetype) presenterForEntity:(id)entity in:(AZErgoDownloadDetailsPopover *)popover {
	self.entity = entity;
	self.popover = popover;
	self.popover.tfTitle.stringValue = [self detailsTitle];
	return self;
}

- (void) presentEntity:(id)entity detailsIn:(AZErgoDownloadDetailsPopover *)popover {
	[self presenterForEntity:entity in:popover];
}

- (void) presentAction:(void(^)(AZErgoEntityDetailsPresenter *presenter))block {
	block(self);
}

- (NSString *) detailsTitle {
	return nil;
}

- (void) recursive:(id)sender block:(void(^)(id entity))block {
	AZ_IFCLASS(sender, CustomDictionary, *dictionary, {
		for (id entity in [dictionary allValues])
			[self recursive:entity block:block];
	}) else
		block(sender);
}

- (void) dropHash {

}
- (void) deleteEntity {

}
- (void) previewEntity {

}
- (void) browseEntityStorage {

}
- (void) browseEntity {

}
- (void) trashEntity {

}
- (void) lockEntity {

}

@end

@implementation AZErgoDownloadDetailsPresenter {
	AZDownload *__download;
}
@synthesize entity = __download;

// TODO: refactor uggly direct param access

- (NSString *) plainTitle {
	if ([CustomDictionary isDictionary:self.entity]) {
		KeyedHolder *holder = ((CustomDictionary *)self.entity)->owner;
		return holder->holdedObject;
	}

	return [self.entity description];
}

/*
 manga:

 chapterTitle = @relatedChapter ? "@relatedChapter" : ""
 mangaTitle = @relatedManga ?: "@entity (not checked by wather yet)"
 mangaTitle = @chapterTitle ? " @relatedManga - " : @mangaTitle

 formattedPageIDX = @formattedPageIDX ? ", @formattedPageIDX" : ""
 idxses = (@formattedChIDX || @formattedPageIDX) ? "[@formattedChIDX@formattedPageIDX]" : ""
 title = "@idxes@mangaTitle@chapterTitle"
 */


- (NSString *) detailsTitle {
	AZErgoUpdateWatch *relatedManga = [AZErgoDownloadsDataSource relatedManga:self.entity];
	AZErgoUpdateChapter *relatedChapter = [AZErgoDownloadsDataSource relatedChapter:self.entity];
	NSString *chapterIDX = nil;
	NSString *pageIDX = nil;

	AZDownload *downloadEntity = self.entity;
	if ([self.entity isKindOfClass:[AZDownload class]]) {
		chapterIDX = [AZErgoDownloadsDataSource formattedChapterIDX:downloadEntity.chapter];
		pageIDX = [AZErgoDownloadsDataSource formattedChapterPageIDX:downloadEntity.page];
	} else
		if ([self.entity isKindOfClass:[ItemsDictionary class]]) {
			chapterIDX = [self plainTitle];
			float idx = [chapterIDX floatValue];
			chapterIDX = [AZErgoDownloadsDataSource formattedChapterIDX:idx];
		}

	NSString *idxes = nil;
	if (!(!chapterIDX && !pageIDX)) {
		pageIDX = pageIDX ? [@", " stringByAppendingString:pageIDX] : nil;
		idxes = [NSString stringWithFormat:@"[%@%@]", chapterIDX, pageIDX ?: @""];
	} else
		idxes = @"";

	NSString *chapterTitle = relatedChapter ? relatedChapter.title : nil;
	NSString *mangaTitle = relatedManga.relatedManga.mainTitle ?: nil;

	if (!mangaTitle) {
		if (pageIDX)
			mangaTitle = __download.forManga.mainTitle;
		else {
			if ([GroupsDictionary isDictionary:self.entity])
				mangaTitle = [self plainTitle];
			else {
				CustomDictionary *downloads = self.entity;
				AZDownload *anyDownload = [[downloads allValues] firstObject];
				if (anyDownload)
					mangaTitle = anyDownload.forManga.mainTitle;
			}
		}
	}

	if (!chapterTitle) {
		if (chapterIDX)
			chapterTitle = mangaTitle ? chapterIDX : nil;
		else
			if ([ItemsDictionary isDictionary:downloadEntity])
				chapterTitle = [self plainTitle];
	}

	if (chapterTitle)
		mangaTitle = mangaTitle ? [@[@" ", mangaTitle, @" - "] componentsJoinedByString:@""] : nil;


	mangaTitle = mangaTitle ?: @"";
	chapterTitle = chapterTitle ?: @"";

	NSString *title = [[idxes stringByAppendingString:mangaTitle] stringByAppendingString:chapterTitle];

	return title;
}

- (void) presentEntity:(id)entity detailsIn:(AZErgoDownloadDetailsPopover *)popover {
	[self presenterForEntity:entity in:popover];

	[[popover.tfURL superview] setCollapsed:NO];
	[popover.bPreview setCollapsed:NO];


	AZDownload *download = __download;
#define _LABEL(_key, _add) ({\
id val = [download.downloadParameters downloadParameter:(_key)].value;\
val = (!val) ? LOC_FORMAT(@"server-default") : val;\
LOC_FORMAT((_add), val);\
})

	popover.tfURL.stringValue = download.sourceURL;
	popover.tfWidth.stringValue = _LABEL(kDownloadParamMaxWidth, @"Width: %@ or less");
	popover.tfHeight.stringValue = _LABEL(kDownloadParamMaxHeight, @"Height: %@ or less");
	popover.tfQuality.stringValue = _LABEL(kDownloadParamQuality, @"Quality: %@");

	popover.tfStorage.stringValue = download.storage.url ?: LOC_FORMAT(@"<storage not saved to db!>");

	popover.tfScanID.stringValue = [NSString stringWithFormat:@"scans/id/%lu",download.scanID];


	BOOL fileExists = !![download localFileSize];
	[popover.bPreview setEnabled:fileExists];
	[popover.bPreviewTrash setEnabled:fileExists];


	BOOL lock = download.lastDownloadIteration > [NSDate timeIntervalSinceReferenceDate];
	[popover.bLock setImage:[NSImage imageNamed:lock ? NSImageNameLockLockedTemplate : NSImageNameLockUnlockedTemplate]];

	NSDecimalNumber *isWebtoon = [download.downloadParameters downloadParameter:kDownloadParamIsWebtoon].value;
	popover.tfIsWebtoon.stringValue = [isWebtoon boolValue] ? LOC_FORMAT(@"Is a webtoon") : @"";

	[popover.tfHash.cell setPlaceholderString:LOC_FORMAT(@"<hash not aquired yet>")];
	popover.tfHash.stringValue = download.proxifierHash ?: @"";

	[popover.tfError setCollapsed:!HAS_BIT(download.state, AZErgoDownloadStateFailed)];
	popover.tfError.stringValue = download.error ?: @"";
}

- (void) deleteEntity {
	[self recursive:self.entity block:^(AZDownload *entity) {
		[entity delete];
	}];

	[[AZDataProxy sharedProxy] notifyChangedWithUserInfo:nil];
}

- (void) previewEntity {
	[[NSWorkspace sharedWorkspace] openFile:[__download localFilePath]];
}

- (void) browseEntityStorage {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:__download.storage.url]];
}

- (void) browseEntity {
	NSURL *url = [NSURL URLWithString:__download.storage.url];
	url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"scans/id/%lu", __download.scanID]];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (void) setLockState:(BOOL)lock {
	[self.popover.bLock setImage:[NSImage imageNamed:lock ? NSImageNameLockLockedTemplate : NSImageNameLockUnlockedTemplate]];
}

- (void) lockEntity {
	BOOL lock = [self.popover.bLock.image.name isEqualToString:NSImageNameLockUnlockedTemplate];

	NSTimeInterval distantFuture = [[NSDate distantFuture] timeIntervalSinceReferenceDate];

	AZProxifier *proxifier = [AZProxifier sharedProxifier];
	[self recursive:self.entity block:^(AZDownload *download) {
		if (lock) // paused already
			download.lastDownloadIteration = distantFuture;
		else {
			download.lastDownloadIteration = 0;
			[proxifier registerForDownloading:download];
		}

		[download notifyStateChanged];
	}];

	[self setLockState:lock];
}

- (void) dropHash {
	__block BOOL keepParams = !([NSEvent modifierFlags] & NSCommandKeyMask);
	BOOL peekSpecificParams = (!keepParams) && ([NSEvent modifierFlags] & NSShiftKeyMask);

	__block AZDownloadParams *prefs = nil;

	if (!keepParams)
		[self recursive:self.entity block:^(AZDownload *entity) {
			if (keepParams)
				return;

			prefs = [[AZErgoDownloadPrefsWindowController sharedController] aquireParams:!peekSpecificParams forManga:entity.forManga];
			keepParams = YES;
		}];

	AZProxifier *proxifier = [AZProxifier sharedProxifier];
	[self recursive:self.entity block:^(AZDownload *entity) {
		[entity reset:prefs];
		[proxifier registerForDownloading:entity];
	}];

	self.popover.tfHash.stringValue = @"";
}

- (void) trashEntity {
	[self recursive:self.entity block:^(AZDownload *entity) {
		[self trashDownload:[NSURL fileURLWithPath:entity.localFilePath]];
	}];
}

- (void) trashDownload:(NSURL *)url {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	if (![fm trashItemAtURL:url
				 resultingItemURL:nil
										error:&error]) {
		if (error.domain == NSCocoaErrorDomain)
			if (error.code == 3328) {
				[AZUtils notifyErrorMsg:NSLocalizedString(@"Can't move to trash: file located at remote drive. Move to Downloads directory of the program first?", @"")
										withButtons:@[
																	NSLocalizedString(@"Ok", @"Ok button title"),
																	NSLocalizedString(@"Delete permanently", @"Delete permanently button title"),
																	NSLocalizedString(@"Cancel", @"Cancel button title"),
																	]
											 andBlock:^(AZDialogReturnCode button) {
												 if (button == AZDialogReturnCancel)
													 return;

												 NSArray *path = [url pathComponents];
												 path = [path subarrayWithRange:NSMakeRange([path count] - 3, 3)];
												 NSURL *local = [[AZUtils applicationDownloadsDirectory] URLByAppendingPathComponent:[path componentsJoinedByString:@"/"]];

												 NSError *error = nil;
												 switch (button) {
													 case AZDialogReturnOk:
													 case AZDialogReturnNo: {

														 if ([fm fileExistsAtPath:[local path]]) {
															 [fm removeItemAtURL:local error:nil];
														 }

														 if (button == AZDialogReturnNo) {
															 [fm removeItemAtURL:url error:nil];
															 break;
														 }

														 [fm createDirectoryAtURL:[local URLByDeletingLastPathComponent]
													withIntermediateDirectories:YES attributes:nil
																								error:nil];

														 if ([fm moveItemAtURL:url toURL:local error:&error])
															 [self trashDownload:local];
														 else
															 AZErrorTip(LOC_FORMAT(@"Can't move to Downloads directory:\n%@", [error localizedDescription]));

														 break;
													 }

													 default:
														 break;
												 }
											 }];

				return;
			}

		AZErrorTip([error localizedDescription]);
	}
}

@end


@implementation AZErgoChapterDetailsPresenter  {
	CustomDictionary *group;
}
@synthesize entity = group;

// TODO: refactor uggly direct param access

- (void) presentEntity:(id)entity detailsIn:(AZErgoDownloadDetailsPopover *)popover {
	[self presenterForEntity:entity in:popover];

	[popover.bPreview setCollapsed:YES];
	[[popover.tfURL superview] setCollapsed:YES];

	[self setLockState:NO];
}

- (void) previewEntity {
}

- (void) browseEntityStorage {
}

- (void) browseEntity {
}

@end
