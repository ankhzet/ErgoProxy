//
//  AZProxifier.h
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZProxyServer.h"
#import "AZDownload.h"
#import "AZErgoDownloader.h"

@class AZStorage, AZDownloader;

@interface AZProxifier : AZProxyServer <AZErgoDownloaderDelegate>

@property (nonatomic, retain) NSSet *storages;
@property (nonatomic, retain) NSSet *downloads;

@property (nonatomic) id<AZErgoDownloadStateListener> delegate;

+ (instancetype) sharedProxy;

- (void) registerStorage:(AZStorage *)storage;

- (void) notifyListeners:(AZDownload *)download;

- (AZStorage *) storageWithURL:(NSURL *)url;
- (AZDownload *) downloadForURL:(NSURL *)url withParams:(AZDownloadParams *)params;
- (AZDownloader *) downloaderForURL:(NSURL *)url;
- (AZDownloader *) newDownloaderForStorage:(AZStorage *)storage andParams:(AZDownloadParams *)params;
- (void) reRegisterDownload:(AZDownload *)download;

- (NSEnumerator *) downloaders;

- (void) runDownloaders:(BOOL)run;
- (void) pauseDownloaders:(BOOL)pause;

@end
