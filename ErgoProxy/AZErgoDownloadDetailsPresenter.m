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
#import "AZDownloadParameter.h"
#import "AZDownloadParams.h"

#import "AZDataProxyContainer.h"

#import "AZErgoDownloadsDataSource.h"

#import "AZErgoUpdatesCommons.h"

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

- (NSString *) detailsTitle {
	return nil;
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
	AZDownload *download;
}
@synthesize entity = download;

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
	NSString *mangaTitle = relatedManga ? relatedManga.title : nil;

	if (!mangaTitle) {
		if (pageIDX)
			mangaTitle = download.manga;
		else {
			if ([GroupsDictionary isDictionary:self.entity])
				mangaTitle = [self plainTitle];
			else {
				CustomDictionary *downloads = self.entity;
				AZDownload *anyDownload = [[downloads allValues] firstObject];
				if (anyDownload)
					mangaTitle = anyDownload.manga;
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

	[popover.tfURL setCollapsed:NO];
	[popover.bPreview setCollapsed:NO];

	popover.tfURL.stringValue = [download.sourceURL absoluteString];
	popover.tfWidth.stringValue = [NSString stringWithFormat:@"Width: %@ or less", [download.downloadParameters downloadParameter:kDownloadParamMaxWidth].value];
	popover.tfHeight.stringValue = [NSString stringWithFormat:@"Height: %@ or less", [download.downloadParameters downloadParameter:kDownloadParamMaxHeight].value];
	popover.tfQuality.stringValue = [NSString stringWithFormat:@"Quality: %@", [download.downloadParameters downloadParameter:kDownloadParamQuality].value];

	popover.tfStorage.stringValue = download.storage.url ? [download.storage.url absoluteString] : @"<storage not saved to db!>";

	popover.tfScanID.stringValue = [NSString stringWithFormat:@"scans/id/%lu",download.scanID];


	BOOL fileExists = !![download localFileSize];
	[popover.bPreview setEnabled:fileExists];
	[popover.bPreviewTrash setEnabled:fileExists];


	BOOL lock = download.lastDownloadIteration > [NSDate timeIntervalSinceReferenceDate];
	[popover.bLock setImage:[NSImage imageNamed:lock ? NSImageNameLockLockedTemplate : NSImageNameLockUnlockedTemplate]];

	NSDecimalNumber *isWebtoon = [download.downloadParameters downloadParameter:kDownloadParamIsWebtoon].value;
	popover.tfIsWebtoon.stringValue = [isWebtoon boolValue] ? @"Is a webtoon" : @"";

	popover.tfHash.stringValue = download.proxifierHash ? download.proxifierHash : @"<hash not aquired yet>";

	[popover.tfError setCollapsed:!HAS_BIT(download.state, AZErgoDownloadStateFailed)];
	popover.tfError.stringValue = download.error ? download.error : @"";
}

- (void) dropHash {
	[download downloadError:nil];
	download.proxifierHash = nil;
	[[AZProxifier sharedProxy] reRegisterDownload:download];
	UNSET_BIT(download.state, AZErgoDownloadStateResolved);
	UNSET_BIT(download.state, AZErgoDownloadStateAquired);
	UNSET_BIT(download.state, AZErgoDownloadStateDownloaded);
	download.downloaded = 0;

	self.popover.tfHash.stringValue = @"";
}

- (void) deleteEntity {
	[download delete];
	[(id)[[AZDataProxyContainer getInstance] dataProxy] notifyChangedWithUserInfo:nil];
}

- (void) previewEntity {
	[[NSWorkspace sharedWorkspace] openFile:[download localFilePath]];
}

- (void) browseEntityStorage {
	[[NSWorkspace sharedWorkspace] openURL:download.storage.url];
}

- (void) browseEntity {
	[[NSWorkspace sharedWorkspace] openURL:[download.storage.url URLByAppendingPathComponent:[NSString stringWithFormat:@"scans/id/%lu",download.scanID]]];
}

- (void) setLockState:(BOOL)lock {
	[self.popover.bLock setImage:[NSImage imageNamed:lock ? NSImageNameLockLockedTemplate : NSImageNameLockUnlockedTemplate]];
}

- (void) lockEntity {
	BOOL lock = [self.popover.bLock.image.name isEqualToString:NSImageNameLockUnlockedTemplate];

	[self recursive:self.entity lock:lock];

	[self setLockState:lock];
}

- (void) recursive:(id)sender lock:(BOOL)lock {
	NSTimeInterval distantFuture = [[NSDate distantFuture] timeIntervalSinceReferenceDate];

	if ([sender isKindOfClass:[AZDownload class]]) {
		AZDownload *_download = sender;
		if (lock) // paused already
			_download.lastDownloadIteration = distantFuture;
		else
			_download.lastDownloadIteration = 0;

		[_download.stateListener download:_download stateChanged:_download.state];
	} else
		if ([sender isKindOfClass:[CustomDictionary class]])
			for (id sub in [(CustomDictionary *)sender allValues])
				[self recursive:sub lock:lock];
}

- (void) trashEntity {
	[self trashDownload:[NSURL fileURLWithPath:[download localFilePath]]];
}

- (void) trashDownload:(NSURL *)url {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	if (![fm trashItemAtURL:url
				 resultingItemURL:nil
										error:&error]) {
		if (error.domain == NSCocoaErrorDomain)
			if (error.code == 3328) {
				[AZUtils notifyErrorMsg:NSLocalizedString(@"Can't move to trash: file located at remote drive. Move to Downloads directory on this computer?", @"")
										withButtons:@[
																	NSLocalizedString(@"Ok", @"Ok button title"),
																	NSLocalizedString(@"Delete permanently", @"Delete permanently button title"),
																	NSLocalizedString(@"Cancel", @"Cancel button title"),
																	]
											 andBlock:^(NSUInteger button) {

												 NSArray *path = [url pathComponents];
												 path = [path subarrayWithRange:NSMakeRange([path count] - 3, 3)];
												 NSURL *local = [[AZUtils applicationDownloadsDirectory] URLByAppendingPathComponent:[path componentsJoinedByString:@"/"]];

												 NSError *error = nil;
												 switch (button) {
													 case NSAlertFirstButtonReturn:
													 case NSAlertSecondButtonReturn: {

														 [fm createDirectoryAtURL:[local URLByDeletingLastPathComponent]
													withIntermediateDirectories:YES attributes:nil
																								error:nil];
														 [fm removeItemAtURL:local error:nil];

														 if (button != NSAlertFirstButtonReturn)
															 break;

														 if ([fm moveItemAtURL:url toURL:local error:&error])
															 [self trashDownload:local];
														 else
															 [AZUtils notifyErrorMsg:[NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"Can't move to Downloads directory", @""), [error localizedDescription]]];

														 break;
													 }

													 default:
														 break;
												 }
											 }];

				return;
			}

		[AZUtils notifyErrorMsg:[error localizedDescription]];
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
	[popover.tfURL setCollapsed:YES];

	[self setLockState:NO];
}

- (void) dropHash {
	AZErgoDownloadDetailsPresenter *ddp = [AZErgoDownloadDetailsPresenter new];
	for (AZDownload *download in [group allValues])
		[[ddp presenterForEntity:download in:self.popover] dropHash];
}

- (void) deleteEntity {
	AZErgoDownloadDetailsPresenter *ddp = [AZErgoDownloadDetailsPresenter new];
	for (AZDownload *download in [group allValues])
		[[ddp presenterForEntity:download in:self.popover] deleteEntity];
}

- (void) lockEntity {
	AZErgoDownloadDetailsPresenter *ddp = [AZErgoDownloadDetailsPresenter new];

	[[ddp presenterForEntity:self.entity in:self.popover] lockEntity];
}

- (void) previewEntity {
}

- (void) browseEntityStorage {
}

- (void) browseEntity {
}

- (void) trashEntity {
	[self recursiveTrash:group];
}

- (void) recursiveTrash:(id)entity {
	if ([entity isKindOfClass:[AZDownload class]])
		[[super presenterForEntity:entity in:self.popover] trashDownload:[NSURL fileURLWithPath:[entity localFilePath]]];
	//	else
	//		for (id sub in [entity allValues])
	//			[self recursiveTrash:sub];
}

@end
