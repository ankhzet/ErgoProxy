//
//  AZPopover.h
//  ErgoProxy
//
//  Created by Ankh on 06.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AZPopoverController.h"

@interface AZPopover : NSPopover

@property (nonatomic) id associatedData;
@property (nonatomic, weak) NSView *alignedTo;
@property (nonatomic) NSRectEdge preferredEdge;

+ (void) showAlignedTo:(NSView *)view withConfigurator:(AZPopoverConfigurator *)configurator;

@end

@interface AZPopover (ControllerRelated)

+ (NSString *) nibName;
+ (NSBundle *) bundle;

@end