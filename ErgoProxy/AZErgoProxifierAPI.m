//
//  AZErgoProxifierAPI.m
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoProxifierAPI.h"
#import "AZErgoAPIRequest.h"
#import "AZDownload.h"
#import "AZProxifier.h"
#import "AZStorage.h"
#import "AZErgoDownloader.h"
#import "AZErgoManga.h"

#import "AZDownloadSpeedWatcher.h"
#import "AZDataProxy.h"

#import "AZJSONUtils.h"

@implementation AZErgoProxifierAPI

- (id) action:(NSString *)actionName {
	AZHTTPRequest *action = [AZErgoAPIRequest actionWithName:actionName];
	action.showErrors = NO;
	return action;
}

#pragma mark - Downloads

- (void) make:(AZDownload *)download error:(NSString *)error {
	NSString *sequence = (++download.httpError > 1) ? LOC_FORMAT(@" (x%lu)", download.httpError) : @"";
	download.error = LOC_FORMAT(@"Download error%@: %@", sequence, error);
}

- (void) aquireFailReason:(AZDownload *)download onRequest:(AZErgoAPIRequest *)request {
//	request.simulateHeadRequest = YES;

	request.httpMethod = HTTP_HEAD;
	[[[request error:^BOOL(AZHTTPRequest *action, NSString *response) {
		DDLogVerbose(@"Aquire error, headers: %@", [action.response allHeaderFields]);
		DDLogVerbose(@"%@", response);

		if ([response isKindOfClass:[NSString class]] && [response isEqualToString:@"Whoa?"]) {
			download.proxifierHash = nil;
			download.storage = nil;
			UNSET_BIT(download.state, AZErgoDownloadStateResolved);
			response = LOC_FORMAT(@"Hash encoding doesn't match server version.");
		} else
			response = [[response description] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];

		[self make:download error:response];

		return NO;
	} firstly:YES] success:^BOOL(AZHTTPRequest *action, __autoreleasing id *data) {
//		NSDictionary *headers = [action.response allHeaderFields];
//		NSLog(@"Headers: %@", headers);

		if ([*data isKindOfClass:[NSData class]]) {
			NSString *s = [[NSString alloc] initWithData:*data encoding:NSUTF8StringEncoding], *t;

			id json = [NSJSONSerialization JSONObjectWithData:*data options:0 error:nil];

			if ((t = JSON_S(json, @"data")))
				s = [t stringByReplacingOccurrencesOfString:@"\n" withString:@" "];

			NSString *contentType = [[action.response contentType] lowercaseString];
			[self make:download error:s ?: ([contentType isLike:@"*image*"] ? LOC_FORMAT(@"No error") : LOC_FORMAT(@"Unknown response type: %@", contentType))];
		}
		return NO;
	} firstly:YES] executeSynked];
}

- (BOOL) resolveStorage:(AZDownload *)download {
	AZProxifier *proxifier = download.proxifier;

	AZErgoAPIRequest *proxifyRequest = [self action:@"aquire"];
	proxifyRequest.serverURL = [NSURL URLWithString:proxifier.url];
	proxifyRequest.parameters = [download fetchParams:!!download.httpError];

	[[[proxifyRequest success:^(AZHTTPRequest *request, id *data) {
		download.storage = [proxifier storageWithURL:[AZDownload storageToken:*data]];
		download.proxifierHash = [AZDownload hashToken:*data];
		download.scanID = [AZDownload scanToken:*data];
		download.state |= AZErgoDownloadStateResolved;
		download.error = nil;
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		[self make:download error:response];
		return YES;
	}] executeSynked];

	return HAS_BIT(download.state, AZErgoDownloadStateResolved);
}

- (BOOL) aquireScanData:(AZDownload *)download {
	if (!(download.proxifierHash && download.storage)) {
		UNSET_BIT(download.state, AZErgoDownloadStateResolved);
		return NO;
	}

	download.fileURL = nil;

	AZErgoAPIRequest *request = [self action:@"proxy"];
	request.serverURL = [NSURL URLWithString:[download.storage fullURL]];
	request.httpMethod = HTTP_HEAD;
	request.acceptEmptyResponseAsSuccess = YES;
	request.timeout = 30;
	[request setParameters:@{@"data": download.proxifierHash}];
	[[[[request success:^BOOL(AZHTTPRequest *_request, id *data) {
		if (!download.fileURL) {
			[self aquireFailReason:download onRequest:request];
			return YES;
		}

		download.totalSize = [_request.response contentLength];
		download.supportsPartialDownload = [_request.response serverSupportsPartialDownload];
		download.state |= AZErgoDownloadStateAquired;
		download.error = nil;
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		[self make:download error:response];
		return YES;
	}] processRedirects:^NSURLRequest *(NSURLConnection *_connection, NSURLRequest *URLRequest, id response) {
		AZDownload *_download = download;// [download inContext:[AZDataProxy contextForCurrentThread]];

		if ([response isRedirectResponse]) {
			NSString *url = [[response locationHeader] cropHTTPParameters];

			if (url.isRelativeURL) {
				_download.fileURL = url;
				_download.error = nil;
			} else {
				NSString *reason = [response allHeaderFields][@"X-Redirect-Reason"];
				if (!!reason) {
					[self make:_download error:reason];

					if ([reason isCaseInsensitiveLike:@"Damaged image"]) {
						_download.fileURL = url;
					}
				}
			}
		}

		if (![URLRequest.HTTPMethod isEqualToString:request.httpMethod]) {
			NSMutableURLRequest *copy = [URLRequest mutableCopy];
			[copy setHTTPMethod:request.httpMethod];
			URLRequest = copy;
		} else {
			if (!response) {
				if (_download.httpError++ > 2) {
					[_download reset:nil];
					[_download.proxifier registerForDownloading:_download];
				}
			}
		}

//		if ([_download hasChanges])
//			[_download.managedObjectContext save:nil];

		return URLRequest;
	}] executeSynked];

	return HAS_BIT(download.state, AZErgoDownloadStateAquired);
}

- (BOOL) downloadScan:(AZDownload *)download {
	if (![self assumeDirsExists:download])
		return NO;

	NSUInteger downloadedSize = [download localFileSize];
	if (downloadedSize >= download.totalSize) {
		[download setDownloadedAmount:downloadedSize];
		download.state |= AZErgoDownloadStateDownloaded;
		download.error = nil;
		return YES;
	}

	BOOL partial = download.supportsPartialDownload;
	[download setDownloadedAmount:partial ? downloadedSize : (downloadedSize = 0)];
	
	NSOutputStream *stream = [download fileStream:partial];

	@try {
		[stream open];

		AZHTTPRequest *downloadRequest = [AZHTTPRequest actionWithName:@""];
		downloadRequest.url = [download fileFullURL];
		if (partial)
			[downloadRequest setContentRange:downloadedSize to:0];

		downloadRequest.timeout = 60;
		downloadRequest.showErrors = NO;
		[[[downloadRequest progress:^BOOL(AZHTTPRequest *action, NSData *receivedData) {
			if (action.response.isOkResponse) {
				NSUInteger length = [receivedData length];
				if (length) {
					if ([stream write:[receivedData bytes] maxLength:length] < 0) {
						[self make:download
								 error:LOC_FORMAT(@"Stream write error for \"%@\"", [download localFilePath])];

						[action cancel];
						return NO;
					}
					[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
						AZDownload *detouched = [download inContext:context];
						detouched.downloadedAmount = detouched.downloaded + length;
						detouched.error = nil;
					}];

					[[AZDownloadSpeedWatcher sharedSpeedWatcher] downloaded:length];
				}
			} else
				if (action.response.statusCode == 416) {
					[download reset:nil];
					[action cancel];
				} else
					[self make:download
							 error:LOC_FORMAT(@"Unexpected response code: %@", [action.response localizedStatusString])];

			AZErgoDownloader *downloader = [[AZProxifier sharedProxifier] downloaderForURL:download.sourceURL];
			if ([downloader paused] || ![downloader running])
				[action cancel];

			return NO; // forbidd azhttprequest to collect downloaded data to it's storage
		}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
			if ([action.response isNotFoundResponse])
				UNSET_BIT(download.state, AZErgoDownloadStateAquired);

			return YES;
		}] executeSynked];

		if (download.downloaded >= download.totalSize) {
			download.state |= AZErgoDownloadStateDownloaded;
			download.error = nil;
		}
	}
	@finally {
		[stream close];
	}

	return HAS_BIT(download.state, AZErgoDownloadStateDownloaded);
}

- (BOOL) assumeDirsExists:(AZDownload *)download {
	NSString *filePath = [download localFilePath];

	if (![NSFileManager isAccesibleForWriting:filePath]) {
		[self make:download error:LOC_FORMAT(@"Path not accesible for writing: %@", filePath)];
		return NO;
	}

	NSError *error = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent]
																 withIntermediateDirectories:YES
																									attributes:Nil
																											 error:&error]) {

		[self make:download
				 error:LOC_FORMAT(@"Failed to create folder [%@]:\n%@",
													[filePath stringByDeletingLastPathComponent],
													[error localizedDescription])];
		return NO;
	}

	return YES;
}

- (BOOL) downloadPreview:(AZErgoManga *)manga atOrigin:(NSString *)serverURL {
	NSString *fileName = [manga previewFile];
	if (!fileName)
		return NO;

	if (![NSFileManager isAccesibleForWriting:fileName])
		return NO;

	NSError *error = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:[fileName stringByDeletingLastPathComponent]
																 withIntermediateDirectories:YES
																									attributes:Nil
																											 error:&error])
		return NO;

	NSUInteger downloadedSize = [NSFileManager fileSize:fileName];

	BOOL partial = YES;

	downloadedSize = partial ? downloadedSize : 0;

	NSOutputStream *stream = [[NSOutputStream alloc] initToFileAtPath:fileName append:partial];

	__block BOOL success = NO;
	@try {
		[stream open];

		AZHTTPRequest *downloadRequest = [AZHTTPRequest actionWithName:@""];
		downloadRequest.url = [[serverURL stringByAppendingPathComponent:manga.preview] stringByReplacingOccurrencesOfString:@"//" withString:@"/"];

		if (partial)
			[downloadRequest setContentRange:downloadedSize to:0];

		downloadRequest.showErrors = NO;

		[[[downloadRequest progress:^BOOL(AZHTTPRequest *action, NSData *receivedData) {
			if (action.response.isOkResponse) {
				NSUInteger length = [receivedData length];
				if (length) {
					if ([stream write:[receivedData bytes] maxLength:length] < 0) {
						DDLogError(@"%@",LOC_FORMAT(@"Stream write error for \"%@\"", fileName));
						[action cancel];
						return NO;
					}
					[[AZDownloadSpeedWatcher sharedSpeedWatcher] downloaded:length];
				}
			} else
				if (action.response.statusCode == 416) {
					[[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
					[action cancel];
				} else
					DDLogError(@"%@", LOC_FORMAT(@"Unexpected response code: %@", [action.response localizedStatusString]));

			// place to put pausing code

			return NO; // forbidd azhttprequest to collect downloaded data to it's storage
		}] success:^BOOL(AZHTTPRequest *action, __autoreleasing id *data) {
			return success = YES;
		}] executeSynked];
	}
	@finally {
		[stream close];
	}

	return success;
}

@end
