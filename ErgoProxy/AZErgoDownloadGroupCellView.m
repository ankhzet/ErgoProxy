//
//  AZErgoDownloadGroupCellView.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadsDataSource.h"
#import "AZErgoDownloadGroupCellView.h"

#import "AZErgoUpdatesCommons.h"

#import "AZErgoMangaCommons.h"

@implementation AZErgoDownloadGroupCellView

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	NSString *title = nil;
	if ([GroupsDictionary isDictionary:entity]) {
		// this is a manga group

		AZErgoUpdateWatch *mangaWatch = [AZErgoDownloadsDataSource relatedManga:entity];
		AZErgoManga *manga = [AZErgoManga mangaByName:mangaWatch.manga];

		title = [manga description] ?: [self plainTitle];
	} else
		if ([ItemsDictionary isDictionary:entity]) {
			// this is a manga chapter group

			AZErgoUpdateChapter *chapter = [AZErgoDownloadsDataSource relatedChapter:entity];

			title = chapter.fullTitle;
		} else
			;

	AZErgoDownloadedAmount amount = [(AZErgoDownloadsDataSource *)view.dataSource downloaded:entity];
	NSString *amountString = nil;
	NSString *downloaded = [NSString cvtFileSize:amount.downloaded];
	if (amount.downloaded != amount.total) {
		NSString *total = [NSString cvtFileSize:amount.total];
		amountString = [NSString stringWithFormat:@"%@/%@", downloaded, total];
	} else
		amountString = downloaded;


	self.tfGroupTitle.stringValue = title ?: @"<cant aquire title!>";
	self.tfDownloadsCount.stringValue = amountString;
}

@end
