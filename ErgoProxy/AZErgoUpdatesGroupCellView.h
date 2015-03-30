//
//  AZErgoUpdatesGroupCellView.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesCellView.h"

@interface AZErgoUpdatesGroupCellView : AZErgoUpdatesCellView

@property (weak) IBOutlet NSTextField *tfHeader;
@property (weak) IBOutlet NSProgressIndicator *piProgressIndicator;

@property (weak) IBOutlet NSView *vStatusBlock;
@property (weak) IBOutlet NSTextField *tfDownloaded;
@property (weak) IBOutlet NSImageView *ivDownloaded;
@property (weak) IBOutlet NSTextField *tfScheduled;
@property (weak) IBOutlet NSImageView *ivScheduled;
@property (weak) IBOutlet NSTextField *tfNew;
@property (weak) IBOutlet NSImageView *ivNew;

@property (weak) IBOutlet NSButton *bInfo;

@end
