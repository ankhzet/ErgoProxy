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

- (AZStorage *) storageWithURL:(NSURL *)url;
- (AZDownload *) downloadForURL:(NSURL *)url withParams:(AZDownloadParams *)params;
- (AZErgoDownloader *) downloaderForURL:(NSURL *)url;
- (AZErgoDownloader *) newDownloaderForStorage:(AZStorage *)storage andParams:(AZDownloadParams *)params;
- (void) reRegisterDownload:(AZDownload *)download;

- (NSEnumerator *) downloaders;

- (void) runDownloaders:(BOOL)run;
- (void) pauseDownloaders:(BOOL)pause;

@end

// may send AZErgoDownloadStateListener delegated methods
@interface AZProxifier (Delegation) <AZErgoDownloaderDelegate, AZMultipleTargetDelegateProtocol>

- (void) notifyListeners:(AZDownload *)download;

@end