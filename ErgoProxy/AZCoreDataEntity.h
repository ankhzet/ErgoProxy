//
//  AZCoreDataEntity.h
//  AnkhZet
//
//  Created by Ankh on 23.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface AZCoreDataEntity : NSManagedObject

+ (instancetype) insertNew;
- (void) delete;

+ (NSString *) CDEntityName;
+ (NSEntityDescription *) entityDescription;

/*!@brief Filters entities in DB with predicate (if not nil) and returns all finded (array), or one of finded (entity), if limit is set to 1.
 */
+ (id) filter:(NSPredicate *)predicate limit:(NSUInteger)limit;

+ (instancetype) unique:(NSPredicate *)filter initWith:(void(^)(id entity))block;

@end