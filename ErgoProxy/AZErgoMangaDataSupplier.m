//
//  AZErgoMangaDataSupplier.m
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoMangaDataSupplier.h"
#import "AZErgoTemplateProcessor.h"

#import "AZErgoMangaCommons.h"
#import "AZDataProxy.h"

@implementation AZErgoMangaDataSupplier

- (id) getDataByKey:(NSString *)key {
	id data = [super getDataByKey:key];

	if (data)
		return data;

	if ([key isEqualToString:@"title"])
		return LOC_FORMAT(@"ErgoProxy");

	if ([key caseInsensitiveCompare:@"is_fullscreen"]==NSOrderedSame)
		return @([[NSApp delegate] window].isInFullScreenMode);

	return nil;
}


+ (NSArray *) componentsFromAbsolutePath:(NSString *)path {
	path = [path stringByReplacingOccurrencesOfString:[[AZErgoMangaChapter mangaStorage] stringByAppendingString:@"/"] withString:@""];

	NSMutableArray *root = [[path pathComponents] mutableCopy];
	if ([[root firstObject] isEqualToString:@"/"])
		[root removeObject:@"/"];

	NSString *mangaRoot = [root firstObject];
	[root removeObject:mangaRoot];

	NSString *chapterStr = [root firstObject];
	float chapter = [chapterStr floatValue];
	[root removeObjectIdenticalTo:chapterStr];

	NSMutableArray *components = [NSMutableArray new];

	if (mangaRoot)
		[components addObject:mangaRoot];

	if (chapter > 0)
		[components addObject:@(chapter)];

	return components;
}

+ (instancetype) dataWithDirectoryIndex:(NSString *)path {
	NSString *absolutePath = [path stringByReplacingOccurrencesOfString:[AZErgoMangaChapter mangaStorage] withString:@"/manga"];

	NSArray *entries = [AZUtils fetchEntries:path withProperties:@[NSURLIsRegularFileKey, NSURLIsDirectoryKey]];
	NSMutableArray *listing = [NSMutableArray new];
	for (NSString *entry in entries)
		[listing addObject:[NSString stringWithFormat:@"\t<li><a href=\"%@/%@\">%@</a></li>", absolutePath, entry, entry]];

	NSString *html = [NSString stringWithFormat:@"<ul>\n%@\n</ul>\n", [listing componentsJoinedByString:@"\n"]];

	return [[self alloc] initWithDictionary:@{@"content": html}];
}

+ (instancetype) dataWithReader:(NSString *)path {
	NSArray *components = [self componentsFromAbsolutePath:path];
	NSString *mangaRoot = [components firstObject];
	float chapter = [[components lastObject] floatValue];

	if (!(!!mangaRoot && !!chapter))
		return nil;

	NSString *chapterPath = [NSString stringWithFormat:@"%@/%@/%@", [AZErgoMangaChapter mangaStorage], mangaRoot, [AZErgoMangaChapter formatChapterID:chapter]];

	NSArray *entries = [AZUtils fetchFiles:chapterPath];

	NSMutableDictionary *data = [NSMutableDictionary new];

	NSArray *nav =
	@[
		@"<a class='prev' href='javascript:void(0);'> Previous </a>",
		@"<a class='fs' href='javascript:void(0);'> FS </a>",
		@"<a class='preview' href='javascript:void(0);'> Make Preview </a>",
		@"<a class='manhwa' href='javascript:void(0);'> Manhwa Mode </a>",
		@"<a class='prev' href='/manga/{{manga.root}}/{{chapter.id:chapter}}'> Chapter Folder </a>",
		@"<a class='next' href='javascript:void(0);'> Next </a>",
		];

	float lastChapter = [AZErgoMangaChapter lastChapter:mangaRoot];

	AZErgoManga *manga = [AZErgoManga mangaByName:mangaRoot];

	AZErgoMangaProgress *progress = manga.progress;
	progress.chapters = MAX(progress.chapters, lastChapter);

	float prev = progress.chapter;
	BOOL another = ![AZErgoMangaChapter same:chapter as:prev];
	if (another || (progress.page < 1))
		[progress setChapter:(!![entries count]) ? chapter : MAX(chapter, prev) andPage:1];

	if ([AZErgoMangaChapter same:prev as:lastChapter]) {
		if (manga.isDownloaded)
			[manga toggle:YES tagWithGUID:AZErgoTagGroupReaded];
	}

	[[AZDataProxy sharedProxy] saveContext:YES];

	NSWindow *window = [[NSApp delegate] window];
	NSView *view = [window contentView];
	NSSize size = view.frame.size;

	data[@"manga"] = @{
										 @"id": manga.name,
										 @"root": manga.name,
										 @"titles": [@[manga.mainTitle] arrayByAddingObjectsFromArray:[manga additionalTitles]],
										 @"tags": manga.tagNames,
										 @"is_webtoon": @(manga.isWebtoon),

										 @"chapter": @{
												 @"id": @(chapter),
												 },
										 @"page_id": @(MAX(1, MIN(progress.page, [entries count]))),

										 @"scans": entries,

										 };

	data[@"view"] = @{
										@"width": @(size.width),
										@"height": @(size.height),
										};


	data[@"nav"] = [nav componentsJoinedByString:@" | "];

	NSString *html = [AZErgoTextTemplateProcessor processTemplate:@"reader"
																				 withDataSubstitutioner:[self dataSubstitutioner:data]];

	return [[self alloc] initWithDictionary:@{@"content": html,
																						@"title": LOC_FORMAT(@"ErgoProxy"),
																						@"page_title": [NSString stringWithFormat:@"%@ (%@/%@)",manga.mainTitle,@(chapter),@(lastChapter)]
																						}];
}

+ (instancetype) dataWithProgress:(NSString *)path {
	NSMutableArray *components = [[path pathComponents] mutableCopy];

	NSUInteger page = [[components lastObject] integerValue];
	[components removeLastObject];

	float chapter = [[components lastObject] floatValue];
	[components removeLastObject];

	NSString *mangaRoot = [components lastObject];

	NSDictionary *result;
	AZErgoManga *manga = [AZErgoManga mangaByName:mangaRoot];
	if (!!manga) {
		[manga.progress setChapter:chapter andPage:page];
		result = @{@"result": @"ok"};
	} else
		result = @{@"result": @"err", @"message": LOC_FORMAT(@"Manga \"%@\" not found", mangaRoot)};

	return [[self alloc] initWithDictionary:result];
}

@end
