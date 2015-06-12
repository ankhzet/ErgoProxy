//
//  AZPopoverController.h
//  ErgoProxy
//
//  Created by Ankh on 06.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AZPopover;
@interface AZPopoverConfigurator : NSObject

@property (nonatomic) id associatedData;

+ (instancetype) with:(id)associatedData;
- (void) preparePopover:(AZPopover *)popover;
@end

@interface AZPopoverController : NSViewController
@property (weak) IBOutlet AZPopover *popover;

@end
