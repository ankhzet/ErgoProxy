//
//  AZDownloadParams.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZDownloadParams.h"
#import "AZDataProxyContainer.h"

NSString *kDownloadParamMaxWidth = @"kDownloadParamMaxWidth";
NSString *kDownloadParamMaxHeight = @"kDownloadParamMaxHeight";
NSString *kDownloadParamQuality = @"kDownloadParamQuality";
NSString *kDownloadParamIsWebtoon = @"kDownloadParamIsWebtoon";

@interface AZDownloadParams () {
	NSMutableDictionary *parameters;
}

@end

@implementation AZDownloadParams

- (id)initWithParameters:(NSDictionary *)parameters {
	if (!(self = [super init]))
		return self;

	for (NSString *param in [parameters allKeys]) {
    
	}
	return self;
}

+ (AZDownloadParams *) sharedParams:(NSString *)hash {
	NSManagedObjectContext *context = [[AZDataProxyContainer getInstance] managedObjectContext];

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"DownloadParams"
																						inManagedObjectContext:context];
	[fetchRequest setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hashed = %@", hash];

	[fetchRequest setPredicate:predicate];

	NSError *_error = nil;
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&_error];

	return [fetchedObjects lastObject];
}

+ (instancetype) new {
	return [NSEntityDescription insertNewObjectForEntityForName:@"DownloadParams"
																			 inManagedObjectContext:[[AZDataProxyContainer getInstance] managedObjectContext]];
}

+ (instancetype) params:(NSDictionary *)parameters {
	AZDownloadParams *instance = [self sharedParams:[self hashedParams:parameters]];
	if (!instance) {
		instance = [self new];
		instance->parameters = [parameters mutableCopy];
	}
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

- (id) downloadParameter:(NSString *)parameter {
	return parameters[parameter];
}

- (void) setDownloadParameter:(NSString *)parameter value:(id)value {
	parameters[parameter] = value;
}

+ (NSString *) hashedParams:(NSDictionary *)parameters {
	return [NSString stringWithFormat:@"{%@:%@}",
					[[parameters allKeys] componentsJoinedByString:@";"],
					[[parameters allValues] componentsJoinedByString:@";"]];
}

- (NSString *) hashed {
	return [[self class] hashedParams:parameters];
}

@end
