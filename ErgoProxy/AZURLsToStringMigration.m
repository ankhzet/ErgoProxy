//
//  AZURLsToStringMigration.m
//  ErgoProxy
//
//  Created by Ankh on 30.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZURLsToStringMigration.h"

#import "AZDownload.h"
#import "AZProxyServer.h"
#import "AZProxifier.h"
#import "AZStorage.h"

@implementation AZURLsToStringMigration

- (id) copyEntity:(NSManagedObject *)source toEntity:(NSManagedObject *)destination withMapping:(id(^)(NSString *key, id value, NSManagedObject *dst))block {
	for (NSString *key in [[source entity] attributeKeys]) {
		id value = [source valueForKey:key];

		value = block(key, value, destination);

		[destination setValue:value forKey:key];
	}

	return destination;
}


- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{

	NSManagedObject *newObject = [NSEntityDescription insertNewObjectForEntityForName:[mapping destinationEntityName] inManagedObjectContext:[manager destinationContext]];

	NSString *class = sInstance.entity.name;

	id (^mapper) (NSString *key, id value, NSManagedObject *dst) = nil;

	if ([class isEqualToString:@"Download"])
		mapper = ^id(NSString *key, id value, NSManagedObject *dst) {
			BOOL handled = [key isEqualToString:@"fileURL"] || [key isEqualToString:@"sourceURL"];
			if (handled) {
				AZ_IFCLASS(value, NSURL, *url, {
					value = [url absoluteString];
				});
			}

			return value;
		};

	else if ([@[@"Proxifier", @"Storage"] containsObject:class])
		mapper = ^id(NSString *key, id value, NSManagedObject *dst) {
			BOOL handled = [key isEqualToString:@"url"];
			if (handled) {
				AZ_IFCLASS(value, NSURL, *url, {
					value = [url absoluteString];
				});
			}

			return value;
		};

	else if ([class isEqualToString:@"ErgoMangaProgress"])
		mapper = ^id(NSString *key, id value, NSManagedObject *dst) {
			BOOL handled = [key isEqualToString:@"updated"];
			if (handled) {
				if ([value isKindOfClass:[NSNumber class]])
					value = nil;
			}

			return value;
		};

	[self copyEntity:sInstance toEntity:newObject withMapping:mapper];


	[manager associateSourceInstance:sInstance withDestinationInstance:newObject forEntityMapping:mapping];

	return YES;
}

@end
