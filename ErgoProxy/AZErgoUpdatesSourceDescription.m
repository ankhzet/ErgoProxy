//
//  AZErgoUpdatesSourceDescription.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesSourceDescription.h"

@implementation AZErgoUpdatesSourceDescription
@dynamic serverURL, watches;

- (NSComparisonResult) compare:(AZErgoUpdatesSourceDescription *)another {
	return [self.serverURL compare:another.serverURL];
}

- (NSString *) description {
	return [self serverURL];
}

@end
