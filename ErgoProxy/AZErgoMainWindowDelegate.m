//
//  AZErgoMainWindowDelegate.m
//  ErgoProxy
//
//  Created by Ankh on 22.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMainWindowDelegate.h"

@implementation AZErgoMainWindowDelegate

- (NSApplicationPresentationOptions) window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions {

	return proposedOptions | NSApplicationPresentationAutoHideToolbar;
}

@end
