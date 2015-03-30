//
//  AZErgoDownloadGroupCellView.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZConfigurableTableCellView.h"

@interface AZErgoDownloadGroupCellView : AZConfigurableTableCellView

@property (weak) IBOutlet NSTextField *tfGroupTitle;
@property (weak) IBOutlet NSTextField *tfDownloadsCount;

@end
