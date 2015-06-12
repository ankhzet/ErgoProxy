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
    instance = [self any] ?: [self insertNew];
	});
	return instance;
}


- (void) registerStorage:(AZStorage *)storage {
	storage.proxifier = self;
}

- (AZStorage *) storageWithURL:(NSString *)url {
	for (AZStorage *storage in [self.storages allObjects])
		if ([storage.url isEqualTo:url] || [[storage fullURL] isEqualTo:url])
			return storage;

	AZStorage *storage = [AZStorage serverWithURL:url];
	[self registerStorage:storage];
	return storage;
}

- (NSEnumerator *) downloaders {
	@synchronized(self) {
		if (!downloaders)
			return nil;
	}
	@synchronized(downloaders) {
		AZ_Mutable(Array, *all);
		for (NSDictionary *batch in [downloaders allValues])
			for (id downloader in [batch allValues])
				[all addObject:downloader];

		return [all objectEnumerator];
	}
}

- (AZErgoDownloader *) downloaderForURL:(NSString *)url {
	for (AZErgoDownloader *downloader in [self downloaders])
		if ([downloader hasDownloadForURL:url])
			return downloader;

	return nil;
}

- (AZErgoDownloader *) downloaderForStorage:(AZStorage *)storage andParams:(AZDownloadParams *)params {
	NSString *paramsHash = [[params hashed] copy] ?: @"default";
	NSString *storagesHash = storage ? [[storage fullURL] copy] : @"resolver";

	@synchronized(self) {
		if (!downloaders)
			downloaders = [NSMutableDictionary dictionary];
	}

	@synchronized(downloaders) {
		NSMutableDictionary *parametrizedDownloaders = GET_OR_INIT(downloaders[paramsHash], [NSMutableDictionary new]);

		AZErgoDownloader *downloader = parametrizedDownloaders[storagesHash];

		if (!downloader) {
			downloader = parametrizedDownloaders[storagesHash] = [AZErgoDownloader downloaderForStorage:storage];
			[self bindAsDelegateTo:downloader solo:NO];

			if ([self hasRunningDownloaders])
				[downloader processDownloads];
		}

		return downloader;
	}
}

- (AZDownload *) downloadForURL:(NSString *)url withParams:(AZDownloadParams *)params {
	AZDownload *download = [AZDownload downloadForURL:url withParams:params];
	download.proxifier = self;
	download.state = AZErgoDownloadStateDownloaded;

	AZErgoDownloader *downloader = [self downloaderForDownload:download];

	return [downloader hasDownloadForURL:url];
}

- (AZErgoDownloader *) downloaderForDownload:(AZDownload *)download {
	AZErgoDownloader *downloader = [self downloaderForURL:download.sourceURL];
	if (downloader)
		return downloader;

	downloader = [self downloaderForStorage:download.storage andParams:download.downloadParameters];
	[downloader addDownload:download];
	[self notifyListeners:download];

	return downloader;
}

- (void) reRegisterDownloads:(BOOL(^)(AZDownload *download))filterBlock {
	AZ_Mutable(Array, *downloads);
	@synchronized(self) {
		for (NSDictionary *parametrized in [downloaders allValues])
			for (AZErgoDownloader *downloader in [parametrized allValues]) {
				NSArray *objects = [downloader.downloads allValues];

				if (filterBlock)
					objects = [objects objectsAtIndexes:[objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
						return filterBlock(obj);
					}]];

				[downloads addObjectsFromArray:objects];
			}

		if (!![downloads count])
			downloaders = nil;
	}

	for (AZDownload *download in downloads) {
		[self registerForDownloading:download];
	}
}

- (void) reRegisterDownloads {
	[self reRegisterDownloads:nil];
}

- (void) registerForDownloading:(AZDownload *)download {
	[download fixState];

	if (HAS_BIT(download.state, AZErgoDownloadStateDownloaded))
		return;

	download.proxifier = self;

	if (!download.fileURL)
		UNSET_BIT(download.state, AZErgoDownloadStateAquired);
	else
		download.supportsPartialDownload = YES;

	if (!(download.storage && download.proxifierHash))
		UNSET_BIT(download.state,  AZErgoDownloadStateResolved);

//	UNSET_BIT(download.state, AZErgoDownloadStateAquired);

	if (!download.downloadParameters)
		download.downloadParameters = [AZDownloadParams defaultParams:download.forManga];

	[self downloaderForDownload:download];

	[self bindAsDelegateTo:download solo:NO];
}

- (void) runDownloaders:(BOOL)run {
	for (AZErgoDownloader *downloader in [self downloaders])
		if (run && !downloader.running)
			[downloader processDownloads];
		else
			if (downloader.running && !run)
				[downloader stop];
}

- (void) pauseDownloaders:(BOOL)pause {
	for (AZErgoDownloader *downloader in [self downloaders])
		if (pause)
			[downloader pause];
		else
			[downloader resume];
}

- (NSUInteger) hasRunningDownloaders {
	NSUInteger running = 0;
	for (AZErgoDownloader *downloader in [self downloaders])
		if (downloader.running)
			running++;

	return running;
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
	[self.md_delegate downloader:downloader stateSchanged:state];
}

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state {
	if (state == AZErgoDownloadStateResolved) {
		AZErgoDownloader *downloader = [self downloaderForURL:download.sourceURL];
		[downloader removeDownload:download];

		downloader = [self downloaderForDownload:download];
	}
	[self.md_delegate download:download stateChanged:state];
}

- (void) download:(AZDownload *)download progressChanged:(double)progress {
	[self.md_delegate download:download progressChanged:progress];
}

@end