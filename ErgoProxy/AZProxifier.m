//
//  AZProxifier.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZProxifier.h"
#import "AZStorage.h"

#import "AZUtils.h"

#import "AZDownload.h"
#import "AZErgoDownloader.h"
#import "AZDownloadParams.h"

@interface AZProxifier () {
	NSMutableDictionary *downloaders;
}

@end

MULTIDELEGATED_INJECT_LISTENER(AZProxifier)
MULTIDELEGATED_INJECT_MULTIDELEGATED(AZProxifier)

@implementation AZProxifier
@dynamic storages, downloads;

+ (instancetype) sharedProxifier {
	static AZProxifier *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    instance = [self unique:[NSPredicate predicateWithFormat:@"url = null"] initWith:^(AZProxifier *instantiated) {
			instantiated.url = nil;
		}];
	});
	return instance;
}


- (void) registerStorage:(AZStorage *)storage {
	storage.proxifier = self;
}

- (AZStorage *) storageWithURL:(NSURL *)url {
	for (AZStorage *storage in self.storages)
		if ([storage.url isEqualTo:url] || [[storage fullURL] isEqualTo:url])
			return storage;

	AZStorage *storage = [AZStorage serverWithURL:url];
	[self registerStorage:storage];
	return storage;
}

- (NSEnumerator *) downloaders {
	return [[downloaders allValues] objectEnumerator];
}

- (AZErgoDownloader *) downloaderForURL:(NSURL *)url {
	for (AZErgoDownloader *downloader in [downloaders allValues])
		if ([downloader hasDownloadForURL:url])
			return downloader;

	return nil;
}

- (AZErgoDownloader *) newDownloaderForStorage:(AZStorage *)storage andParams:(AZDownloadParams *)params {
	NSString *hash = [NSString stringWithFormat:@"%@@%@", storage ? [storage fullURL] : @"", [params hashed]];
	AZErgoDownloader *downloader = downloaders[hash];

	if (!downloader) {
		if (!downloaders)
			downloaders = [NSMutableDictionary dictionary];

		downloader = downloaders[hash] = [AZErgoDownloader downloaderForStorage:storage];
		downloader.delegate = self;
	}

	return downloader;
}

- (AZDownload *) downloadForURL:(NSURL *)url withParams:(AZDownloadParams *)params {
	AZErgoDownloader *downloader = [self downloaderForURL:url];
	if (downloader)
		return [downloader hasDownloadForURL:url];

	AZDownload *download = [AZDownload downloadForURL:url withParams:params];
	download.proxifier = self;

	downloader = [self newDownloaderForStorage:nil andParams:params];
	[downloader addDownload:download];

	[self notifyListeners:download];

	return download;
}

- (void) reRegisterDownload:(AZDownload *)download {
	if (HAS_BIT(download.state, AZErgoDownloadStateDownloaded))
		return;

	download.proxifier = self;

	if (!download.fileURL)
		UNSET_BIT(download.state,AZErgoDownloadStateAquired);
	else
		download.supportsPartialDownload = YES;

	if (!(download.storage && download.proxifierHash))
		UNSET_BIT(download.state,  AZErgoDownloadStateResolved);

//	UNSET_BIT(download.state, AZErgoDownloadStateAquired);

	if (!download.downloadParameters)
		download.downloadParameters = [AZDownloadParams defaultParams];

	AZErgoDownloader *downloader = [self downloaderForURL:download.sourceURL];
	if (!downloader) {
		downloader = [self newDownloaderForStorage:download.storage andParams:download.downloadParameters];
		[downloader addDownload:download];
		[self notifyListeners:download];
	}

	[self bindAsDelegateTo:download solo:NO];
}

- (void) runDownloaders:(BOOL)run {
	for (AZErgoDownloader *downloader in [downloaders allValues])
		if (run && !downloader.running)
			[downloader processDownloads];
		else
			if (downloader.running && !run)
				[downloader stop];
}

- (void) pauseDownloaders:(BOOL)pause {
	for (AZErgoDownloader *downloader in [downloaders allValues])
		if (pause)
			[downloader pause];
		else
			[downloader resume];
}

@end

@implementation AZProxifier (Delegation)

- (void) notifyListeners:(AZDownload *)download {
	[self.md_delegate download:download stateChanged:download.state];
}

- (void) downloader:(AZErgoCustomDownloader *)downloader readyForNextStage:(AZDownload *)download {
	[self notifyListeners:download];
}

- (void) downloader:(AZErgoCustomDownloader *)downloader stateSchanged:(AZErgoDownloaderState)state {
	//TODO: reaction to downloader:stateChanged:
}

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state {
	[self.md_delegate download:download stateChanged:state];
}

- (void) download:(AZDownload *)download progressChanged:(double)progress {
	[self.md_delegate download:download progressChanged:progress];
}

@end