//
//  AZDataPproxyContainer.h
//  AnkhZet
//
//  This class is used to encapsulate ( or it tries to encapsulate %) ) data managing code (like iCloud sync).
//
//  Created by Ankh on 08.01.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZDataProxy.h"

@interface AZDataProxyContainer : NSObject

@property (nonatomic, strong) AZDataProxy *dataProxy;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// singletone instance aquiring. Throws exception, if not configured with +initInstance first.
+(AZDataProxyContainer *) getInstance;

// singletone configuration. Only first call have impact
+(AZDataProxyContainer *) initInstance: (AZDataProxy *)proxy;

// commit all changes in CoreData storage
+(BOOL) saveContext;

@end
