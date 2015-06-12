//
//  AZPopover.m
//  ErgoProxy
//
//  Created by Ankh on 06.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZPopover.h"
#import "AZPopoverController.h"

@implementation AZPopover (ControllerRelated)

+ (AZPopoverController *) sharedController {
	static NSMutableDictionary *controllers;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (!controllers)
			controllers = [NSMutableDictionary new];

	});

	@synchronized(controllers) {
		NSString *className = NSStringFromClass(self);
		AZPopoverController *controller = controllers[className];
		if (!controller) {
			controller = controllers[className] = [[AZPopoverController alloc] initWithNibName:[self nibName] bundle:[self bundle]];
			[controller view];
		}

		return controller;
	}
}

+ (NSString *) nibName {
	return nil;
}

+ (NSBundle *) bundle {
	return nil;
}

@end

@implementation AZPopover
@synthesize alignedTo = _alignedTo, preferredEdge = preferredEdge;

+ (void) showAlignedTo:(NSView *)view withConfigurator:(AZPopoverConfigurator *)configurator {
	AZPopoverController *controller = [self sharedController];
	[configurator preparePopover:controller.popover];

	if (controller.popover.isShown) {

	} else
		controller.popover.alignedTo = view;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (!(self = [super initWithCoder:aDecoder]))
		return self;

	self.behavior = NSPopoverBehaviorTransient;
	self.preferredEdge = NSMaxYEdge;
	return self;
}

- (void) setAlignedTo:(NSView *)alignedTo {
	_alignedTo = alignedTo;

	if (alignedTo)
		[self showRelativeToRect:alignedTo.bounds ofView:alignedTo preferredEdge:self.preferredEdge];
}

@end
