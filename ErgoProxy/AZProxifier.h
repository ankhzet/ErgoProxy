//
//  AZProxifier.h
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZProxyServer.h"
#import "AZErgoCustomDownloader.h"

#import "AZDownload.h"

#import "AZMultipleTargetDelegate.h"

@class AZStorage, AZErgoDownloader, AZDownload, AZDownloadParams;

@interface AZProxifier : AZProxyServer

@property (nonatomic, retain) NSSet *storages;
@property (nonatomic, retain) NSSet *downloads;

+ (instancetype) sharedProxifier;

- (void) registerStorage:(AZStorage *)storage;

- (AZStorage *) storageWithURL:(NSString *)url;
- (AZDownload *) downloadForURL:(NSString *)url withParams:(AZDownloadParams *)params;
- (AZErgoDownloader *) downloaderForURL:(NSString *)url;
- (void) registerForDownloading:(AZDownload *)download;
- (void) reRegisterDownloads;
- (void) reRegisterDownloads:(BOOL(^)(AZDownload *download))filterBlock;

- (NSEnumerator *) downloaders;

- (void) runDownloaders:(BOOL)run;
- (void) pauseDownloaders:(BOOL)pause;
- (NSUInteger) hasRunningDownloaders;

@end

// may send AZErgoDownloadStateListener delegated methods
@interface AZProxifier (Delegation) <AZErgoDownloaderDelegate, AZMultipleTargetDelegateProtocol>

- (void) notifyListeners:(AZDownload *)download;

@end