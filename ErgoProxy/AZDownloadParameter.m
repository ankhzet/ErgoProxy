//
//  AZDownloadParameter.m
//  ErgoProxy
//
//  Created by Ankh on 23.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZDownloadParameter.h"
#import "AZDownloadParams.h"


@implementation AZDownloadParameter

@dynamic name;
@dynamic value;
@dynamic ownedBy;


+ (instancetype) param:(NSString *)paramName withValue:(NSDecimalNumber *)value {
	AZDownloadParameter *instance = [self insertNew];
	instance.name = paramName;
	instance.value = value;
	return instance;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@: %@", self.name, self.value ? self.value : @"<no value>"];
}

@end
