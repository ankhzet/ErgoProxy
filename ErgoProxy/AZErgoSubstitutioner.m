//
//  AZErgoSubstitutioner.m
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoSubstitutioner.h"

@interface AZErgoSubstitutioner () {
	id<AZErgoSubtitutionerDataSupplier> dataSupplier;
}

@end

@implementation AZErgoSubstitutioner

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
			if (!substitution)
				substitution = dataSupplier ? ([dataSupplier getDataByKey:component] ?: @"") : component;
			else {
				SEL selector = NSSelectorFromString([NSString stringWithFormat:@"data%@:", [component capitalizedString]]);
				if ([self respondsToSelector:selector])
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
					substitution = [self performSelector:selector withObject:substitution];
#pragma clang diagnostic pop
			}

		return substitution;
	}

	return dataSupplier ? [dataSupplier getDataByKey:key] : nil;
}

+ (NSString *) formatChapterID:(float)chapter {
	int isBonus = ((int)(chapter * 10)) % 10;

	NSString *string = isBonus ? [NSString stringWithFormat:@"%.1f", chapter] : [NSString stringWithFormat:@"%d", (int)chapter];

	return [self pad:string toLen:isBonus ? 6 : 4];
}

+ (NSString *)pad:(NSString *)str toLen:(NSInteger)len {
	len = len - [str length];
	if (len > 0)
		str = [[@"" stringByPaddingToLength:len withString:@"0" startingAtIndex:0] stringByAppendingString:str];

	return str;
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
	return [AZErgoSubstitutioner formatChapterID:[[data description] floatValue]];
}

- (NSString *) dataEmpty:(NSString *)data {
	return data ? data : @"";
}

@end
