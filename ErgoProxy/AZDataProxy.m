//
//  AZDataProxy.m
//  AnkhZet
//
//  Created by Ankh on 08.01.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZDataProxy.h"
#import "AZUtils.h"

NSString *const kDPParameterModelName = @"kDPParameterModelName";
NSString *const kDPParameterStorageFile = @"kDPParameterStorageFile";
NSString *const kDPParameterSyncDirectory = @"kDPParameterSyncDirectory";

// notification, that will be send on iCloud data update
NSString *const changeNotificationName = @"CoreDataChangeNotification";


@implementation AZDataProxy

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


-(id) init {
	if (!(self = [super init]))
		return nil;

	self.coredataModel = @"AnkhZet";
	self.localDataDirectory = @"Documents";
	self.dataStorageFileName = @"Database.sqlite";
	
	return self;
}

+ (instancetype) storageWithParameters:(NSDictionary *)appParameters {
	return [[self alloc] initWithParameters:appParameters];
}

- (id)initWithParameters:(NSDictionary *)appParameters {
	if (!(self = [self init]))
		return nil;

	if (appParameters[kDPParameterModelName])
		self.coredataModel = appParameters[kDPParameterModelName];

	if (appParameters[kDPParameterStorageFile])
		self.dataStorageFileName = appParameters[kDPParameterStorageFile];

	if (appParameters[kDPParameterSyncDirectory])
		self.localDataDirectory = appParameters[kDPParameterSyncDirectory];

	return self;
}

// path for local data storage (e.g. photos)
-(NSURL *) localDataDirURL {
	return [[AZUtils applicationDocumentsDirectory] URLByAppendingPathComponent:self.localDataDirectory];
}

#pragma mark - Core Data stack

// url of local coredata file
-(NSURL *) localStorageFileURL {
	return [[AZUtils applicationDocumentsDirectory] URLByAppendingPathComponent:self.dataStorageFileName];
}

// save CoreData-managed data
-(BOOL)saveContext {
	NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
	if (managedObjectContext != nil) {
		@try {
			if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				return NO;
			}
		}
		@catch (NSException *exception) {
			NSLog(@"CoreData error: %@", exception);
		}
		@finally {
		}
	}
	
	return YES;
}

#pragma mark - Notifications

-(void) notifyChangedWithUserInfo: (id) userInfo {
	[[NSNotificationCenter defaultCenter] postNotificationName:changeNotificationName object:self userInfo:userInfo];
}

-(void) subscribeForUpdateNotifications: (id)observer selector: (SEL)selector {
	[[NSNotificationCenter defaultCenter] addObserver:observer
																					 selector:selector
																							 name:changeNotificationName
																						 object:self];

}
-(void) unSubscribeFromUpdateNotifications: (id)observer {
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:changeNotificationName object:self];

}
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
	if (_managedObjectContext != nil) {
		return _managedObjectContext;
	}
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return _managedObjectContext;
}

#pragma mark - Basic Core Data functionality

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
	if (_managedObjectModel != nil) {
		return _managedObjectModel;
	}

	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.coredataModel withExtension:@"momd"];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (_persistentStoreCoordinator != nil) {
		return _persistentStoreCoordinator;
	}

	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![self addPersistentStore:_persistentStoreCoordinator]) {
		abort();
	}
	
	return _persistentStoreCoordinator;
}

- (NSPersistentStore *) addPersistentStore:(NSPersistentStoreCoordinator *)coordinator {
	NSLog(@"localDataStorageFile = %@", self.dataStorageFileName);
	NSURL *localStore = [self localStorageFileURL]; // absolute url

	// options for persistent store
	// automigrate
	NSDictionary *options =
	@{
		NSMigratePersistentStoresAutomaticallyOption:@YES,
		NSInferMappingModelAutomaticallyOption:@YES
		};

	[coordinator lock];

	NSError *error = nil;
	NSPersistentStore *store =
	[coordinator addPersistentStoreWithType:NSSQLiteStoreType
														configuration:nil
																			URL:localStore
																	options:options
																		error:&error];

	if (!store) {
		NSLog(@"Unresolved CoreData error %@, %@", error, [error userInfo]);
		/*
		 Typical reasons for an error here include:
		 * The persistent store is not accessible;
		 * The schema for the persistent store is incompatible with current managed object model.
		 Check the error message to determine what the actual problem was.


		 If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

		 If you encounter schema incompatibility errors during development, you can reduce their frequency by:
		 * Simply deleting the existing store:
		 */

//		[[NSFileManager defaultManager] removeItemAtURL:localStore error:nil];
		 /* */
	}
	[coordinator unlock];

	return store;
}

@end
