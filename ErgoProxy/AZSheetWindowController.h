//
//  AZSheetWindowController.h
//  ErgoProxy
//
//  Created by Ankh on 28.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, AZDialogReturnCode) {
	AZDialogNoReturn = NSIntegerMin,
	AZDialogReturnCancel = 0,
	AZDialogReturnOk = 1,
	AZDialogReturnApply = 2,
};

@interface AZSheetWindowController : NSWindowController

@property BOOL hasChanges;

+ (instancetype) sharedController;

typedef AZDialogReturnCode (^AZDialogSetupBlock)(AZSheetWindowController *controller);
typedef AZDialogReturnCode (^AZDialogProcessBlock)(AZDialogReturnCode code, id controller);

- (AZDialogReturnCode) showWithSetup:(AZDialogSetupBlock)setup andFiltering:(AZDialogProcessBlock)filtering;
- (AZDialogReturnCode) beginSheet;
- (AZDialogReturnCode) beginSheetForWindow:(NSWindow *)window;

- (NSControl *) searchControl:(NSString *)identifier inContainingView:(NSView *)view;

@end

@interface AZSheetWindowController (Protected)

+ (NSString *) windowNib;
- (BOOL) applyChanges;
- (void) prepareWindow;

@end