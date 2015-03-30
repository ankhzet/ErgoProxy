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
	dispatch_queue_t cdOwnerQueue, cdPropagateQueue;
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

	cdOwnerQueue = dispatch_queue_create_recursive_serial("org.ankhzet.coredata-context-owner");
	cdPropagateQueue = dispatch_queue_create_recursive_serial("org.ankhzet.coredata-propagation-queue");

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
- (void) saveContext {
	[self.managedObjectContext performBlock:^{
		@synchronized(self) {
			if (![self.managedObjectContext commitEditing])
				DDLogError(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));

			NSError *error = nil;
			if ([self.managedObjectContext hasChanges]) {
				if ([self.managedObjectContext tryLock])
					@try {
						if (![self.managedObjectContext save:&error]) {
							DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
						}
					}
				@finally {
					[self.managedObjectContext unlock];
				}
			}
		}
	}];
}

- (void) performOnFetchThread:(dispatch_block_t)block {
	[self.managedObjectContext performBlockAndWait:block];
}

- (NSUInteger) countForFetchRequest:(NSFetchRequest *)request error:(NSError **)error {
	__block NSUInteger result = 0;

	NSManagedObjectContext *c = self.managedObjectContext;
	[c performBlockAndWait:^{
		result = [c countForFetchRequest:request error:error];
	}];

	return result;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request error:(NSError **)error {
	__block NSArray *temp = nil;

//	BOOL lock = YES;
//
//	dispatch_semaphore_t s = dispatch_semaphore_create(0);
//
//	u_int64_t t = dispatch_time(DISPATCH_TIME_NOW, 0);
//
//		[self.managedObjectContext lock];

	[self.managedObjectContext performBlockAndWait:^{
//	[self.managedObjectContext performBlock:^{
//		[self.managedObjectContext lock];
		temp = [self.managedObjectContext executeFetchRequest:request error:error];
//		[self.managedObjectContext unlock];
//		dispatch_semaphore_signal(s);
	}];


//	while (lock) {
//
//		if (!dispatch_semaphore_wait(s, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.001)))
//			break;
//
//		if (dispatch_time(DISPATCH_TIME_NOW, 0) - t > NSEC_PER_SEC * 5) {
//			lock = NO;
//			NSLog(@"CD fetch timeout!");
//		}
//
//	}

//	[self.managedObjectContext unlock];

	return temp;//[temp transitCoreDataObjects];
}

- (BOOL) securedTransaction:(AZSecureCoreDataTransactionBlok)block {
	__block BOOL result = YES;

	[self.managedObjectContext lock];

	[self.managedObjectContext performBlockAndWait:^{
//	[self performOnFetchThread:^{
		NSManagedObjectContext *tempContext = self.managedObjectContext;
		//[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//
//	dispatch_sync_recursive(cdPropagateQueue, ^{

//		[tempContext performBlockAndWait:^{
//			[tempContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
//		[tempContext setParentContext:self.managedObjectContext];
//		[tempContext setUndoManager:nil];

		BOOL propagateChanges = YES;
		@try {
			block(tempContext, &propagateChanges);
		}
		@catch (id exception) {
			result = NO;
			DDLogError(@"Secured CoreData transaction error: %@", [exception description]);
		}
		@finally {
			if (propagateChanges) {
				@try {
//					[tempContext performBlock:^{
//						[tempContext processPendingChanges];
//					}];
				}
				@catch (id exception) {
						DDLogError(@"Secured CoreData transaction changes propagation error: %@", exception);
				}
//				NSError *error = nil;
//					if (![tempContext save:&error]) {
//						result = NO;
//						NSLog(@"Secured CoreData transaction changes propagation error: %@", [error localizedDescription]);
//					}
			}
		}
	}];
//	});
//		}];
//	}];

	[self.managedObjectContext unlock];

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

- (id) objectWithID:(NSManagedObjectID *)id {
	return [self.managedObjectContext objectWithID:id];
}


- (void) deleteObject:(NSManagedObject *)object {
	[object.managedObjectContext deleteObject:object];
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
		dispatch_sync_recursive(cdOwnerQueue, ^{
			cdOwnerThread = [NSThread currentThread];

			_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
			[_managedObjectContext setUndoManager:nil];
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
	DDLogVerbose(@"localDataStorageFile = %@", self.dataStorageFileName);
	NSURL *localStore = [self localStorageFileURL]; // absolute url

	// options for persistent store
	// automigrate
	NSDictionary *options =
	@{
		NSMigratePersistentStoresAutomaticallyOption:@YES,
//		NSInferMappingModelAutomaticallyOption:@YES,
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
		DDLogError(@"Unresolved CoreData error %@, %@", error, [error userInfo]);
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

@implementation NSManagedObjectContext (PerThreadContext)
#define AZ_SHARED_THREAD_MOC_KEY @"AZ_managedObjectContext"

+ (NSManagedObjectContext *) contextForCurrentThread {
	NSManagedObjectContext *context = nil;

	static OSSpinLock lock = OS_SPINLOCK_INIT;
	@try {
		OSSpinLockLock(&lock);

		NSMutableDictionary *info = [NSThread currentThread].threadDictionary;
		if (!(context = info[AZ_SHARED_THREAD_MOC_KEY])) {
			context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
			context.parentContext = [AZDataProxy sharedProxy].managedObjectContext;
			info[AZ_SHARED_THREAD_MOC_KEY] = context;
		}
	}
	@finally {
		OSSpinLockUnlock(&lock);
	}
	return context;
}

@end

@implementation NSArray (AZDataProxy)

- (NSArray *) transitCoreDataObjects {
	NSUInteger count = [self count];
	if (!count)
		return self;

	NSManagedObjectContext *t = [NSManagedObjectContext contextForCurrentThread];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	for (NSManagedObject *object in self)
		[result addObject:[t objectWithID:object.objectID]];

	return result;
}

@end
