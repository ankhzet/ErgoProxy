//
//  AZDownloadParams.h
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kDownloadParamMaxWidth;
extern NSString *kDownloadParamMaxHeight;
extern NSString *kDownloadParamQuality;
extern NSString *kDownloadParamIsWebtoon;

@interface AZDownloadParams : NSManagedObject

+ (instancetype) params:(NSDictionary *)parameters;
+ (instancetype) defaultParams;

- (id) downloadParameter:(NSString *)parameter;
- (void) setDownloadParameter:(NSString *)parameter value:(id)value;
- (NSString *) hashed;

@end
