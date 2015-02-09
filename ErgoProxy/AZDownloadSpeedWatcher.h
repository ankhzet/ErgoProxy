//
//  AZDownloadSpeedWatcher.h
//  ErgoProxy
//
//  Created by Ankh on 12.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZMultipleTargetDelegate.h"

@class AZDownloadSpeedWatcher;
@protocol AZDownloadSpeedWatcherDelegate <NSObject>

- (void) watcherUpdated:(AZDownloadSpeedWatcher *)watcher;

@end

@interface AZDownloadSpeedWatcher : NSObject

+ (instancetype) sharedSpeedWatcher;

- (void) downloaded:(NSUInteger)bytes;

- (NSUInteger) totalDownloaded;
- (float) averageSpeed;
- (float) averageSpeedSince:(NSTimeInterval)date;

+ (NSTimeInterval) timeWithTimeIntervalSinceNow:(NSTimeInterval)delta;

@end

@interface AZDownloadSpeedWatcher () <AZMultipleTargetDelegateProtocol>

@end