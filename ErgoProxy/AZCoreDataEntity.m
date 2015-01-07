//
//  AZCoreDataEntity.m
//  AnkhZet
//
//  Created by Ankh on 23.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZCoreDataEntity.h"
#import "AZDataProxyContainer.h"

@implementation AZCoreDataEntity

+ (NSString *) CDEntityName {
	return [NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"AZ" withString:@""];
}

+ (NSEntityDescription *) entityDescription {
	NSManagedObjectContext *context = [[AZDataProxyContainer getInstance] managedObjectContext];
	NSString *entityName = [self CDEntityName];
	return [NSEntityDescription entityForName:entityName
										 inManagedObjectContext:context];
}

+ (instancetype) insertNew {
	return [NSEntityDescription insertNewObjectForEntityForName:[self CDEntityName]
																			 inManagedObjectContext:[[AZDataProxyContainer getInstance] managedObjectContext]];
}

- (void) delete {
	NSManagedObjectContext *context = [[AZDataProxyContainer getInstance] managedObjectContext];
	[context deleteObject:self];
}

+ (NSArray *) all {
	return [self filter:nil limit:0];
}

+ (id) filter:(NSPredicate *)predicate limit:(NSUInteger)limit {
	NSManagedObjectContext *context = [[AZDataProxyContainer getInstance] managedObjectContext];
//	if ([context hasChanges])
//		[context save:nil];

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[self entityDescription]];

	BOOL blockPredicate = [[predicate predicateFormat] hasPrefix:@"BLOCK"];

	if (!blockPredicate) {
		if (predicate)
			[fetchRequest setPredicate:predicate];

		if (limit)
			[fetchRequest setFetchLimit:limit];
	}

	__block NSArray *fetchedObjects = nil;
	dispatch_queue_t current = dispatch_get_current_queue();
	dispatch_queue_t operate = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	if (operate == current) {
		NSError *_error = nil;
		fetchedObjects = [context executeFetchRequest:fetchRequest error:&_error];
	} else
		dispatch_sync(operate, ^{
			NSError *_error = nil;
			fetchedObjects = [context executeFetchRequest:fetchRequest error:&_error];
		});

	if (blockPredicate) {
		fetchedObjects = [fetchedObjects filteredArrayUsingPredicate:predicate];
		if (limit && ([fetchedObjects count] > limit))
			fetchedObjects = [fetchedObjects subarrayWithRange:NSMakeRange(0, limit)];
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
