//
//  AZAlertSheet.h
//  ErgoProxy
//
//  Created by Ankh on 10.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZSheetWindowController.h"

#define AZAlert [AZAlertSheet sharedController]
#define AZWarningTitle NSLocalizedString(@"Warning", @"Alert warning title")
#define AZInfoTitle NSLocalizedString(@"Info", @"Alert info title")
#define AZErrorTitle NSLocalizedString(@"Error", @"Alert error title")
#define AZChoiceTitle NSLocalizedString(@"Pick action", @"Alert choice title")

@interface AZAlertSheet : AZSheetWindowController

- (AZDialogReturnCode) showAlert:(NSString *)title message:(NSString *)message;
- (AZDialogReturnCode) showOkCancel:(NSString *)title message:(NSString *)message;
- (AZDialogReturnCode) showYesNoCancel:(NSString *)title message:(NSString *)message;

- (AZDialogReturnCode) showAlert:(NSString *)title message:(NSString *)message withButtons:(NSArray *)buttons;

@end
