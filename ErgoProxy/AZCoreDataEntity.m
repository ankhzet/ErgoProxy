//
//  AZCoreDataEntity.m
//  AnkhZet
//
//  Created by Ankh on 23.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"
#import "AZDataProxy.h"

@implementation AZCoreDataEntity

+ (NSString *) CDEntityName {
	return [NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"AZ" withString:@""];
}

+ (NSEntityDescription *) entityDescription {
	NSString *entityName = [self CDEntityName];
	return [[AZDataProxy sharedProxy] entityForName:entityName];
}

+ (instancetype) insertNew {
	return [[AZDataProxy sharedProxy] insertNewObjectForEntityForName:[self CDEntityName]];
}

- (void) delete {
	[[AZDataProxy sharedProxy] deleteObject:self];
}

+ (NSArray *) all {
	return [self filter:nil limit:0];
}

+ (id) filter:(NSPredicate *)predicate limit:(NSUInteger)limit {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[self entityDescription]];

	BOOL blockPredicate = [[predicate predicateFormat] hasPrefix:@"BLOCK"];

	if (!blockPredicate) {
		if (predicate)
			[fetchRequest setPredicate:predicate];

		if (limit)
			[fetchRequest setFetchLimit:limit];
	}

	NSError *error = nil;
	NSArray *fetchedObjects = [[AZDataProxy sharedProxy] executeFetchRequest:fetchRequest error:&error];

	if (blockPredicate) {
		__block NSArray *filtered = nil;
		[[AZDataProxy sharedProxy] performOnFetchThread:^{
			filtered = [fetchedObjects filteredArrayUsingPredicate:predicate];
		}];

		if (limit && ([filtered count] > limit))
			fetchedObjects = [filtered subarrayWithRange:NSMakeRange(0, limit)];
	}

	return (limit == 1) ? [fetchedObjects lastObject] : fetchedObjects;
}

+ (instancetype) unique:(NSPredicate *)filter initWith:(void(^)(id entity))block {
	id instance = [self filter:filter limit:1];

	if (!instance) {
		instance = [self insertNew];
		block(instance);
	}

	return instance;
}

@end
