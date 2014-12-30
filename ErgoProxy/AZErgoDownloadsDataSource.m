//
//  AZErgoDownloadsDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadsDataSource.h"

#import "AZDownload.h"
#import "AZProxifier.h"


@implementation AZErgoDownloadsDataSource

- (void) filterByManga:(NSString *)manga {
	groups = manga ? rootNodes[manga] : rootNodes;
	if (!groups)
		groups = rootNodes;

	self.filter = rootNodes != groups;
}

- (AZErgoDownloadedAmount) downloaded:(id)node {
	AZErgoDownloadedAmount amount = {.total = 0, .downloaded = 0};

	if ([CustomDictionary isDictionary:node]) {
		CustomDictionary *dic = node;
		for (id key in [dic allKeys]) {
			AZErgoDownloadedAmount sub = [self downloaded:dic[key]];
			amount.total += sub.total;
			amount.downloaded += MIN(sub.downloaded, sub.total);
		}
	} else {
		amount.total = ((AZDownload *)node).totalSize;
		amount.downloaded = ((AZDownload *)node).downloaded;
		if (!amount.total)
			amount.total = 1;

		if (amount.total > amount.downloaded)
			[[AZProxifier sharedProxy] reRegisterDownload:node];
	}

	return amount;
}

#define _DLD_UNFINISHED(_amount) ((!_amount.total) || (_amount.downloaded < _amount.total))

- (void) expandUnfinishedInOutlineView:(NSOutlineView *)outlineView {
	[outlineView collapseItem:nil collapseChildren:YES];

	NSUInteger rows = [outlineView numberOfRows];
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:rows];

	for (int row = 0; row < rows; row++) {
		id item = [outlineView itemAtRow:row];
		[items addObject:item];
	}

	[self expandUnfinishedSubitems:items inOutlineView:outlineView];
}

- (void) expandUnfinishedSubitems:(NSArray *)items inOutlineView:(NSOutlineView *)outlineView {
	NSUInteger count = [items count];
	NSMutableArray *toExpand = [NSMutableArray arrayWithCapacity:count];

	for (CustomDictionary *item in items) {
		BOOL expandable = [self outlineView:outlineView isItemExpandable:item];
		BOOL expand = expandable && _DLD_UNFINISHED([self downloaded:item]);
		if (expand)
			[toExpand addObject:item];
	}

	for (CustomDictionary *item in toExpand) {
		[outlineView expandItem:item];
		if ((items = [item allValues]))
			[self expandUnfinishedSubitems:items inOutlineView:outlineView];
	}
}

- (IBAction)actionDownloadStatusClick:(id)sender {
	if (self.delegate) {
		AZErgoConfigurableTableCellView *dcv = [self cellViewFromSender:sender];
		if (!dcv) return;

		[self.delegate showDownload:dcv.download detailsFromSender:sender];
	}
}

@end

@implementation AZErgoDownloadsDataSource (GroupableDataSource)

- (NSString *) rootIdentifierFromItem:(id)item {
	return [self rootNodeOf:item];
}

- (NSString *) groupIdentifierFromItem:(id)item {
	return [self groupNodeOf:item];
}

- (id) rootNodeOf:(AZDownload *)item {
	return item.manga;
}

- (id) groupNodeOf:(AZDownload *)item {
	return [NSString stringWithFormat:@"%06.1f",item.chapter];
}

- (NSNumber *) orderedUID:(AZDownload *)item {
	return @(truncf(item.chapter * 10) + (item.page / 1000.f));
}

@end
