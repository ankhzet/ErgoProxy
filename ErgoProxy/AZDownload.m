//
//  AZDownload.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZDownload.h"
#import "AZDownloadParams.h"
#import "AZDownloadParameter.h"
#import "AZJSONUtils.h"
#import "AZStorage.h"

#import "AZDataProxy.h"

#import "AZMultipleTargetDelegate.h"

#define API_AQUIRE_PARAM_URL @"url"
#define API_AQUIRE_PARAM_WIDTH @"width"
#define API_AQUIRE_PARAM_HEIGHT @"height"
#define API_AQUIRE_PARAM_QUALITY @"quality"
#define API_AQUIRE_PARAM_WEBTOON @"isweb"

#define LOCAL_FILE_PATTERN @"%@/%@/%@/%@.%@"

#define API_PUT_PARAM(_p1, _k1, _p2, _k2)\
  ({AZDownloadParameter *param = [_p2 downloadParameter:_k2]; if (param) (_p1)[_k1] = param.value;})

MULTIDELEGATED_INJECT_MULTIDELEGATED(AZDownload)

@implementation AZDownload
@dynamic proxifier, downloadParameters, storage, totalSize, downloaded, fileURL;
@dynamic page, chapter, manga, sourceURL, proxifierHash, scanID;
@synthesize lastDownloadIteration, supportsPartialDownload;
@synthesize state, error, httpError;

- (void) setState:(AZErgoDownloadState)_state {
	if (state == _state)
		return;

	state = _state;
	[self notifyStateChanged];
}

- (void) setDownloadedAmount:(NSUInteger)_downloaded {
	if (self.downloaded == _downloaded)
		return;

	self.downloaded = _downloaded;
	[self notifyProgressChanged];
}

- (BOOL) isBonusChapter {
	return (int)(10.f * (self.chapter - truncf(self.chapter))) > 0;
}

- (NSUInteger) indexHash {
	return (int)(self.chapter * 10) * 1000 + self.page;
}

- (void) downloadError:(id)_error {
	if (_error)
		self.state |= AZErgoDownloadStateFailed;
	else
		UNSET_BIT(self.state, AZErgoDownloadStateFailed);

	self.error = _error;
}

+ (NSArray *) fetchDownloads {
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

	[fetchRequest setEntity:[self entityDescription]];

	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"scanID" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];

	NSError *error = nil;
	NSArray *fetchedObjects = [[AZDataProxy sharedProxy] executeFetchRequest:fetchRequest error:&error];

	if (fetchedObjects != nil)
		for (AZDownload *download in fetchedObjects)
			[download fixState];

	return fetchedObjects;
}

+ (NSArray *) manga:(NSString *)manga hasChapterDownloads:(float)chapter {
	NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"(manga == %@) and (abs(chapter - %lf) < 0.01)", manga, chapter];
	NSArray *fetch = [self filter:filterPredicate limit:0];

	for (AZDownload *download in fetch)
		[download fixState];

	return fetch;
}

- (void) fixState {
	if (state == AZErgoDownloadStateNone) {

		if (self.proxifierHash && self.storage) {
			state |= AZErgoDownloadStateResolved;
		}

		if (!!self.totalSize) {
			state |= AZErgoDownloadStateAquired;
			if (self.downloaded >= self.totalSize)
				state |= AZErgoDownloadStateDownloaded;
		}

		[self notifyStateChanged];
	}
}

@end

@implementation AZDownload (FileDownloadRelated)

- (NSString *) fileFullURL {
	return [[[self.storage fullURL] absoluteString] stringByAppendingString:[self.fileURL substringFromIndex:1]];
}

- (double) percentProgress {
	return self.totalSize ? MIN(MAX((double)self.downloaded / (double)self.totalSize, 0), 1.0) : 0.;
}

- (NSString *) localFilePath {
	NSString *root = PREF_STR(PREFS_COMMON_MANGA_STORAGE);
	if ([root hasSuffix:@"/"])
		root = [root substringToIndex:[root length] - 1];

	NSString *chapterStr = [self isBonusChapter] ? [NSString stringWithFormat:@"%06.1f", self.chapter] : [NSString stringWithFormat:@"%04d", (int)self.chapter];

	NSString *path = [NSString stringWithFormat:
										LOCAL_FILE_PATTERN,
										root,
										self.manga,
										chapterStr,
										[NSString stringWithFormat:@"%04ld", (long)self.page],
										[self.fileURL pathExtension]];

	return path;
}

- (NSUInteger) localFileSize {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *filePath = [self localFilePath];
	if (![fm fileExistsAtPath:filePath])
		return 0;

	NSError *_error = nil;
	NSDictionary *attribs = [fm attributesOfItemAtPath:filePath error:&_error];
	if (!attribs) { // file don't exists?
		NSLog(@"Error while accessing [%@]: %@", filePath, [_error localizedDescription]);
		return 0;
	}
	return [attribs fileSize];
}

- (NSOutputStream *) fileStream:(BOOL)seekToEnd {
	return [[NSOutputStream alloc] initToFileAtPath:[self localFilePath] append:seekToEnd];
}

@end

@implementation AZDownload (Instantiation)

+ (AZDownload *) downloadForURL:(NSURL *)url withParams:(AZDownloadParams *)params {
	AZDownload *download = [self unique:[NSPredicate predicateWithFormat:@"sourceURL = %@", url] initWith:^(AZDownload *instantiated) {
		instantiated.sourceURL = url;
	}];
	download.downloadParameters = params;
	return download;
}

@end

@implementation AZDownload (Proxifying)

- (NSDictionary *) fetchParams:(BOOL)base64 {
	NSMutableDictionary *params = [NSMutableDictionary dictionary];

	NSString *url = [self.sourceURL absoluteString];
	if (base64)
		url = [NSString stringWithFormat:@"@64!%@",[[url dataUsingEncoding:NSASCIIStringEncoding] base64Encoding]];
	else
		url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	NSAssert(!!url, @"URL is nil (%@, %@)!", self.sourceURL, base64 ? @"base-64" : @"percent-encoded");
	params[API_AQUIRE_PARAM_URL] = url;

	//	API_PUT_PARAM(downloadParams, kDownloadParamServer, self.downloadParams, kDownloadParamServer);

	API_PUT_PARAM(params, API_AQUIRE_PARAM_WIDTH, self.downloadParameters, kDownloadParamMaxWidth);
	API_PUT_PARAM(params, API_AQUIRE_PARAM_HEIGHT, self.downloadParameters, kDownloadParamMaxHeight);
	API_PUT_PARAM(params, API_AQUIRE_PARAM_QUALITY, self.downloadParameters, kDownloadParamQuality);
	API_PUT_PARAM(params, API_AQUIRE_PARAM_WEBTOON, self.downloadParameters, kDownloadParamIsWebtoon);

	return params;
}

+ (NSURL *) storageToken:(id)jsonProxifierResponse {
	return [NSURL URLWithString:JSON_S(jsonProxifierResponse, @"storage")];
}

+ (NSString *) hashToken:(id)jsonProxifierResponse {
	return JSON_S(jsonProxifierResponse, @"hash");
}

+ (NSUInteger) scanToken:(id)jsonProxifierResponse {
	return [JSON_I(jsonProxifierResponse, @"scan-id") unsignedIntegerValue];
}

@end

@implementation AZDownload (Validity)

// thnx to http://stackoverflow.com/questions/3848280/catching-error-corrupt-jpeg-data-premature-end-of-data-segment
- (BOOL) isFileCorrupt {
	NSData *data = [NSData dataWithContentsOfFile:[self localFilePath]];

	if (!data || data.length <= 0) return NO;

	if (data.length < 4) return YES;

	NSInteger totalBytes = data.length;
	const char *bytes = (const char*)[data bytes];

	return !(bytes[0] == (char)0xff &&
					bytes[1] == (char)0xd8 &&
					bytes[totalBytes - 2] == (char)0xff &&
					bytes[totalBytes - 1] == (char)0xd9);
}

@end

@implementation AZDownload (Delegation)

- (void) notifyStateChanged {
	[self.md_delegate download:self stateChanged:state];
}

- (void) notifyProgressChanged {
	[self.md_delegate download:self progressChanged:[self percentProgress]];
}

@end
