//
//  AZErgoUpdatesDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesDataSource.h"

#import "AZErgoUpdatesDataSource.h"
#import "AZErgoUpdatesSourceDescription.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdateChapter.h"

#import "AZErgoUpdatesGroupCellView.h"

@implementation AZErgoUpdatesDataSource

- (CGFloat) cellHeight:(id)item {
	return 24.0;
}

- (CGFloat) groupCellHeight:(id)item {
	return 24.0;
}

- (NSString *) rootIdentifierFromItem:(id)item {
	return ((AZErgoUpdatesSourceDescription *)[self rootNodeOf:item]).serverURL;
}

- (NSString *) groupIdentifierFromItem:(id)item {
	return ((AZErgoUpdateWatch *)[self groupNodeOf:item]).manga;
}

- (id) rootNodeOf:(AZErgoUpdateChapter *)item {
	return item.watch.source;
}

- (id) groupNodeOf:(AZErgoUpdateChapter *)item {
	return item.watch;
}

- (id<NSCopying>) orderedUID:(AZErgoUpdateChapter *)item {
	return @(item.volume * 10000 + item.idx);
}

- (NSArray *) sort:(CustomDictionary *)group keys:(NSArray *)keys {
	return [keys sortedArrayUsingSelector:@selector(compare:)];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return self.expanded ? [CustomDictionary isDictionary:item] : [GroupsDictionary isDictionary:item];
}

@end
