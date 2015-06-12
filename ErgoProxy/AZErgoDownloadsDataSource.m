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

#import "AZErgoMangaCommons.h"

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
		AZDownload *download = ((AZDownload *)node);
		amount.total = download.totalSize;
		amount.downloaded = download.downloaded;
	}

	return amount;
}

- (BOOL) unfinished:(id)node {
	if ([CustomDictionary isDictionary:node]) {
		CustomDictionary *dic = node;
		for (id key in [dic allKeys])
			if ([self unfinished:dic[key]])
				return YES;

	} else {
		AZDownload *download = node;
		return (download.lastDownloadIteration <= [NSDate timeIntervalSinceReferenceDate]) && !download.isFinished;
	}

	return NO;
}

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
		BOOL expand = expandable && [self unfinished:item];
		if (expand)
			[toExpand addObject:item];
	}

	for (CustomDictionary *item in toExpand) {
		[outlineView expandItem:item];
		if ((items = [item allValues]))
			[self expandUnfinishedSubitems:items inOutlineView:outlineView];
	}
}

@end

@implementation AZErgoDownloadsDataSource (DataFormatting)

+ (NSString *) formattedChapterIDX:(float)chapter prefix:(BOOL)prefix {
	NSString *chap = (!!((int)(chapter * 10) % 10))
	? [NSString stringWithFormat:@"%.1f", chapter]
	: [NSString stringWithFormat:@"%d", (int)(chapter)];
	return prefix ? [@"ch. " stringByAppendingString:chap] : chap;
}

+ (NSString *) formattedChapterIDX:(float)chapter {
	return [self formattedChapterIDX:chapter prefix:YES];
}

+ (NSString *) formattedChapterPageIDX:(NSUInteger)page prefix:(BOOL)prefix {
	return prefix ? [@"p. " stringByAppendingString:[@(page) stringValue]] : [@(page) stringValue];
}

+ (NSString *) formattedChapterPageIDX:(NSUInteger)page {
	return [self formattedChapterPageIDX:page prefix:YES];
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
				mangaName = anyDownload.forManga.name;
		} else
			mangaName = ((AZDownload *)node).forManga.name;

	AZErgoUpdateWatch *related = nil;
	if (!!mangaName)
		related = [AZErgoUpdateWatch any:@"manga == %@", mangaName];

	return related;
}

+ (AZErgoUpdateChapter *) relatedChapter:(id)node {
	NSNumber *chapterIdx = nil;
	NSString *manga = nil;

	if ([GroupsDictionary isDictionary:node]) {
		// this is a root node with manga name in it, so - no chapter idx'es available
	} else
		if ([ItemsDictionary isDictionary:node]) {
			// this is a chapter node with chapter id in it

			AZDownload *anyDownload = [[(CustomDictionary *)node allValues] firstObject];
			if (anyDownload) {
				return anyDownload.updateChapter;
			} else {
				AZErgoUpdateWatch *relatedManga = [self relatedManga:node];
				manga = relatedManga.manga;

				AZErgoUpdateChapter *related = nil;

				if (!(!chapterIdx || !manga))
					related = [AZErgoUpdateChapter any:@"(abs(persistentIdx - %lf) < 0.01) and (watch.manga ==[c] %@)", [chapterIdx floatValue], manga];

				return related;
			}
		} else {
			return ((AZDownload *)node).updateChapter;
		}

	return nil;
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
	return item.forManga.name;
}

- (id) groupNodeOf:(AZDownload *)item {
	return [NSString stringWithFormat:@"%06.1f",item.chapter];
}

- (id<NSCopying>) orderedUID:(AZDownload *)item {
	return @(trunc(item.chapter * 10) + (item.page / 10000.f));
}

@end

@implementation AZErgoDownloadsDataSource (AccessorsBehaviour)

- (CGFloat) groupCellHeight:(id)item {
	return 24.f;
}

- (CGFloat) cellHeight:(id)item {
	return 24.f;
}

@end
