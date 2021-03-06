//
//  AZErgoDownloadDetailsPopover.h
//  ErgoProxy
//
//  Created by Ankh on 04.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AZDownload;
@interface AZErgoDownloadDetailsPopover : NSPopover <NSPopoverDelegate>

@property (weak) IBOutlet NSButton *bPreview;
@property (weak) IBOutlet NSButton *bPreviewTrash;
@property (weak) IBOutlet NSButton *bLock;

@property (weak) IBOutlet NSTextField *tfStorage;
@property (weak) IBOutlet NSTextField *tfScanID;

@property (weak) IBOutlet NSTextField *tfTitle;
@property (weak) IBOutlet NSTextField *tfURL;
@property (weak) IBOutlet NSTextField *tfWidth;
@property (weak) IBOutlet NSTextField *tfHeight;
@property (weak) IBOutlet NSTextField *tfQuality;
@property (weak) IBOutlet NSTextField *tfIsWebtoon;
@property (weak) IBOutlet NSTextField *tfHash;
@property (weak) IBOutlet NSTextField *tfError;

- (void) showDetailsFor:(id)entity alignedTo:(NSView *)view;

@end
