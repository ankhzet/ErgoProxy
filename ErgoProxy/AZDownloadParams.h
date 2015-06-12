//
//  AZDownloadParams.h
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZCoreDataEntity.h"

extern NSString *kDownloadParamMaxWidth;
extern NSString *kDownloadParamMaxHeight;
extern NSString *kDownloadParamQuality;
extern NSString *kDownloadParamIsWebtoon;

@class AZDownloadParameter, AZErgoManga;
@interface AZDownloadParams : AZCoreDataEntity

@property (nonatomic, retain) NSSet *parameters;
@property (nonatomic, readonly) NSString *hashed;

+ (instancetype) params:(NSDictionary *)parameters;
+ (instancetype) defaultParams:(AZErgoManga *)manga;

- (AZDownloadParameter *) downloadParameter:(NSString *)parameter;
- (AZDownloadParams *) setDownloadParameter:(NSString *)parameter value:(id)value;

- (void) addParametersObject:(AZDownloadParameter *)object;

@end
