//
//  CustomDictionary.m
//  ErgoProxy
//
//  Created by Ankh on 12.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "CustomDictionary.h"

@implementation CustomDictionary

+ (instancetype) custom:(id)owner {
	CustomDictionary *dictionary = [self new];
	dictionary->owner = owner;
	return dictionary;
}

- (id)init {
	if (!(self = [super init]))
		return self;

	dictionary = [NSMutableDictionary dictionary];
	return self;
}
- (void) setObject:(id)object forKeyedSubscript:(id<NSCopying>)key {
	dictionary[key] = object;
}
- (id) objectForKeyedSubscript:(id)key {
	return dictionary[key];
}
- (NSUInteger) count {
	return [dictionary count];
}
- (NSArray *) allKeys {
	return [dictionary allKeys];
}
- (NSArray *) allValues {
	return [dictionary allValues];
}

+ (BOOL) isDictionary:(id)object {
	return [object isKindOfClass:self];
}

@end
