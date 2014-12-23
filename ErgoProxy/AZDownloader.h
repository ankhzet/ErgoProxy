//
//  AZDownloader.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZErgoDownloader.h"

@class AZDownload, AZDownloadParams, AZStorage, AZProxifier;
@interface AZDownloader : AZErgoDownloader

@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) BOOL running;
@property (nonatomic, readonly) NSUInteger inProcess;
@property (nonatomic) NSUInteger concurentTasks;
@property (nonatomic) NSTimeInterval consecutiveIterationsInterval;

@property (nonatomic, weak) AZStorage *storage;
@property (nonatomic) NSDictionary *downloads;

+ (instancetype) downloaderForStorage:(AZStorage *)storage;

- (AZDownload *) addDownload:(AZDownload *)download;
- (AZDownload *) hasDownloadForURL:(NSURL *)url;
- (void) removeDownload:(AZDownload *)download;

@end

@interface AZDownloader (Downloading)

- (void) pause;
- (void) resume;
- (void) stop;
- (void) processDownloads;

@end
