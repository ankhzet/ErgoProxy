//
//  AZErgoDownloadDetailsPopover.h
//  ErgoProxy
//
//  Created by Ankh on 04.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AZDownload;
@interface AZErgoDownloadDetailsPopover : NSPopover

@property (weak) IBOutlet NSTextField *tfTitle;
@property (weak) IBOutlet NSTextField *tfURL;
@property (weak) IBOutlet NSTextField *tfWidth;
@property (weak) IBOutlet NSTextField *tfHeight;
@property (weak) IBOutlet NSTextField *tfQuality;
@property (weak) IBOutlet NSTextField *tfIsWebtoon;
@property (weak) IBOutlet NSTextField *tfHash;
@property (weak) IBOutlet NSTextField *tfError;

- (void) showDetailsFor:(AZDownload *)download alignedTo:(NSView *)view;

@end
