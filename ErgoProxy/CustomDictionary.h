//
//  CustomDictionary.h
//  ErgoProxy
//
//  Created by Ankh on 12.11.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomDictionary : NSObject {
@public
	id owner;
@protected
	NSMutableDictionary *dictionary;
}

+ (instancetype) custom:(id)owner;

- (void) setObject:(id)object forKeyedSubscript:(id<NSCopying>)key;
- (id) objectForKeyedSubscript:(id)key;
- (NSUInteger) count;
- (NSArray *) allKeys;
- (NSArray *) allValues;
+ (BOOL) isDictionary:(id)object;

@end

@interface RootDictionary : CustomDictionary @end
@interface GroupsDictionary : CustomDictionary @end
@interface ItemsDictionary : CustomDictionary @end
