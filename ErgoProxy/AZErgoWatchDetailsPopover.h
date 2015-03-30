//
//  AZErgoWatchDetailsPopover.h
//  ErgoProxy
//
//  Created by Ankh on 05.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AZErgoUpdateWatch;
@interface AZErgoWatchDetailsPopover : NSPopover

- (void) showDetailsOf:(AZErgoUpdateWatch *)watch alignedTo:(NSView *)view;

@end
