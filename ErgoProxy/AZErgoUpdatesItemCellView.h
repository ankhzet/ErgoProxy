//
//  AZErgoUpdateItemView.h
//  ErgoProxy
//
//  Created by Ankh on 25.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesCellView.h"

@interface AZErgoUpdatesItemCellView : AZErgoUpdatesCellView

@property (weak) IBOutlet NSImageView *ivStatus;
@property (weak) IBOutlet NSTextField *tfTitle;
@property (weak) IBOutlet NSTextField *tfDate;
@property (weak) IBOutlet NSButton *bListScans;

@end
