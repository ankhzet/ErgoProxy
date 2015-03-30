//
//  AZErgoMangaStatePopoverController.m
//  ErgoProxy
//
//  Created by Ankh on 23.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaStatePopoverController.h"

@interface AZErgoMangaStatePopoverController ()

@end

@implementation AZErgoMangaStatePopoverController

+ (AZErgoMangaStatePopoverController *) sharedController {
	static AZErgoMangaStatePopoverController *controller;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		controller = [[self alloc] initWithNibName:@"MangaStatesPopover" bundle:nil];
		[controller view];
	});

	return controller;
}

@end
