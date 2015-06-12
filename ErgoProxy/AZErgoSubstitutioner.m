//
//  AZErgoSubstitutioner.m
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoSubstitutioner.h"

#import "AZErgoMangaCommons.h"

@interface AZErgoSubstitutioner () {
	id<AZErgoSubtitutionerDataSupplier> dataSupplier;
}

@end

@implementation AZErgoSubstitutioner
@synthesize dataSupplier = dataSupplier;

+ (instancetype) substitutionerWithDataSupplier:(id<AZErgoSubtitutionerDataSupplier>)dataSupplier {
	AZErgoSubstitutioner *s = [self new];
	s->dataSupplier = dataSupplier;
	return s;
}

- (NSString *) getSubstitution:(NSString *)key {
	if ([key rangeOfString:@":"].location != NSNotFound) {
		NSArray *components = [key componentsSeparatedByString:@":"];

		NSString *substitution = nil;

		for (NSString *component in components)
			if (!substitution) {
				substitution = dataSupplier ? ([self getData:component] ?: @"") : component;
			} else {
				SEL selector = NSSelectorFromString([NSString stringWithFormat:@"data%@:", [component capitalizedString]]);
				if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
					substitution = [self performSelector:selector withObject:substitution];
#pragma clang diagnostic pop
				}
			}

		return substitution;
	}

	return dataSupplier ? [self getData:key] : nil;
}

- (id) getData:(NSString *)keypath {
	NSArray *path = [keypath componentsSeparatedByString:@"."];
	keypath = [path firstObject];

	id data = [dataSupplier getDataByKey:keypath];
	if ([path count] > 1)
		for (NSString *key in path)
			if (key != keypath)
				data = [data objectForKey:key];

	return data;
}

@end

@implementation AZErgoSubstitutioner (SubstitutionsFormatters)

- (NSString *) dataDashed:(NSString *)data {
	NSArray *components = [data componentsSeparatedByCharactersInSet:[NSCharacterSet letterCharacterSet]];
	data = [[components componentsJoinedByString:@"  "] stringByReplacingOccurrencesOfString:@"  " withString:@" "];

	data = [data stringByReplacingOccurrencesOfString:@" " withString:@"-"];
	return data;
}

- (NSString *) dataCapitalized:(NSString *)data {
	return [data capitalizedString];
}

- (NSString *) dataLowercase:(NSString *)data {
	return [data lowercaseString];
}

- (NSString *) dataUppercase:(NSString *)data {
	return [data uppercaseString];
}

- (NSString *) dataUrlencoded:(NSString *)data {
	return [data stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *) dataJson:(NSString *)data {
	NSData *json = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
	return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

- (NSString *) dataChapter:(id)data {
	return [AZErgoMangaChapter formatChapterID:[[data description] floatValue]];
}

- (NSString *) dataEmpty:(NSString *)data {
	return data ? data : @"";
}

- (NSString *) dataBool:(id)data {
	BOOL value = NO;

	if (!!data) {
		if ([data respondsToSelector:@selector(boolValue)])
			value = [data boolValue];

		else
			value = [[data description] boolValue];
}

	return value ? @"true" : @"false";
}

@end
