//
//  AZErgoUpdateWatchSubmitterWindowController.h
//  ErgoProxy
//
//  Created by Ankh on 28.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZSheetWindowController.h"

@class AZErgoUpdateWatch;

@interface AZErgoUpdateWatchSubmitterWindowController : AZSheetWindowController

@property (nonatomic) NSString *directory;
@property (nonatomic) NSString *identifier;

- (void) showWatchSubmitter:(AZErgoUpdateWatch *)watch;

@end
