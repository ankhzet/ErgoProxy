//
//  AZAppDelegate.m
//  ErgoProxy
//
//  Created by Ankh on 27.03.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZAppDelegate.h"

#import "AZTabsCommons.h"

#import "DDTTYLogger.h"

static BOOL isRunningTests(void) __attribute__((const));

@interface AZAppDelegate () <AZTabsGroupDelegate> {
	AZTabsGroup *_tabsGroup;
}

@property (weak) IBOutlet NSToolbar *tbToolBar;
@property (weak) IBOutlet NSTabView *tvTabView;
@end

@implementation AZAppDelegate
@synthesize tabsGroup = _tabsGroup;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if (isRunningTests())
		return;

	[DDLog addLogger:[DDTTYLogger sharedInstance]];

	_tabsGroup = [[AZTabsGroup alloc] initWithTabView:self.tvTabView];
	_tabsGroup.delegate = self;

	[self registerTabs];

	NSString *initialTab = [self initialTab];
	if (initialTab)
		[_tabsGroup navigateTo:initialTab withNavData:nil];
}

- (void) registerTabs {

}

- (NSString *) initialTab {
	return nil;
}

- (AZTabProvider *) registerTab:(Class)tabProviderClass {
	return [_tabsGroup registerTab:tabProviderClass];
}

- (void) navigateTo:(NSString *)tabIdentifier {
	
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemWithIdentifier:(NSString *)identifier {
	NSArray *items = [toolbar items];
	for (NSToolbarItem *i in items)
		if ([[i itemIdentifier] isEqualToString:identifier])
			return i;

	return nil;
}

- (BOOL) tabGroup:(AZTabsGroup *)tabGroup navigateTo:(AZTabProvider *)tab {
	NSToolbarItem *navTo = [self toolbar:self.tbToolBar itemWithIdentifier:[tab tabIdentifier]];
	if (navTo)
		[navTo setEnabled:NO];

	return YES;
}

- (void) tabGroup:(AZTabsGroup *)tabGroup navigatedTo:(AZTabProvider *)tab {
	NSToolbarItem *navTo = [self toolbar:self.tbToolBar itemWithIdentifier:[tab tabIdentifier]];
	if (navTo)
		[navTo setEnabled:YES];

	[self.tbToolBar setSelectedItemIdentifier:[tab tabIdentifier]];
}

- (NSToolbar *)tabGroupAssociatedToolbar:(AZTabsGroup *)tabGroup {
	return self.tbToolBar;
}

- (IBAction)actionToolbarNavigate:(id)sender {
	NSString *uid = ((NSToolbarItem *)sender).itemIdentifier;
	[_tabsGroup navigateTo:uid withNavData:nil];
}

@end

static BOOL isRunningTests(void) {
	NSDictionary* environment = [[NSProcessInfo processInfo] environment];
	NSString* injectBundle = environment[@"XCInjectBundle"];
	return [[injectBundle pathExtension] isEqualToString:@"xctest"];
}