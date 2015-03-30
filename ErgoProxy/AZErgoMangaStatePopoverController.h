//
//  AZErgoMangaStatePopoverController.h
//  ErgoProxy
//
//  Created by Ankh on 23.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AZErgoWatchDetailsPopover.h"

@interface AZErgoMangaStatePopoverController : NSViewController

@property (strong) IBOutlet AZErgoWatchDetailsPopover *popover;

+ (AZErgoMangaStatePopoverController *) sharedController;

@end
