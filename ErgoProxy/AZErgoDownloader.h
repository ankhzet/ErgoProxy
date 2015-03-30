//
//  AZErgoDownloader.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZErgoCustomDownloader.h"
#import "AZMultipleTargetDelegate.h"

@class AZStorage;
@interface AZErgoDownloader : AZErgoCustomDownloader

@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) BOOL running;
@property (nonatomic, readonly) NSUInteger inProcess;
@property (nonatomic) NSString *concurentTasks;
@property (nonatomic) NSTimeInterval consecutiveIterationsInterval;

+ (instancetype) downloaderForStorage:(AZStorage *)storage;

@end

@interface AZErgoDownloader (Downloading) <AZMultipleTargetDelegateProtocol>

- (void) pause;
- (void) resume;
- (void) stop;
- (void) processDownloads;

@end
