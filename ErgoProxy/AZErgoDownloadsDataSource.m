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

#import "AZErgoConfigurableTableCellView.h"
#import "KeyedHolder.h"
#import "CustomDictionary.h"

@interface Manga : KeyedHolder @end @implementation Manga @end
@interface Chapter : KeyedHolder @end @implementation Chapter @end

@interface MangaDictionary : CustomDictionary @end @implementation MangaDictionary @end
@interface ChapterDictionary : CustomDictionary @end @implementation ChapterDictionary @end
@interface DownloadDictionary : CustomDictionary @end @implementation DownloadDictionary @end

@implementation AZErgoDownloadsDataSource {
	MangaDictionary *downloadGroups, *baseDownloads;
	NSMutableDictionary *_uDownloads;
	NSDictionary *schedulesArray;
	BOOL filter;
	NSMutableDictionary *keysMapping;
}

- (void) filterByManga:(NSString *)manga {
	downloadGroups = manga ? baseDownloads[manga] : baseDownloads;
	if (!downloadGroups)
		downloadGroups = baseDownloads;

	filter = baseDownloads != downloadGroups;
}

- (void) setData:(NSArray *)data {
	_data = data;

	_uDownloads = [NSMutableDictionary dictionary];
	for (AZDownload *download in data) {
		NSString *manga = download.manga;

		NSMutableArray *mangaDownloads = _uDownloads[manga] ? _uDownloads[manga] : (_uDownloads[manga] = [NSMutableArray array]);

		[mangaDownloads addObject:download];
	}

	NSMutableDictionary *cachedHolders = [NSMutableDictionary dictionary];

	baseDownloads = [MangaDictionary custom:nil];
	for (NSArray *mangaDownloads in [_uDownloads allValues]) {
		for (AZDownload *download in mangaDownloads) {
			Manga *manga = cachedHolders[download.manga];
			if (!manga) manga = cachedHolders[download.manga] = [Manga holderFor:download.manga];

			Class c = _groupped ? [ChapterDictionary class] : [DownloadDictionary class];
			DownloadDictionary *downloads = baseDownloads[manga] ? baseDownloads[manga] : (baseDownloads[manga] = [c custom:manga]);

			if (_groupped) {
				NSString *chapStr = [NSString stringWithFormat:@"%06.1f",download.chapter];
				NSString *idx = [[download.manga stringByAppendingString:@" "] stringByAppendingString:chapStr];
				Chapter *chapter = cachedHolders[idx];
				if (!chapter) chapter = cachedHolders[idx] = [Chapter holderFor:chapStr];
				downloads = downloads[chapter] ? downloads[chapter] : (downloads[chapter] = [DownloadDictionary custom:chapter]);
			}

			float uid = truncf(download.chapter * 10) + (download.page / 1000.f);

			downloads[@(uid)] = download;
		}
	}

	downloadGroups = baseDownloads;

	[self sort];
}

- (void) sort {
	keysMapping = [NSMutableDictionary dictionary];
	keysMapping[@0] = [self sortDictionary:downloadGroups];
}

- (NSArray *) sortDictionary:(CustomDictionary *)dic {
	for (id key in [dic allKeys])
		if ([CustomDictionary isDictionary:dic[key]])
			keysMapping[key] = [self sortDictionary:dic[key]];

	return [[dic allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (void) setGroupped:(BOOL)groupped {
	if (groupped == _groupped)
		return;

	_groupped = groupped;
	[self setData:_data];
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
		AZErgoDownloadCellView *dcv = sender;
		while (dcv && ![dcv isKindOfClass:[AZErgoDownloadCellView class]]) {
			dcv = (id)((NSView *)dcv).superview;
		}
		if (!dcv) return;

		[self.delegate showDownload:dcv.download detailsFromSender:sender];
	}
}



- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	NSString *cellType = @"DownloadCell";

	if (item == outlineView)
		cellType = @"HeaderCell";
	else {
		if ([CustomDictionary isDictionary:item]) {
			CustomDictionary *dictionary = item;
			if ([Manga isA:dictionary->owner])
				cellType = @"GroupCell";
			if ([Chapter isA:dictionary->owner])
				cellType = @"GroupCell";
		}
	}

	AZErgoConfigurableTableCellView *cellView = [outlineView makeViewWithIdentifier:cellType owner:self];
	[cellView configureForEntity:item inOutlineView:outlineView];

	return cellView;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSInteger count = 0;

	if (!item) // if root node
		count = [downloadGroups count] + (filter ? 1 : 0);
	else
		if ([CustomDictionary isDictionary:item])
			count = [item count];

	return count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if (!item) { // root node
		if (filter && !index)
			return outlineView;

		index = index - (filter ? 1 : 0);
		return downloadGroups[keysMapping[@0][index]];
	}

	if ([CustomDictionary isDictionary:item]) {
		id key = ((CustomDictionary *)item)->owner;
		return item[keysMapping[key][index]];
	}

	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return [CustomDictionary isDictionary:item];//[item isKindOfClass:[PagesDictionary class]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return [CustomDictionary isDictionary:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
	return [self outlineView:outlineView isItemExpandable:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;//[self outlineView:outlineView isItemExpandable:item];
}

/* NOTE: this method is optional for the View Based OutlineView.
 */
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([CustomDictionary isDictionary:item])
		return ((CustomDictionary *)item)->owner;

	return item;
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	return ([CustomDictionary isDictionary:item] || [item isKindOfClass:[NSOutlineView class]]) ? 20 : 24.f;
}

@end
