//
//  AZAppDelegate.h
//  ErgoProxy
//
//  Created by Ankh on 27.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AZTabsGroup, AZTabProvider;
@interface AZAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic) AZTabsGroup *tabsGroup;


- (void) registerTabs;
- (NSString *) initialTab;
- (AZTabProvider *) registerTab:(Class)tabProviderClass;

@end
