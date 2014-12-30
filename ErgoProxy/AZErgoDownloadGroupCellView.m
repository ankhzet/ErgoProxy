//
//  AZErgoDownloadGroupCellView.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadsDataSource.h"
#import "AZErgoDownloadGroupCellView.h"

#import "AZErgoUpdatesCommons.h"

@implementation AZErgoDownloadGroupCellView

- (NSString *) plainTitle {
	KeyedHolder *holder = ((CustomDictionary *)self.bindedEntity)->owner;
	return [holder->holdedObject capitalizedString];
}

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	NSString *title = nil;
			title = [self plainTitle];
	self.tfGroupTitle.stringValue = title ?: @"<cant aquire title!>";
}

@end
