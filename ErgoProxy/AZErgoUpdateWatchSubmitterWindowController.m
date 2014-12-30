//
//  AZErgoUpdateWatchSubmitterWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 28.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdateWatchSubmitterWindowController.h"

#import "AZErgoUpdatesCommons.h"

@interface AZErgoUpdateWatchSubmitterWindowController ()

@property (weak) IBOutlet NSComboBox *cbDirectoriesList;
@property (weak) IBOutlet NSTextField *tfIdentifier;

@end

@implementation AZErgoUpdateWatchSubmitterWindowController

- (NSString *) directory {
	return self.cbDirectoriesList.stringValue;
}

- (NSString *) identifier {
	return self.tfIdentifier.stringValue;
}

- (void) setDirectory:(NSString *)directory {
	self.cbDirectoriesList.stringValue = directory ?: @"";
}

- (void) setIdentifier:(NSString *)identifier {
	self.tfIdentifier.stringValue = identifier ?: @"";
}

- (id)initWithWindow:(NSWindow *)window {
	if (!(self = [super initWithWindow:window]))
		return self;

	return self;
}

- (void) prepareWindow {
	[super prepareWindow];
	[self actionRefreshList:nil];
}

- (void) showWatchSubmitter {
	switch ([self beginSheet]) {
		case AZDialogReturnOk:
			break;

		default:
			break;
	}
}

- (IBAction)actionRefreshList:(id)sender {
	NSArray *dirs = [AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)];

	[self.cbDirectoriesList removeAllItems];
	[self.cbDirectoriesList addItemsWithObjectValues:dirs];
	[self.cbDirectoriesList setCompletes:YES];
}

@end