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
#import "AZErgoUpdatesCommons.h"


@implementation AZErgoDownloadsDataSource

- (void) filterByManga:(NSString *)manga {
	groups = manga ? rootNodes[manga] : rootNodes;
	if (!groups)
		groups = rootNodes;

	self.filter = rootNodes != groups;
}

- (AZErgoDownloadedAmount) downloaded:(id)node reclaim:(BOOL)reclaim {
	AZErgoDownloadedAmount amount = {.total = 0, .downloaded = 0};

	if ([CustomDictionary isDictionary:node]) {
		CustomDictionary *dic = node;
		for (id key in [dic allKeys]) {
			AZErgoDownloadedAmount sub = [self downloaded:dic[key] reclaim:reclaim];
			amount.total += sub.total;
			amount.downloaded += MIN(sub.downloaded, sub.total);
		}
	} else {
		amount.total = ((AZDownload *)node).totalSize;
		amount.downloaded = ((AZDownload *)node).downloaded;
//		if (!amount.total)
//			amount.total = 1;

		if (reclaim && ((amount.downloaded < amount.total) || !amount.total))
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
		BOOL expand = expandable && _DLD_UNFINISHED([self downloaded:item reclaim:NO]);
		if (expand)
			[toExpand addObject:item];
	}

	for (CustomDictionary *item in toExpand) {
		[outlineView expandItem:item];
		if ((items = [item allValues]))
			[self expandUnfinishedSubitems:items inOutlineView:outlineView];
	}
}

- (IBAction) actionDelegatedClick:(id)sender {
	if (self.delegate) {
		AZErgoConfigurableTableCellView *dcv = [self cellViewFromSender:sender];
		if (!dcv) return;

		[self.delegate showEntity:dcv.bindedEntity detailsFromSender:sender];
	}
}

@end

@implementation AZErgoDownloadsDataSource (DataFormatting)

+ (NSString *) formattedChapterIDX:(float) chapter {
	NSString *chap = (!!((int)(chapter * 10) % 10))
	? [NSString stringWithFormat:@"ch. %.1f", chapter]
	: [NSString stringWithFormat:@"ch. %d", (int)(chapter)];

	return chap;
}

+ (NSString *) formattedChapterPageIDX:(NSUInteger) page {
	return [NSString stringWithFormat:@"p. %lu", page];
}

+ (AZErgoUpdateWatch *) relatedManga:(id)node {
	CustomDictionary *asDictionary = node;

	NSString *mangaName = nil;

	if ([GroupsDictionary isDictionary:asDictionary]) {
		// this is a root node with manga name in it
		KeyedHolder *holder = asDictionary->owner;
		mangaName = holder->holdedObject;
	} else
		if ([ItemsDictionary isDictionary:asDictionary]) {
			// this is a chapter node with chapter id in it

			AZDownload *anyDownload = [[asDictionary allValues] firstObject];
			if (anyDownload)
				mangaName = anyDownload.manga;
		} else
			mangaName = ((AZDownload *)node).manga;

	AZErgoUpdateWatch *related = nil;
	if (!!mangaName)
		related = [AZErgoUpdateWatch filter:[NSPredicate predicateWithFormat:@"manga like[c] %@", mangaName] limit:1];

	return related;
}

+ (AZErgoUpdateChapter *) relatedChapter:(id)node {
	NSNumber *chapterIdx = nil;
	NSString *manga = nil;

	if ([GroupsDictionary isDictionary:node]) {
		// this is a root node with manga name in it, so - no chapter idx'es available
		return nil;
	} else
		if ([ItemsDictionary isDictionary:node]) {
			// this is a chapter node with chapter id in it

			AZDownload *anyDownload = [[(CustomDictionary *)node allValues] firstObject];
			if (anyDownload) {
				manga = anyDownload.manga;
				chapterIdx = @(anyDownload.chapter);
			} else {
				AZErgoUpdateWatch *relatedManga = [self relatedManga:node];
				manga = relatedManga.manga;
			}
		} else {
			manga = ((AZDownload *)node).manga;
			chapterIdx = @(((AZDownload *)node).chapter);
		}

	AZErgoUpdateChapter *related = nil;


	if (!(!chapterIdx || !manga))
		related = [AZErgoUpdateChapter filter:[NSPredicate predicateWithFormat:@"watch.manga like[c] %@ and abs(idx - %lf) < 0.01", manga, [chapterIdx floatValue]] limit:1];

	return related;
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
