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

	NSString *title = [self plainTitle];
	switch ([title integerValue]) {
		case AZErgoTagGroupComplete:
			title = @"Tagged as complete";
			break;

		case AZErgoTagGroupReaded:
			title = @"Tagged as readed";
			break;

		case AZErgoTagGroupAdult:
			title = @"Tagged as adult (18+)";
			break;

		default:
			title = @"Common tags";
			break;
	}

	self.textField.stringValue = title;
}

@end
