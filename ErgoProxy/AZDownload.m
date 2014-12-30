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

#import "AZDataProxyContainer.h"
#import "AZSynkEnabledStorage.h"

#define API_AQUIRE_PARAM_URL @"url"
#define API_AQUIRE_PARAM_WIDTH @"width"
#define API_AQUIRE_PARAM_HEIGHT @"height"
#define API_AQUIRE_PARAM_QUALITY @"quality"
#define API_AQUIRE_PARAM_WEBTOON @"isweb"

#define LOCAL_FILE_PATTERN @"%@/%@/%@/%@.%@"

#define API_PUT_PARAM(_p1, _k1, _p2, _k2)\
  ({AZDownloadParameter *param = [_p2 downloadParameter:_k2]; if (param) (_p1)[_k1] = param.value;})

@implementation AZDownload
@dynamic proxifier, downloadParameters, storage, totalSize, downloaded;
@synthesize lastDownloadIteration, fileURL, supportsPartialDownload;
@dynamic page, chapter, manga, sourceURL, proxifierHash, scanID;
@synthesize stateListener, state, error, httpError;


- (void) setState:(AZErgoDownloadState)_state {
	if (state == _state)
		return;

	state = _state;
	if (stateListener)
		[stateListener download:self stateChanged:state];
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
	self.state = _error ? (state | AZErgoDownloadStateFailed) : (state ^ AZErgoDownloadStateFailed);
	self.error = _error;
}

+ (NSArray *) fetchDownloads {
	NSManagedObjectContext *context = [[AZDataProxyContainer getInstance] managedObjectContext];

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

	[fetchRequest setEntity:[self entityDescription]];

	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"scanID" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];

	NSError *_error = nil;
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&_error];
	if (fetchedObjects == nil) {
		// Handle the error
	} else {
		for (AZDownload *download in fetchedObjects) {
			if (download.state == AZErgoDownloadStateNone) {
				if (download.proxifierHash && download.storage) {
					download.state |= AZErgoDownloadStateResolved;
					if (download.totalSize) {
						download.state |= AZErgoDownloadStateAquired;
						if (download.downloaded >= download.totalSize)
							download.state |= AZErgoDownloadStateDownloaded;
					}
				}
			}
		}
	}

	return fetchedObjects;
}

+ (NSArray *) manga:(NSString *)manga hasChapterDownloads:(float)chapter {
	NSArray *fetch = [self filter:[NSPredicate predicateWithFormat:@"(manga like[c] %@) and (abs(chapter - %lf) < 0.01)", manga, chapter]
													limit:0];

	for (AZDownload *download in fetch) {
		if (download.state == AZErgoDownloadStateNone) {
			AZErgoDownloadState state = AZErgoDownloadStateNone;

			if (download.proxifierHash && download.storage) {
				state |= AZErgoDownloadStateResolved;
			}

			if (download.totalSize) {
				state |= AZErgoDownloadStateAquired;
				if (download.downloaded >= download.totalSize)
					state |= AZErgoDownloadStateDownloaded;
			}

			download.state = state;
		}
	}

	return fetch;
}

@end

@implementation AZDownload (FileDownloadRelated)

- (NSString *) fileFullURL {
	return [[[self.storage fullURL] absoluteString] stringByAppendingString:[self.fileURL substringFromIndex:1]];
}

- (void) notifyProgressChanged {
	if (stateListener)
		[stateListener download:self progressChanged:[self percentProgress]];
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

- (NSDictionary *) fetchParams {
	NSMutableDictionary *params = [NSMutableDictionary dictionary];

	params[API_AQUIRE_PARAM_URL] = [[self.sourceURL absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

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

