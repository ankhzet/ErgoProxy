//
//  AZErgoDictionaryDataSupplier.m
//  ErgoProxy
//
//  Created by Ankh on 10.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoDictionaryDataSupplier.h"

@implementation AZErgoDictionaryDataSupplier {
	NSDictionary *data;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (!(self = [self init]))
		return self;

	self->data = dictionary;
	return self;
}

- (id) getDataByKey:(NSString *)key {
	key = [key lowercaseString];

	if ([data objectForKey:key])
		return [data objectForKey:key];

	return nil;
}

+ (instancetype) dataSupplier:(NSDictionary *)originalData {
	return [[self alloc] initWithDictionary:originalData];
}

+ (AZErgoSubstitutioner *) dataSubstitutioner:(NSDictionary *)originalData {
	return [AZErgoSubstitutioner substitutionerWithDataSupplier:[self dataSupplier:originalData]];
}

@end
