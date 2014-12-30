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

@implementation AZErgoDownloadGroupCellView

- (NSString *) plainTitle {
	KeyedHolder *holder = ((CustomDictionary *)self.bindedEntity)->owner;
	return [holder->holdedObject capitalizedString];
}

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	NSString *title = nil;
	if ([GroupsDictionary isDictionary:entity]) {
		// this is a manga group

		AZErgoUpdateWatch *manga = [AZErgoDownloadsDataSource relatedManga:entity];

		title = manga ? (manga.title ?: manga.manga) : [self plainTitle];
	} else
		if ([ItemsDictionary isDictionary:entity]) {
			// this is a manga chapter group

			AZErgoUpdateChapter *chapter = [AZErgoDownloadsDataSource relatedChapter:entity];

			title = [self plainTitle];
			float idx = [title floatValue];
			title = [AZErgoDownloadsDataSource formattedChapterIDX:idx];
			title = [title stringByAppendingString:chapter ? [@" \t- " stringByAppendingString:chapter.title] : @""];
		} else
			;

	self.tfGroupTitle.stringValue = title ?: @"<cant aquire title!>";

	AZErgoDownloadedAmount amount = [(AZErgoDownloadsDataSource *)view.dataSource downloaded:entity reclaim:NO];
	NSString *downloaded = [NSString cvtFileSize:amount.downloaded];
	NSString *total = [NSString cvtFileSize:amount.total];
	self.tfDownloadsCount.stringValue = [NSString stringWithFormat:@"%@/%@", downloaded, total];
}

@end
