//
//  AZPopoverController.m
//  ErgoProxy
//
//  Created by Ankh on 06.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZPopoverController.h"
#import "AZPopover.h"

@implementation AZPopoverController


@end

@implementation AZPopoverConfigurator

+ (instancetype) with:(id)associatedData {
	AZPopoverConfigurator *instance = [self new];
	instance.associatedData = associatedData;
	return instance;
}

- (void) preparePopover:(AZPopover *)popover {
	popover.associatedData = self.associatedData;
}

@end

