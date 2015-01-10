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

@implementation AZDataProxy {
	dispatch_queue_t cdOwnerQueue, cdFetchQueue;
	NSThread *cdOwnerThread;
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


-(id) init {
	if (!(self = [super init]))
		return nil;

	self.coredataModel = @"AnkhZet";
	self.localDataDirectory = @"Documents";
	self.dataStorageFileName = @"Database.sqlite";

	cdOwnerQueue = dispatch_queue_create("org.ankhzet.coredata-owner", DISPATCH_QUEUE_SERIAL);
	cdFetchQueue = dispatch_queue_create("org.ankhzet.coredata-fetcher", DISPATCH_QUEUE_SERIAL);

	return self;
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

+ (instancetype) storageWithParameters:(NSDictionary *)appParameters {
	return [[self alloc] initWithParameters:appParameters];
}

+ (instancetype) initSharedProxy:(NSDictionary *)appParameters {
	static AZDataProxy *sharedInstance;

	if (!sharedInstance) {
		@synchronized(self) {
			if (!sharedInstance) {
				NSAssert(!!appParameters, @"Tried to access CoreData proxy shared instance but not initialized it yet.");

				sharedInstance = [self storageWithParameters:appParameters];
			}
		}
	}

	return sharedInstance;
}

+ (instancetype) sharedProxy {
	return [self initSharedProxy:nil];
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

	__block BOOL result = YES;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;

	if (managedObjectContext != nil) {

		dispatch_sync(cdFetchQueue, ^{
			@synchronized(self) {
				if (![managedObjectContext commitEditing])
					NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));

				@try {
					NSError *error = nil;
					if ([managedObjectContext hasChanges] && !(result = [managedObjectContext save:&error])) {
						NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
						return;
					}
				}
				@catch (NSException *exception) {
					NSLog(@"CoreData error: %@", exception);
				}
				@finally {
				}
			}
		});

	}
	
	return result;
}

- (void) performSelectorOnContextsThread:(dispatch_block_t)param {
	param();
}

- (void) performOnFetchThread:(dispatch_block_t)block {
	dispatch_sync(cdFetchQueue, ^{
		dispatch_sync(cdOwnerQueue, ^{
			[self performSelector:@selector(performSelectorOnContextsThread:)
									 onThread:cdOwnerThread
								 withObject:block
							waitUntilDone:YES];
		});
	});
}


- (NSArray *)executeFetchRequest:(NSFetchRequest *)request error:(NSError **)error {

	__block NSArray *result = nil;

	[self performOnFetchThread:^{
		@synchronized(self) {
			result = [self.managedObjectContext executeFetchRequest:request error:error];
		}
	}];

	return result;
}

- (NSEntityDescription *) entityForName:(NSString *)name {
	return [NSEntityDescription entityForName:name
										 inManagedObjectContext:self.managedObjectContext];
}

- (id) insertNewObjectForEntityForName:(NSString *)name {
	return [NSEntityDescription insertNewObjectForEntityForName:name
																			 inManagedObjectContext:self.managedObjectContext];
}

- (void) deleteObject:(NSManagedObject *)object {
	[self.managedObjectContext deleteObject:object];
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
		dispatch_sync(cdOwnerQueue, ^{
			cdOwnerThread = [NSThread currentThread];

			_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
		});
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
