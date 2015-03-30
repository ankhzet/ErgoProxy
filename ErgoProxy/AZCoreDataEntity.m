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

- (instancetype) inContext:(NSManagedObjectContext *)context {
	return (id)[(id)((!context) ? [AZDataProxy sharedProxy] : context) objectWithID:self.objectID] ?: self;
}

- (void) delete {
	[[AZDataProxy sharedProxy] deleteObject:self];
}

+ (instancetype) any:(NSString *)filter,... {
	NSPredicate *predicate = nil;
	if (!!filter) {
		va_list args;
		va_start(args, filter);
		predicate = [NSPredicate predicateWithFormat:filter arguments:args];
		va_end(args);
	}
	return [self filter:predicate limit:1];
}

+ (instancetype) any {
	return [self filter:nil limit:1];
}

+ (NSArray *) all:(NSString *)filter,... {
	NSPredicate *predicate = nil;
	if (!!filter) {
		va_list args;
		va_start(args, filter);
		predicate = [NSPredicate predicateWithFormat:filter arguments:args];
		va_end(args);
	}

	return [self filter:predicate limit:0];
}

+ (NSArray *) all {
	return [self filter:nil limit:0];
}

+ (NSUInteger) countOf:(NSPredicate *)predicate {
	if (!predicate.isBlockPredicate) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[self entityDescription]];

		if (predicate)
			[fetchRequest setPredicate:predicate];

		return [[AZDataProxy sharedProxy] countForFetchRequest:fetchRequest error:nil];
	}

	return [[self filter:predicate limit:0] count];
}

+ (id) filter:(NSPredicate *)predicate limit:(NSUInteger)limit {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[self entityDescription]];

	BOOL blockPredicate = predicate.isBlockPredicate;

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
		else
			fetchedObjects = filtered;
	}

	return (limit == 1) ? [fetchedObjects lastObject] : fetchedObjects;
}

+ (instancetype) unique:(NSPredicate *)filter initWith:(void(^)(id entity))block {
	id instance = [self filter:filter limit:1];

	if (!instance) {
		instance = [self insertNew];
		if (block)
			block(instance);
	}

	return instance;
}

@end
