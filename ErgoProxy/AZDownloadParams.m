//
//  AZDownloadParams.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZDownloadParams.h"
#import "AZDataProxyContainer.h"
#import "AZDownloadParameter.h"

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

	AZDownloadParams *instance = [self unique:[NSPredicate predicateWithBlock:^BOOL(AZDownloadParams *entity, NSDictionary *bindings) {
		return [entity.hashed isEqualToString:hash];
	}] initWith:^(id instantiated) {
		[instantiated applyParams:parameters];
	}];

	return instance;
}

+ (instancetype) defaultParams {
	NSMutableDictionary *params = [NSMutableDictionary dictionary];

	NSInteger width = PREF_INT(PREFS_DOWNLOAD_WIDTH);
	NSInteger height = PREF_INT(PREFS_DOWNLOAD_HEIGHT);
	NSInteger quality = PREF_INT(PREFS_DOWNLOAD_QUALITY);
	NSInteger webtoon = PREF_BOOL(PREFS_DOWNLOAD_WEBTOON);

	if (width) params[kDownloadParamMaxWidth] = @(width);
	if (height) params[kDownloadParamMaxHeight] = @(height);
	if (quality) params[kDownloadParamQuality] = @(quality);
	if (webtoon) params[kDownloadParamIsWebtoon] = @(webtoon);

	return [self params:params];
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

	if (recreate)
		return [[self class] params:[self paramsDictionary]];

	return self;
}

+ (NSString *) hashedParams:(NSDictionary *)parameters {
	return [NSString stringWithFormat:@"{%@:%@}",
					[[parameters allKeys] componentsJoinedByString:@";"],
					[[parameters allValues] componentsJoinedByString:@";"]];
}

- (NSDictionary *) paramsDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:[self.parameters count]];
	for (AZDownloadParameter *param in self.parameters)
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
