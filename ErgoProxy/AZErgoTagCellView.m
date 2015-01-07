//
//  AZErgoTagCellView.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoTagCellView.h"
#import "AZErgoMangaCommons.h"

@implementation AZErgoTagCellView

- (void) configureForEntity:(AZErgoMangaTag *)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	self.tfTagName.stringValue = entity.tag ?: @"<tag name unknown>";
	self.tfRelatedCount.stringValue = [@([[entity manga] count]) stringValue];
}

@end
