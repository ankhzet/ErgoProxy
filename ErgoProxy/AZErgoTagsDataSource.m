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

- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
	[(id)self.md_delegate tagSelected:nil];

		[proposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			id item = [outlineView itemAtRow:idx];
			[(id)self.md_delegate tagSelected:item];
		}];

	return proposedSelectionIndexes;
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
	return [AZErgoMangaTag tagGroupName:[tag.guid integerValue]];
}

- (id) groupNodeOf:(AZErgoMangaTag *)tag {
	return tag.tag;
}

- (id<NSCopying>) orderedUID:(AZErgoMangaTag *)tag {
	return tag.tag;
}

@end
