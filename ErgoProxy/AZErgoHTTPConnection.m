//
//  AZErgoHTTPConnection.m
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoHTTPConnection.h"
#import "HTTPLogging.h"

#import "HTTPDynamicFileResponse.h"
#import "AZErgoHTMLResponse.h"
#import "HTTPErrorResponse.h"
#import "HTTPRedirectResponse.h"

#import "AZErgoSubstitutioner.h"
#import "AZErgoTemplateProcessor.h"
#import "AZErgoMangaDataSupplier.h"

static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

#define _IDX(_idx) ({(int)(_idx * 10);})

@implementation AZErgoHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	NSString *filePath = [self filePathForURI:path];

	NSString *documentRoot = [config documentRoot];

	if (![filePath hasPrefix:documentRoot])
		return nil;

	NSString *relativePath = [filePath substringFromIndex:[documentRoot length]];

	NSMutableArray *components = [[relativePath pathComponents] mutableCopy];
	if ([[components firstObject] isEqualToString:@"/"])
		[components removeObject:@"/"];

	NSString *action = [[[[components firstObject]
											 stringByReplacingOccurrencesOfString:@"-" withString:@" "]
											capitalizedString]
											stringByReplacingOccurrencesOfString:@" " withString:@""];

	SEL selector = NSSelectorFromString([NSString stringWithFormat:@"serve:action%@:", [action capitalizedString]]);
	if ([self respondsToSelector:selector]) {
		components = ([components count] > 1) ? (id)[components subarrayWithRange:NSMakeRange(1, [components count] - 1)] : nil;

		relativePath = [components componentsJoinedByString:@"/"] ?: @"/";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		id response = [self performSelector:selector withObject:method withObject:relativePath];
#pragma clang diagnostic pop

		BOOL isResponse = [response conformsToProtocol:@protocol(HTTPResponse)];
		BOOL isSupplier = [response conformsToProtocol:@protocol(AZErgoSubtitutionerDataSupplier)];
		if (!isResponse && isSupplier)
			response = [self serveDynamicContent:response];

		return response;
	}

	BOOL isDir = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir]) {
		if (!isDir)
			return [[HTTPAsyncFileResponse alloc] initWithFilePath:filePath forConnection:self];

		return (id)[self serveDynamicContent:[AZErgoMangaDataSupplier dataWithDirectoryIndex:relativePath]];
	}


	return [super httpResponseForMethod:method URI:path];
}

- (id<HTTPResponse>) serveDynamicContent:(AZErgoMangaDataSupplier *)dataSupplier {
	return dataSupplier
	? [AZErgoHTMLResponse responseWithContent:[AZErgoSubstitutioner substitutionerWithDataSupplier:dataSupplier]
																	andMarkup:[self filePathForURI:@"/markup.tpl"]
															forConnection:self]

	: [[HTTPErrorResponse alloc] initWithErrorCode:404];
}

- (id) serve:(NSString *)method actionManga:(NSString *)relativePath {
	NSArray *parts = [relativePath pathComponents];

	NSArray *components = [AZErgoMangaDataSupplier componentsFromAbsolutePath:relativePath];
	if (([components count] == 2) && ([parts count] == 2))
		return [[HTTPRedirectResponse alloc] initWithPath:[NSString stringWithFormat:@"/reader/%@/", relativePath]];

	relativePath = [[AZErgoMangaDataSupplier mangaStorage] stringByAppendingPathComponent:relativePath];

	BOOL isDir = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:relativePath isDirectory:&isDir]) {
		if (!isDir)
			return [[HTTPAsyncFileResponse alloc] initWithFilePath:relativePath forConnection:self];

		return [AZErgoMangaDataSupplier dataWithDirectoryIndex:relativePath];
	}

	return nil;
}

- (id) serve:(NSString *)method actionReader:(NSString *)relativePath {
	NSDictionary *params = [self parseGetParams];
	int delta = [params[@"delta"] intValue];

	if (!!delta)
		return [self navigateChapter:relativePath withDelta:delta];

	return [AZErgoMangaDataSupplier dataWithReader:relativePath];
}

- (id) navigateChapter:(NSString *)absolutePath withDelta:(int)delta {
	NSArray *components = [AZErgoMangaDataSupplier componentsFromAbsolutePath:absolutePath];
	NSString *manga = components[0];

	int chapter = _IDX([components[1] floatValue]);

	NSArray *chapters = [AZErgoMangaDataSupplier fetchChapters:manga];

	NSNumber *prev = nil, *next = nil;

	for (NSNumber *ch in chapters) {
		int f = _IDX([ch floatValue]);

		if (f < chapter)
			if (f > [prev intValue])
				prev = @(f);

		if (f > chapter)
			if (f < (next ? [next intValue] : MAXFLOAT))
				next = @(f);
	}

	int old = chapter;

	if (delta > 0) {
		chapter = next ? [next intValue] : chapter;
		if (chapter == old) {
			chapter += _IDX(1);
		}
	}
	if (delta < 0) chapter = prev ? [prev intValue] : chapter;

	float chap = (chapter / 10.f);
	return [[HTTPRedirectResponse alloc] initWithPath:[NSString stringWithFormat:@"/reader/%@/%@", manga, @(chap)]];
}

@end


