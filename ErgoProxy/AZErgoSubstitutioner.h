//
//  AZErgoSubstitutioner.h
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AZErgoSubtitutionerDataSupplier <NSObject>

- (id) getDataByKey:(NSString *)key;

@end

@interface AZErgoSubstitutioner : NSObject

+ (instancetype) substitutionerWithDataSupplier:(id<AZErgoSubtitutionerDataSupplier>)dataSupplier;

- (NSString *) getSubstitution:(NSString *)key;

+ (NSString *) formatChapterID:(float)chapter;

@end
