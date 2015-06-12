//
//  AZErgoDictionaryDataSupplier.h
//  ErgoProxy
//
//  Created by Ankh on 10.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZErgoSubstitutioner.h"

@interface AZErgoDictionaryDataSupplier : NSObject <AZErgoSubtitutionerDataSupplier>

+ (instancetype) dataSupplier:(NSDictionary *)originalData;
+ (AZErgoSubstitutioner *) dataSubstitutioner:(NSDictionary *)originalData;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
