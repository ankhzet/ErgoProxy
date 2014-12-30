//
//  AZErgoWatchTab.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoWatchTab.h"

@interface AZErgoWatchTab () 
@property (nonatomic) AZErgoUpdatesDataSource *updates;

@end

@implementation AZErgoWatchTab
@synthesize updates = _updates;

- (id)init {
	if (!(self = [super init]))
		return self;
}

- (NSString *) tabIdentifier {
	return AZEPUIDWatchTab;
}

@end
