//
//  AZErgoDownloadPrefsWindowController.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AZDownloadParams;
@interface AZErgoDownloadPrefsWindowController : NSWindowController

- (AZDownloadParams *) aquireParams:(BOOL)useDefaults;

@end
