//
//  AZErgoChapterStateDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 06.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChapterStateDataSource.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"

@implementation AZErgoChapterStateDataSource

- (CGFloat) cellHeight:(id)item {
	return 24.0;
}

- (CGFloat) groupCellHeight:(id)item {
	return 24.0;
}

- (NSString *) rootIdentifierFromItem:(id)item {
	return ((AZErgoManga *)[self rootNodeOf:item]).name;
}

- (NSString *) groupIdentifierFromItem:(id)item {
	return [self groupNodeOf:item];
}

- (id) rootNodeOf:(id<AZErgoChapterProtocol>)item {
	return [AZErgoManga mangaByName:item.mangaName];
}

- (id) groupNodeOf:(id<AZErgoChapterProtocol>)item {
	return [NSString stringWithFormat:@"Volume %03lu", item.volume];
}

- (id<NSCopying>) orderedUID:(id<AZErgoChapterProtocol>)item {
	return @(item.idx);
}

@end
