//
//  AZSynkEnabledStorage.h
//  AnkhZet
//
//  Created by Ankh on 01.01.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZSynkEnabledStorage.h"
#import "AZUtils.h"

@interface AZSynkEnabledStorage () {
	NSDictionary *remoteChanges;
}

@end

@implementation AZSynkEnabledStorage
@synthesize performSynk = _performSynk;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


// init with default data manager.
-(id)init {
	if (!(self = [super init]))
		return self;
	
	_performSynk = [[NSUserDefaults standardUserDefaults] boolForKey:@"useSynchronization"];
	
	return self;
}

- (void) setPerformSynk:(BOOL)performSynk {
	if (_performSynk == performSynk) {
		return;
	}
	_performSynk = performSynk;
	[self synkToggled];
}

- (BOOL) performSynk {
	return _performSynk;
}

/*! @brief Uploading and downloading linked files on CoreData updates.
 New files will be scheduled for up/downloading. File deletions will be handled automatically on managed context save. File updates never appears.
 @param fromRemote Yes, if changes arrived from remote server. If YES, changes will be remembered and handled on next context save. Else, changes will be compared with previously stored remote changes and processed.
 @param changes Dictionary with changed objects, as in userInfo, provided by NSManagedObjectContextDidSaveNotification notification.
 @return Yes, if processed succesfully. No, if synkchronization unavailable.
 */
-(BOOL) performSynkIfRequiredFromRemote:(BOOL)fromRemote withChanges:(NSDictionary *)changes {
	if (![self synkable])
		return NO;

//	NSLog(@"%s", __PRETTY_FUNCTION__);
	if (fromRemote) {
		remoteChanges = changes;
		return YES;
	}

	NSSet *iRemote, *iLocal;

	iRemote = remoteChanges[NSInsertedObjectsKey];
	iLocal = changes[NSInsertedObjectsKey];
	for (NSManagedObject *local in iLocal) {
		NSString *fileToSynk = [self filterDiff:local];
		if (!fileToSynk)
			continue;

    if ([iRemote member:local]) {
			// arrived from remote storage
			[self doDownload:fileToSynk];
		} else {
			[self doUpload:fileToSynk];
		}
	}
	return YES;
}

/*!
 @brief Force file download if needed and possible.
 */
-(BOOL) doDownload:(NSString *)fileName {
	AZFileSynkState state = [self fileState:fileName];

	if (!(state & AZFileSynkStateIsRemote))
		return NO;

	if (state & AZFileSynkStateDownloading)
		return YES;

	return [self fileDownload:fileName] & AZFileSynkStateDownloading;
}

/*!
 @brief Force file upload if needed and possible.
 */
-(BOOL) doUpload:(NSString *)fileName {
	AZFileSynkState state = [self fileState:fileName];

	if (!(state & AZFileSynkStateIsLocal))
		return NO;

	if (state & AZFileSynkStateUploading)
		return YES;

	return [self fileUpload:fileName] & AZFileSynkStateUploading;
}

#pragma mark Overridable methods

-(AZFileSynkState) fileState:(NSString *)fileName {
	return AZFileSynkStateNone;
}

-(AZFileSynkState) fileDownload:(NSString *)fileName {
	return AZFileSynkStateNone;
}

-(AZFileSynkState) fileUpload:(NSString *)fileName {
	return AZFileSynkStateNone;
}

-(NSString *) filterDiff:(NSManagedObject *)entity {
	return NO;
}

- (BOOL) synkable {
	return NO;
}

- (void) synkToggled {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	// try to recreate Core Data managers
	_managedObjectContext = nil;
	_persistentStoreCoordinator = nil;
	[self managedObjectContext];
}

#pragma mark - CoreData relative methods override

/*!
	@brief Metods returns persistent storage coordinator if it was created previously. Otherwise, new coordinator will be created. If device is Synk-enabled, Remote-synched store will be added to coordinator. Method returns immediately, store setup made in separate thread, after setup update notification will be sent to observers (see (un)subscribeForUpdateNotifications method).
*/
-(NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	if(_persistentStoreCoordinator != nil) {
		return _persistentStoreCoordinator;
	}
	
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	NSPersistentStoreCoordinator *coordinator = _persistentStoreCoordinator;
	
	// Setup persistent store in another thread:
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if ([self synkable]) {
			[self addRemoteStore:coordinator];
		} else {
			DDLogVerbose(@"Not a synk-enabled device (or disabled in preferences) - using a local store");
			[self addPersistentStore:coordinator];
		}

		[NSUserDefaults notify:self onDefaultsChange:@selector(userDefaultsChanged:)];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self notifyChangedWithUserInfo:nil];
		});
	});
	
	return _persistentStoreCoordinator;
}

/*!
 */
- (NSPersistentStore *) addRemoteStore:(NSPersistentStoreCoordinator *)coordinator {
	return [self addPersistentStore:coordinator];
}

- (NSManagedObjectContext *)managedObjectContext {
	
	if (_managedObjectContext != nil) {
		return _managedObjectContext;
	}

	_managedObjectContext = [super managedObjectContext];

	if (_managedObjectContext != nil) {
		[_managedObjectContext performBlockAndWait:^{
//			//TODO: modify to accept NSPersistentStoreDidImportContentChangesNotification-like notifications
//			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteChangesImport:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
		}];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localChangesSave:) name:NSManagedObjectContextDidSaveNotification object:_managedObjectContext];

	return _managedObjectContext;
}

- (void)remoteChangesImport:(NSNotification *)notification {
	DDLogVerbose(@"Merging in changes from remote storage...");

	[self performSynkIfRequiredFromRemote:YES withChanges:notification.userInfo];
	NSManagedObjectContext *moc = [self managedObjectContext];

	[moc performBlock:^{
		[moc mergeChangesFromContextDidSaveNotification:notification];
		[self saveContext];
////			NSLog(@"Strange CoreData behavior, context save after merge failed.");
//		else
			[self notifyChangedWithUserInfo:[notification userInfo]];
	}];
}

- (void)localChangesSave:(NSNotification *)notification {
//	NSLog(@"Changes in local storage...");

	[self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
//	[self performSynkIfRequiredFromRemote:NO withChanges:notification.userInfo];
}

/*! @brief Save CoreData db updates. If there are related file updates - they will be pushed on to remote storage. */
//-(BOOL) saveContext {
//	return [super saveContext];
//}


- (void) userDefaultsChanged: (NSNotification *) notification {
	self.performSynk = [[NSUserDefaults standardUserDefaults] boolForKey:@"useSynchronization"];
}


@end

