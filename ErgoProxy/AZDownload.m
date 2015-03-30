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

#import "AZErgoMangaCommons.h"

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
@dynamic page, chapter, sourceURL, proxifierHash, scanID, lastDownloadIteration;
@dynamic forManga, updateChapter;
@synthesize supportsPartialDownload;
@synthesize state, error, httpError;

- (void) setState:(AZErgoDownloadState)_state {
	if (state == _state)
		return;

	if (HAS_BIT(_state, AZErgoDownloadStateDownloaded) && !HAS_BIT(state, AZErgoDownloadStateDownloaded)) {
		[[AZDataProxy sharedProxy] securedTransaction:^(NSManagedObjectContext *context, BOOL *propagateChanges) {
			AZErgoMangaProgress *p = self.forManga.progress;
			[p setChapters:MAX(p.chapters, self.chapter)];
			[p setUpdated:[NSDate new]];

			self.proxifierHash = nil;
		}];
	}

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

- (BOOL) isFinished {
	NSUInteger total = self.totalSize;
	return (!!total) && (self.downloaded >= total);
}

- (BOOL) isUnfinished {
	NSUInteger total = self.totalSize;
	return (!!total) && (self.downloaded < total);
}

- (BOOL) downloadComplete:(BOOL *)isStarted {
	NSUInteger total = self.totalSize;
	BOOL started = !!total;

	if (isStarted != NULL)
		*isStarted = started;

	return started && (self.downloaded >= total);
}

- (NSUInteger) indexHash {
	return (int)(self.chapter * 10000) + self.page;
}

- (NSComparisonResult) compare:(AZDownload *)other {
	NSComparisonResult r = (self.forManga == other.forManga) ? NSOrderedSame : [self.forManga compare:other.forManga];
	if (r == NSOrderedSame) {
		r = SIGN(self.chapter - other.chapter);

		if (r == NSOrderedSame)
			r = SIGN(self.page - other.page);
	}

	return r;
}

- (NSComparisonResult) compareState:(AZDownload *)other {
	return SIGN(state - other.state);
}

- (void) downloadError:(id)_error {
	if (_error)
		self.state |= AZErgoDownloadStateFailed;
	else {
		UNSET_BIT(self.state, AZErgoDownloadStateFailed);
		self.httpError = 0;
	}

	self.error = _error;
}

+ (NSUInteger) manga:(NSString *)manga countChapterDownloads:(float)chapter {
	NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"(abs(chapter - %lf) < 0.01) and (forManga.name == %@)", chapter, manga];
	return [self countOf:filterPredicate];
}

+ (NSArray *) manga:(NSString *)manga hasChapterDownloads:(float)chapter {
	NSArray *fetch = [self all:@"(abs(chapter - %lf) < 0.01) and (forManga.name == %@)", chapter, manga];

	for (AZDownload *download in fetch)
		if (download.state == AZErgoDownloadStateNone)
			[download fixState];

	return fetch;
}

+ (NSArray *) mangaDownloads:(NSString *)manga limit:(NSUInteger)limit {
	NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"forManga.name == %@", manga];

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[self entityDescription]];

	NSSortDescriptor *sortChapter = [NSSortDescriptor sortDescriptorWithKey:@"chapter" ascending:NO];

	[fetchRequest setPredicate:filterPredicate];
	[fetchRequest setSortDescriptors:@[sortChapter]];

	if (limit)
		[fetchRequest setFetchLimit:limit];

	NSError *error = nil;
	NSArray *fetchedObjects = [[AZDataProxy sharedProxy] executeFetchRequest:fetchRequest error:&error];

	return (limit == 1) ? [fetchedObjects lastObject] : fetchedObjects;
}

- (void) fixState {
	AZErgoDownloadState new = state;
	if (new == AZErgoDownloadStateNone) {

		if (self.proxifierHash && self.storage) {
			new |= AZErgoDownloadStateResolved;
		}

		NSUInteger size = self.totalSize;
		if (!!size) {
			new |= AZErgoDownloadStateAquired;
			if (self.downloaded >= size)
				new |= AZErgoDownloadStateDownloaded;
		}

		if (new != state)
			self.state = new;
	}
}

- (void) reset:(AZDownloadParams *)withParams {
	self.proxifierHash = nil;
	self.storage = nil;
	self.fileURL = nil;
	self.lastDownloadIteration = 0;
	self.downloaded = 0;
	self.totalSize = 0;

	if (!!withParams)
		self.downloadParameters = withParams;

	[self downloadError:nil];

	UNSET_BIT(state, AZErgoDownloadStateResolved);
	UNSET_BIT(state, AZErgoDownloadStateAquired);
	UNSET_BIT(state, AZErgoDownloadStateDownloaded);

	[self notifyStateChanged];
}

@end

@implementation AZDownload (FileDownloadRelated)

- (NSString *) fileFullURL {
	return [[self.storage fullURL] stringByAppendingString:[self.fileURL substringFromIndex:1]];
}

- (double) percentProgress {
	return self.totalSize ? MIN(MAX((double)self.downloaded / (double)self.totalSize, 0), 1.0) : 0.;
}

- (NSString *) localFilePath {
	AZErgoManga *manga = self.forManga;
	NSString *mangaFolder = [manga mangaFolder];
	NSString *chapterFolder = [AZErgoMangaChapter formatChapterID:self.chapter];
	NSString *fileName = [NSString stringWithFormat:@"%04ld.%@",(long)self.page,[self.fileURL pathExtension]];

	if (!((!!mangaFolder) && (!!chapterFolder) && (!!fileName)))
		NSAssert(false, @"Empty params!");

	NSString *path = [NSString pathWithComponents:@[mangaFolder, chapterFolder, fileName]];
	return path;
}

- (NSUInteger) localFileSize {
	return [NSFileManager fileSize:self.localFilePath];
}

- (NSOutputStream *) fileStream:(BOOL)seekToEnd {
	return [[NSOutputStream alloc] initToFileAtPath:[self localFilePath] append:seekToEnd];
}

@end

@implementation AZDownload (Instantiation)

+ (AZDownload *) downloadForURL:(NSString *)url withParams:(AZDownloadParams *)params {
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

	NSString *url = self.sourceURL;
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

+ (NSString *) storageToken:(id)jsonProxifierResponse {
	return JSON_S(jsonProxifierResponse, @"storage");
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
