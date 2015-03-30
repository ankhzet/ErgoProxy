//
//  AZErgoTagCellView.h
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZConfigurableTableCellView.h"

@interface AZErgoTagCellView : AZConfigurableTableCellView

@property (weak) IBOutlet NSTextField *tfTagName;
@property (weak) IBOutlet NSTextField *tfRelatedCount;

@end
