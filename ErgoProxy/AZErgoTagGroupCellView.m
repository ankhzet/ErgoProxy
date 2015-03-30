//
//  AZErgoTagGroupCellView.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoTagGroupCellView.h"
#import "AZErgoMangaCommons.h"

@implementation AZErgoTagGroupCellView

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	self.textField.stringValue = LOC_FORMAT([self plainTitle] ?: @"Unknown tag group");
}

@end
