//
//  AZAlertSheet.m
//  ErgoProxy
//
//  Created by Ankh on 10.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZAlertSheet.h"
#import "AZCollapsingView.h"

@interface AZAlertSheet ()

@property (weak) IBOutlet NSTextField *tfAlertText;
@property (weak) IBOutlet NSTextField *tfAlertTitle;

@property (weak) IBOutlet NSButton *bThirdButton;
@property (weak) IBOutlet NSButton *bSecondButton;
@property (weak) IBOutlet NSButton *bFirstButton;
@end

@implementation AZAlertSheet

- (AZDialogReturnCode) showAlert:(NSString *)title message:(NSString *)message {
	return [self showAlert:title
								 message:message
						 withButtons:nil];
}

- (AZDialogReturnCode) showOkCancel:(NSString *)title message:(NSString *)message {
	return [self showAlert:title
								 message:message
						 withButtons:@[
													 NSLocalizedString(@"Ok", @"Ok alert button text"),
													 @"",
													 NSLocalizedString(@"Cancel", @"Cancel alert button text"),
													 ]];
}

- (AZDialogReturnCode) showYesNoCancel:(NSString *)title message:(NSString *)message {
	return [self showAlert:title
								 message:message
						 withButtons:@[
													 NSLocalizedString(@"Yes", @"Yes alert button text"),
													 NSLocalizedString(@"No", @"No alert button text"),
													 NSLocalizedString(@"Cancel", @"Cancel alert button text"),
													 ]];
}


- (AZDialogReturnCode) showAlert:(NSString *)title message:(NSString *)message withButtons:(NSArray *)buttons {
	return [self showWithSetup:^AZDialogReturnCode(AZSheetWindowController *controller) {
		NSMutableArray *b = [@[self.bFirstButton, self.bSecondButton, self.bThirdButton] mutableCopy];
		NSArray *toAdd = (![buttons count]) ? @[NSLocalizedString(@"Ok", @"Ok alert button text")] : buttons;

		for (NSButton *button in b)
			[button setCollapsed:YES];

		for (NSString *buttonLabel in toAdd) {
			NSButton *button = [b firstObject];
			[b removeObject:button];

			if ([buttonLabel length]) {
				[button setTitle:buttonLabel];
				[button setCollapsed:NO];
			}
		}

		self.tfAlertTitle.stringValue = title ?: NSLocalizedString(@"Alert", nil);
		self.tfAlertText.stringValue = message ?: NSLocalizedString(@"Alert", nil);

		return [self beginSheet];

	} andFiltering:^AZDialogReturnCode(AZDialogReturnCode code, id controller) {
		self.hasChanges = NO;

		switch (code) {
			case AZDialogNoReturn:
				break;
			case AZDialogReturnApply:
				return -AZDialogReturnApply;
				break;
			default:
				break;
		}

		return code;
	}];
}

@end
