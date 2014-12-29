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
#import "AZDownloader.h"
#import "AZDownloadParams.h"


@interface AZProxifier () {
	NSMutableDictionary *downloaders;
}

@end

@implementation AZProxifier
@synthesize delegate;
@dynamic storages, downloads;

+ (instancetype) sharedProxy {
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

- (AZDownloader *) downloaderForURL:(NSURL *)url {
	for (AZDownloader *downloader in [downloaders allValues])
		if ([downloader hasDownloadForURL:url])
			return downloader;

	return nil;
}

- (AZDownloader *) newDownloaderForStorage:(AZStorage *)storage andParams:(AZDownloadParams *)params {
	NSString *hash = [NSString stringWithFormat:@"%@@%@", storage ? [storage fullURL] : @"", [params hashed]];
	AZDownloader *downloader = downloaders[hash];

	if (!downloader) {
		if (!downloaders)
			downloaders = [NSMutableDictionary dictionary];

		downloader = downloaders[hash] = [AZDownloader downloaderForStorage:storage];
		downloader.delegate = self;
	}

	return downloader;
}

- (AZDownload *) downloadForURL:(NSURL *)url withParams:(AZDownloadParams *)params {
	AZDownloader *downloader = [self downloaderForURL:url];
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
	AZDownloader *downloader = [self downloaderForURL:download.sourceURL];
	if (downloader)
		return;

//	if (!download.proxifierHash)
//		UNSET_BIT(download.state,AZErgoDownloadStateAquired);

	if (!download.storage)
		UNSET_BIT(download.state,  AZErgoDownloadStateResolved);

	UNSET_BIT(download.state, AZErgoDownloadStateAquired);

	if (!download.downloadParameters)
		download.downloadParameters = [AZDownloadParams defaultParams];

	downloader = [self newDownloaderForStorage:download.storage andParams:download.downloadParameters];
	[downloader addDownload:download];

	download.proxifier = self;
	[self notifyListeners:download];
}

- (void) notifyListeners:(AZDownload *)download {
	if (self.delegate)
		[self.delegate download:download stateChanged:download.state];
}

- (void) downloader:(AZErgoDownloader *)downloader readyForNextStage:(AZDownload *)download {
	[self notifyListeners:download];
}

- (void) downloader:(AZErgoDownloader *)downloader stateSchanged:(AZErgoDownloaderState)state {
	//TODO: reaction to downloader:stateChanged:
}

- (void) runDownloaders:(BOOL)run {
	for (AZDownloader *downloader in [downloaders allValues])
		if (run && !downloader.running)
			[downloader processDownloads];
		else
			if (downloader.running && !run)
				[downloader stop];
}

- (void) pauseDownloaders:(BOOL)pause {
	for (AZDownloader *downloader in [downloaders allValues])
		if (pause)
			[downloader pause];
		else
			[downloader resume];
}

@end
