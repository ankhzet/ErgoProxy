//
//  AZErgoCustomDownloader.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoCustomDownloader.h"

#import "AZDownload.h"
#import "AZStorage.h"
#import "AZErgoAPIRequest.h"

#import "AZProxifier.h"
#import "AZErgoAPIRequest.h"
#import "AZErgoDownloader.h"


@interface AZErgoCustomDownloader () {
@protected
	NSMutableDictionary *_downloads;
}

@end

@implementation AZErgoCustomDownloader
@synthesize downloads = _downloads;

- (AZDownload *) addDownload:(AZDownload *)download {
	@synchronized(_downloads) {
		if (!_downloads)
			_downloads = [NSMutableDictionary dictionary];

		AZDownload *old = _downloads[download.sourceURL];
		_downloads[download.sourceURL] = download;

		download.storage = self.storage;
		return old;
	}
}

- (void) removeDownload:(AZDownload *)download {
	@synchronized(_downloads) {
		[_downloads removeObjectForKey:download.sourceURL];
	}
}

- (AZDownload *) hasDownloadForURL:(NSURL *)url {
	@synchronized(_downloads) {
		return _downloads[url];
	}
}

@end

@implementation AZErgoCustomDownloader (Downloads)

- (void) notifyStageChange:(AZDownload *)download {
	if (self.delegate)
		[self.delegate downloader:self readyForNextStage:download];
}

- (void) resolveData:(AZDownload *)download {
	AZProxifier *proxifier = download.proxifier;

	AZErgoDownloader *_downloader = [proxifier downloaderForURL:download.sourceURL];

	AZErgoAPIRequest *proxifyRequest = [AZErgoAPIRequest actionWithName:@"aquire"];
	proxifyRequest.serverURL = proxifier.url;
	[proxifyRequest setParameters:[download fetchParams:!!download.httpError]];
	proxifyRequest.showErrors = NO;

	[[[proxifyRequest success:^(AZHTTPRequest *request, id *data) {
		AZErgoDownloader *downloader = _downloader;
		AZStorage *storage = [proxifier storageWithURL:[AZDownload storageToken:*data]];

		if (downloader.storage != storage) {
			[downloader removeDownload:download];

			downloader = [proxifier newDownloaderForStorage:storage andParams:download.downloadParameters];
			[downloader processDownloads];
		}

		[downloader addDownload:download];

		download.proxifierHash = [AZDownload hashToken:*data];
		download.scanID = [AZDownload scanToken:*data];
		download.state |= AZErgoDownloadStateResolved;
		download.httpError = 0;
		[download downloadError:nil];
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		download.httpError++;
		[download downloadError:[NSString stringWithFormat:@"Download data resolve failed: %@", response]];
		return YES;
	}] executeSynked];
}

- (void) aquireFailReason:(AZDownload *)download {
	NSAssert(!!download.proxifierHash, @"Tried to aquire data when proxifier hash not aquired yet.");
	AZErgoAPIRequest *request = [AZErgoAPIRequest actionWithName:@"proxy"];
	request.serverURL = [download.storage fullURL];
	request.simulateHeadRequest = YES;
	[request setParameters:@{@"data": download.proxifierHash}];
	[[request error:^BOOL(AZHTTPRequest *action, NSString *response) {
		//		NSLog(@"%@", response);
		[download downloadError:[NSString stringWithFormat:@"Download data aquire failed: %@", response]];
		return NO;
	}] executeSynked];
}

- (void) aquireData:(AZDownload *)download {
	//	NSLog(@"Aquiring [%@]...", download.sourceURL);

	if (!download.proxifierHash) {
		UNSET_BIT(download.state, AZErgoDownloadStateResolved);
		return;
	}

	download.fileURL = nil;

	AZErgoAPIRequest *request = [AZErgoAPIRequest actionWithName:@"proxy"];
	request.serverURL = [download.storage fullURL];
	request.httpMethod = @"HEAD";
	request.acceptEmptyResponseAsSuccess = YES;
	request.showErrors = NO;
	[request setParameters:@{@"data": download.proxifierHash}];
	[[[[request success:^BOOL(AZHTTPRequest *_request, id *data) {
		NSDictionary *headers = [_request.response allHeaderFields];
		if (!download.fileURL) {
			[self aquireFailReason:download];
			return YES;
		}
		//				NSLog(@"%@", headers);
		download.totalSize = [headers[@"Content-Length"] integerValue];
		download.supportsPartialDownload = [headers[@"Accept-ranges"] isEqualToString:@"bytes"];
		download.state |= AZErgoDownloadStateAquired;
		[download downloadError:nil];
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		//		NSLog(@"Resolve failed");
		[download downloadError:[NSString stringWithFormat:@"Download data aquire failed: %@", response]];
		return NO;
	}] processRedirects:^NSURLRequest *(NSURLConnection *_connection, NSURLRequest *_request, NSURLResponse *_response) {
		NSHTTPURLResponse *httpResponse = (id)_response;
		NSUInteger code = [httpResponse statusCode];
		if ((code >= 300) && (code < 400)) {
			NSString *url = httpResponse.allHeaderFields[@"Location"];
			NSRange r = [url rangeOfString:@"?"];
			if (r.length)
				url = [url substringToIndex:r.location];

			if ([url rangeOfString:@"/"].location == 0)
				download.fileURL = url;
		}

		if (![_request.HTTPMethod isEqualToString:request.httpMethod]) {
			NSMutableURLRequest *copy = [_request mutableCopy];
			[copy setHTTPMethod:request.httpMethod];
			_request = copy;
		}

		return _request;
	}] executeSynked];
}

- (void) downloadFile:(AZDownload *)download {
	//	NSLog(@"Downloading [%@]...", download.fileURL);

	NSUInteger downloadedSize = [download localFileSize];
	if (downloadedSize >= download.totalSize) {
		[download setDownloadedAmount:downloadedSize];
		download.state |= AZErgoDownloadStateDownloaded;
		[download downloadError:nil];
		return;
	}

	BOOL partial = download.supportsPartialDownload;
	if (partial)
		[download setDownloadedAmount:downloadedSize];
	else
		[download setDownloadedAmount:downloadedSize = 0];

	NSString *filePath = [download localFilePath];
	NSError *error = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent]
																 withIntermediateDirectories:YES
																									attributes:Nil
																											 error:&error]) {
		NSString *errorStr = [NSString stringWithFormat:@"Failed to create folder [%@]:\n%@", [filePath stringByDeletingLastPathComponent], [error localizedDescription]];
		NSLog(@"%@", errorStr);
		[download downloadError:errorStr];
	}

	NSOutputStream *stream = [download fileStream:partial];

	@try {
		[stream open];

		AZHTTPRequest *downloadRequest = [AZHTTPRequest actionWithName:@""];
		downloadRequest.url = [download fileFullURL];
		if (partial)
			[downloadRequest setContentRange:downloadedSize to:0];

		downloadRequest.showErrors = NO;
		[[downloadRequest progress:^BOOL(AZHTTPRequest *action, NSData *receivedData) {
			NSUInteger length = [receivedData length];
			if (length) {
				[stream write:[receivedData bytes] maxLength:length];
				[download setDownloadedAmount:download.downloaded + length];
			}

			return NO; // forbidd azhttprequest to collect downloaded data to it's storage
		}] executeSynked];

		if (download.downloaded >= download.totalSize) {
			download.state |= AZErgoDownloadStateDownloaded;
			[download downloadError:nil];
		}
	}
	@finally {
		[stream close];
	}
}

#define __SMART_TASK(__download, __state, __selector)\
({[self download:(__download) block:^(AZDownload *download) {\
[self __selector:download];\
} stateWrap:(__state)];})

- (void) download:(AZDownload *)download block:(void(^)(AZDownload *download))block stateWrap:(AZErgoDownloadState)state {
	download.state |= state;
	@try {
    block(download);
	}
	@finally {
		UNSET_BIT(download.state, state);
		[self notifyStageChange:download];
	}
}

- (void) processTask:(AZDownload *)download {
	download.lastDownloadIteration = [NSDate timeIntervalSinceReferenceDate];

	if (!HAS_BIT(download.state, AZErgoDownloadStateResolved))
		__SMART_TASK(download, AZErgoDownloadStateResolving, resolveData);
	else {
		if (!HAS_BIT(download.state, AZErgoDownloadStateAquired))
			__SMART_TASK(download, AZErgoDownloadStateAquiring, aquireData);
		else
			__SMART_TASK(download, AZErgoDownloadStateDownloading, downloadFile);
	}
}

- (void) detouchTask:(AZDownload *)download {
	@synchronized(_downloads) {
		download.state |= AZErgoDownloadStateProcessing;
	}

	__weak id weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		id strongSelf = weakSelf;

		@try {
			if (strongSelf)
				[strongSelf processTask:download];
		}
		@finally {
			@synchronized(_downloads) {
				UNSET_BIT(download.state, AZErgoDownloadStateProcessing);
			}
		}
	});
}

@end

