//
//  AZErgoTagsDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoTagsDataSource.h"
#import "AZErgoTagCellView.h"
#import "AZErgoTagGroupCellView.h"

@implementation AZErgoTagsDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)idItem {
	if (!!self.delegate)
		[self.delegate tagSelected:idItem];

	return YES;
}

- (void) actionDelegatedClick:(id)sender {
	AZErgoTagCellView *cellView = [self cellViewFromSender:sender];
	if (cellView && !!self.delegate)
		[self.delegate tagDeleted:cellView.bindedEntity];
}

@end

@implementation AZErgoTagsDataSource (GroupableDataSource)

- (NSString *) rootIdentifierFromItem:(id)item {
	return [self rootNodeOf:item];
}

- (NSString *) groupIdentifierFromItem:(id)item {
	return [self groupNodeOf:item];
}

- (id) rootNodeOf:(AZErgoMangaTag *)tag {
	return tag.guid ?: @0;
}

- (id) groupNodeOf:(AZErgoMangaTag *)tag {
	return tag.tag;
}

- (id<NSCopying>) orderedUID:(AZErgoMangaTag *)tag {
	return tag.tag;
}

@end
