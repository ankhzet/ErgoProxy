//
//  KeyedHolder.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "KeyedHolder.h"

@implementation KeyedHolder
+ (instancetype) holderFor:(id)object {
	KeyedHolder *holder = [self new];
	holder->holdedObject = object;
	return holder;
}
- (id) copyWithZone:(NSZone *)zone {
	return self;
}
+ (BOOL) isA:(id)object {
	return [object isKindOfClass:self];
}
- (NSComparisonResult) caseInsensitiveCompare:(id)another {
	return [holdedObject caseInsensitiveCompare:((KeyedHolder *)another)->holdedObject];
}
- (NSComparisonResult) compare:(id)another {
	return [holdedObject compare:((KeyedHolder *)another)->holdedObject];
}
@end
