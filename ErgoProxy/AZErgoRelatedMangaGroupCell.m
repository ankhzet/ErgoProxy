//
//  AZErgoRelatedMangaGroupCell.m
//  ErgoProxy
//
//  Created by Ankh on 20.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoRelatedMangaGroupCell.h"
#import "AZErgoMangaCommons.h"

@implementation AZErgoRelatedMangaGroupCell

- (void) configureForEntity:(NSNumber *)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	AZErgoTagGroup group = [[self plainTitle] integerValue];
	AZErgoMangaTag *tag = group ? [AZErgoMangaTag tagByGuid:@(group)] : nil;
	self.textField.stringValue = LOC_FORMAT(tag.tag ?: @"Common");
}

@end
