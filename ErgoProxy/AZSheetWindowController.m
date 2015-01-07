//
//  AZSheetWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 28.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZSheetWindowController.h"

@interface AZSheetWindowController () {
	AZDialogProcessBlock processBlock;
}

@end

@implementation AZSheetWindowController

- (id)initWithWindow:(NSWindow *)window {
	if (!(self = [super initWithWindow:window]))
		return self;

	processBlock = [self makeProcessor:nil];

	return self;
}

- (AZDialogProcessBlock) makeProcessor:(AZDialogProcessBlock)filter {
	return ^(AZDialogReturnCode code, AZSheetWindowController *controller) {

		switch (code) {
			case AZDialogReturnApply:
			case AZDialogReturnOk:
				controller.hasChanges = ![controller applyChanges];
				break;

			default:
				break;
		}

		switch (filter ? (code = filter(code, controller)) : code) {
			case AZDialogNoReturn:
				break;

			case AZDialogReturnApply:
				break;

			case AZDialogReturnOk:
				if (self.hasChanges)
					break;
			default:
				[controller dismissWithReturnCode:code];
		}

		return code;
	};
}

- (AZDialogReturnCode) showWithSetup:(AZDialogSetupBlock)setup andFiltering:(AZDialogProcessBlock)filtering {
	AZDialogReturnCode code = AZDialogReturnCancel;

	AZDialogProcessBlock old = processBlock;
	@try {
		processBlock = [self makeProcessor:filtering];
		code = ABS(setup ? setup(self) : [self beginSheet]);
	}
	@finally {
    processBlock = old;
	}

	return code;
}

+ (NSString *) windowNibName {
	return NSStringFromClass(self);
}

+ (instancetype) sharedController {
	static NSMutableDictionary *controllers;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (!controllers)
			controllers = [NSMutableDictionary dictionary];
	});

	@synchronized(controllers) {
		NSString *nibName = [self windowNibName];

		AZSheetWindowController *instance = controllers[nibName];

		if (!instance)
	    instance = controllers[nibName] = [[self alloc] initWithWindowNibName:nibName];

		return instance;
	}
}

- (void) prepareWindow {
	[self window];
}

- (BOOL) applyChanges {
	return NO;
}

- (AZDialogReturnCode) beginSheet {
	NSWindow *key = [[NSApplication sharedApplication] keyWindow];

	return [self beginSheetForWindow:key];
}

- (AZDialogReturnCode) beginSheetForWindow:(NSWindow *)window {
	[self prepareWindow];
	self.hasChanges = YES;

	[[NSApplication sharedApplication] beginSheet:self.window
																 modalForWindow:window
																	modalDelegate:self
																 didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
																		contextInfo:nil];

	return [NSApp runModalForWindow:self.window];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
}

- (void) dismissWithReturnCode:(NSInteger)returnCode {
	[NSApp endSheet:self.window returnCode:returnCode];
	[NSApp stopModalWithCode:returnCode];
}

- (NSControl *) searchControl:(NSString *)identifier inContainingView:(NSView *)view {
	for (NSControl *control in [view subviews])
		if ([control isKindOfClass:[NSControl class]] && [control.identifier isEqualToString:identifier])
			return control;
	
	return nil;
}

- (IBAction)actionOk:(id)sender {
	processBlock(AZDialogReturnOk, self);
}

- (IBAction)actionCancel:(id)sender {
	processBlock(AZDialogReturnCancel, self);
}

- (IBAction)actionApply:(id)sender {
	processBlock(AZDialogReturnApply, self);
}

@end
