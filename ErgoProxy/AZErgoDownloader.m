//
//  AZErgoDownloader.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloader.h"

#import "AZDownload.h"
#import "AZStorage.h"
#import "AZErgoAPIRequest.h"

#import "AZProxifier.h"
#import "AZErgoAPIRequest.h"
#import "AZDownloader.h"


@interface AZErgoDownloader ()
@end

@implementation AZErgoDownloader (Downloads)

- (void) notifyStageChange:(AZDownload *)download {
	if (self.delegate)
		[self.delegate downloader:self readyForNextStage:download];
}

- (void) resolveData:(AZDownload *)download {
	AZProxifier *proxifier = download.proxifier;

	AZDownloader *_downloader = [proxifier downloaderForURL:download.sourceURL];

	AZErgoAPIRequest *proxifyRequest = [AZErgoAPIRequest actionWithName:@"aquire"];
	proxifyRequest.serverURL = proxifier.url;
	[proxifyRequest setParameters:[download fetchParams]];
	proxifyRequest.showErrors = NO;

	[[[proxifyRequest success:^(AZHTTPRequest *request, id *data) {
		AZDownloader *downloader = _downloader;
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
		[download downloadError:nil];
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		[download downloadError:[NSString stringWithFormat:@"Download data resolve failed: %@", response]];
		return YES;
	}] executeSynked];
}

- (void) aquireFailReason:(AZDownload *)download {
	AZErgoAPIRequest *request = [AZErgoAPIRequest actionWithName:@"proxy"];
	request.serverURL = [download.storage fullURL];
	request.simulateHeadRequest = YES;
	[request setParameters:@{@"data": download.proxifierHash}];
	[request error:^BOOL(AZHTTPRequest *action, NSString *response) {
//		NSLog(@"%@", response);
		[download downloadError:[NSString stringWithFormat:@"Download data aquire failed: %@", response]];
		return NO;
	}];
}

- (void) aquireData:(AZDownload *)download {
//	NSLog(@"Aquiring [%@]...", download.sourceURL);

	download.fileURL = nil;

	AZErgoAPIRequest *request = [AZErgoAPIRequest actionWithName:@"proxy"];
	request.serverURL = [download.storage fullURL];
	request.httpMethod = @"HEAD";
	request.acceptEmptyResponseAsSuccess = YES;
	request.showErrors = NO;
	[request setParameters:@{@"data": download.proxifierHash}];
	[[[[request success:^BOOL(AZHTTPRequest *_request, __autoreleasing id *data) {
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

	BOOL partial = download.supportsPartialDownload;
	NSUInteger downloadedSize = 0;
	if (partial) {
		downloadedSize = [download localFileSize];
		download.downloaded = downloadedSize;
	}

	if (download.downloaded >= download.totalSize) {
		download.state |= AZErgoDownloadStateDownloaded;
		[download downloadError:nil];
		return;
	}

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
				download.downloaded += length;
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
    download.state ^= state;
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

@end

@implementation AZErgoDownloader

- (void) detouchTask:(AZDownload *)download {
	download.state |= AZErgoDownloadStateProcessing;
	__weak id weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		id strongSelf = weakSelf;
		if (strongSelf) {
			@try {
				[strongSelf processTask:download];
			}
			@finally {
				download.state ^= AZErgoDownloadStateProcessing;
			}
		}
	});
}

@end


