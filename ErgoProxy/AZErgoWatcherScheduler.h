//
//  AZErgoWatcherScheduler.h
//  ErgoProxy
//
//  Created by Ankh on 29.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AZErgoWatcherScheduler : NSObject

@property (nonatomic) NSTimeInterval timeInterval;

typedef void (^AZErgoWatcherSchedulerExecutionBlock)(AZErgoWatcherScheduler *scheduler, BOOL *stop);
+ (instancetype) schedulerWithBlock:(AZErgoWatcherSchedulerExecutionBlock)block;


- (void) invalidate;
- (void) revalidate;

@end
