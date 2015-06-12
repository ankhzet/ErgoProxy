//
//  AZDownloadParams.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZDownloadParams.h"
#import "AZDownloadParameter.h"
#import "AZErgoManga.h"
#import "AZDownloadPresets.h"

NSString *kDownloadParamMaxWidth = @"kDownloadParamMaxWidth";
NSString *kDownloadParamMaxHeight = @"kDownloadParamMaxHeight";
NSString *kDownloadParamQuality = @"kDownloadParamQuality";
NSString *kDownloadParamIsWebtoon = @"kDownloadParamIsWebtoon";

@implementation AZDownloadParams
@dynamic parameters;

- (void) applyParams:(NSDictionary *)parameters {
	for (NSString *param in [parameters allKeys])
		[self addParametersObject:[AZDownloadParameter param:param withValue:parameters[param]]];
}

+ (instancetype) params:(NSDictionary *)parameters {
	NSString *hash = [self hashedParams:parameters];

	AZDownloadParams *instance = [self unique:[AZF_ALL predicateWithBlock:^BOOL(AZDownloadParams *entity, NSDictionary *bindings) {
		return [entity.hashed isEqualToString:hash];
	}] initWith:^(id instantiated) {
		[instantiated applyParams:parameters];
	}];

	AZ_Mutable(Array, *empty);
	for (NSString *param in [parameters allKeys])
		if (![instance downloadParameter:param])
			[empty addObject:param];

	if (!![empty count])
		[instance applyParams:[empty mapWithValueFromKeyMapper:^id(NSString *param) {
			return parameters[param];
		}]];

	return instance;
}

+ (NSDictionary *) defaultParamsDictionary:(AZErgoManga *)manga {
	static NSDictionary *map;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    map = @{
						kDownloadParamNameWidth: kDownloadParamMaxWidth,
						kDownloadParamNameHeight: kDownloadParamMaxHeight,
						kDownloadParamNameQuality: kDownloadParamQuality,
						kDownloadParamNameIsWebtoon: kDownloadParamIsWebtoon,
						};
	});

	AZDownloadPresets *presets = [AZDownloadPresets new];
	NSDictionary *defaults = [presets fetchDefaults:[presets pickPreset:manga]];

	defaults = [defaults mapWithKeyRemapper:^id(id entity) {
		return map[entity];
	}];

	return defaults;
}

+ (instancetype) defaultParams:(AZErgoManga *)manga {
	return [self params:[self defaultParamsDictionary:manga]];
}

- (void) addParametersObject:(AZDownloadParameter *)object {
	object.ownedBy = self;
}


- (AZDownloadParameter *) downloadParameter:(NSString *)parameter {
	for (AZDownloadParameter *param in self.parameters)
		if ([param.name isEqualToString:parameter])
			return param;

	return nil;
}

- (AZDownloadParams *) setDownloadParameter:(NSString *)parameter value:(id)value {
	AZDownloadParameter *param = [self downloadParameter:parameter];
	BOOL recreate = !(param && [param.value isEqual:value]);

	if (recreate) {
		NSMutableDictionary *d = [[self paramsDictionary] mutableCopy];
		d[parameter] = value;
		return [[self class] params:d];
	}

	return self;
}

+ (NSString *) hashedParams:(NSDictionary *)parameters {
	NSArray *keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSMutableArray *values = [NSMutableArray new];
	for (NSString *key in keys)
		[values addObject:parameters[key]];

	return [NSString stringWithFormat:@"{%@:%@}",
					[keys componentsJoinedByString:@";"],
					[values componentsJoinedByString:@";"]];
}

- (NSDictionary *) paramsDictionary {
	NSMutableDictionary *d = [[[self class] defaultParamsDictionary:nil] mutableCopy];

	for (AZDownloadParameter *param in [self.parameters allObjects])
		d[param.name] = param.value;

	return d;
}

- (NSString *) hashed {
	return [[self class] hashedParams:[self paramsDictionary]];
}

- (NSString *) description {
	return [self hashed];
}

@end
