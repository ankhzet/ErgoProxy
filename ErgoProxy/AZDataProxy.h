//
//  AZDataProxy.h
//  AnkhZet
//
//  CoreData managing wrapper
//
//  Created by Ankh on 08.01.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZUtils.h"

extern NSString *const kDPParameterModelName;
extern NSString *const kDPParameterStorageFile;
extern NSString *const kDPParameterSyncDirectory;

@interface AZDataProxy : NSObject

// CoreData stuff
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// core data model name
@property (nonatomic, strong) NSString *coredataModel;

// directory name to store local data
@property (nonatomic, strong) NSString *localDataDirectory;

// file name to store coredata file
@property (nonatomic, strong) NSString *dataStorageFileName;

/*!
 @brief Creates data proxy with specified parameters.
 Known parameters:
 kDPParameterStorageFile - filename of sql storage file
 kDPParameterSyncDirectory - local/remote directory name to sync
 */
+ (instancetype) storageWithParameters:(NSDictionary *)appParameters;
/*!
 @brief Inits data proxy with specified parameters.
 Known parameters:
 kDPParameterStorageFile - filename of sql storage file
 kDPParameterSyncDirectory - local/remote directory name to sync
 */
- (id)initWithParameters:(NSDictionary *)appParameters;

// flush CoreData to storage...
-(BOOL) saveContext;

// absolute url for local data storage (e.g. database file)
-(NSURL *) localDataDirURL;

// absolute url of local coredata file
-(NSURL *) localStorageFileURL;

- (NSPersistentStore *) addPersistentStore:(NSPersistentStoreCoordinator *)coordinator;

-(void) notifyChangedWithUserInfo: (id) userInfo;

// subscribe for notifications on remote Core Data changes import
-(void) subscribeForUpdateNotifications: (id)observer selector: (SEL)selector;
-(void) unSubscribeFromUpdateNotifications: (id)observer;


@end
