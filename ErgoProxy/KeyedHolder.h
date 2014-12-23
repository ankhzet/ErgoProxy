//
//  KeyedHolder.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyedHolder : NSObject <NSCopying> {
@public
  id holdedObject;
}

+ (instancetype) holderFor:(id)object;

+ (BOOL) isA:(id)object;

@end

