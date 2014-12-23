//
//  AZErgoGroupCellView.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoGroupCellView.h"
#import "KeyedHolder.h"
#import "CustomDictionary.h"
#import "AZErgoDownloadsDataSource.h"

@implementation AZErgoGroupCellView

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	KeyedHolder *holder = ((CustomDictionary *)entity)->owner;

	self.tfGroupTitle.stringValue = [holder->holdedObject capitalizedString];

	AZErgoDownloadedAmount amount = [(AZErgoDownloadsDataSource *)view.dataSource downloaded:entity];
	self.tfDownloadsCount.stringValue = [NSString stringWithFormat:@"%@/%@", [NSString cvtFileSize:amount.downloaded], [NSString cvtFileSize:amount.total]];
}

@end
