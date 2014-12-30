//
//  AZErgoConfigurableTableCellView.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AZErgoConfigurableTableCellView : NSTableCellView

@property (nonatomic, weak) id bindedEntity;

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view;

@end
