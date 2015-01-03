//
//  AZErgoMangaDataSupplier.m
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoMangaDataSupplier.h"
#import "AZErgoTemplateProcessor.h"


@implementation AZErgoMangaDataSupplier

+ (NSArray *) componentsFromAbsolutePath:(NSString *)path {
	path = [path stringByReplacingOccurrencesOfString:[PREF_STR(PREFS_COMMON_MANGA_STORAGE) stringByAppendingString:@"/"] withString:@""];

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

+ (NSArray *) fetchChapters:(NSString *)manga {
	NSArray *dirs = [AZUtils fetchDirs:[[self mangaStorage] stringByAppendingPathComponent:manga]];

	NSMutableSet *err = [NSMutableSet new];

	NSCharacterSet *nonNumeric = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
	NSMutableArray *sorted = [[dirs sortedArrayUsingComparator:^NSComparisonResult(NSString *chName1, NSString *chName2) {
		if ([chName1 rangeOfCharacterFromSet:nonNumeric].location != NSNotFound) {
			[err addObject:chName1];
			return NSOrderedAscending;
		}

		return [@([chName2 floatValue]) compare:@([chName1 floatValue])];
	}] mutableCopy];

	for (id chapter in err)
		[sorted removeObject:chapter];

	return sorted;
}

+ (NSString *)mangaStorage {
	return PREF_STR(PREFS_COMMON_MANGA_STORAGE);
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (!(self = [self init]))
		return self;

	self->data = dictionary;
	return self;
}

+ (instancetype) dataWithDirectoryIndex:(NSString *)path {
	NSString *absolutePath = [path stringByReplacingOccurrencesOfString:[self mangaStorage] withString:@"/manga"];

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

	NSString *chapterPath = [NSString stringWithFormat:@"%@/%@/%@", [self mangaStorage], mangaRoot, [AZErgoSubstitutioner formatChapterID:chapter]];

	NSArray *entries = [AZUtils fetchEntries:chapterPath withProperties:@[NSURLIsRegularFileKey]];

	NSMutableDictionary *data = [NSMutableDictionary new];

	NSArray *nav =
	@[
		@"<a class='prev' href='javascript:void(0);'> Previous </a>",
		@"<a class='fs' href='javascript:void(0);'> FS </a>",
		@"<a class='preview' href='javascript:void(0);'> Make Preview </a>",
		@"<a class='manhwa' href='javascript:void(0);'> Manhwa Mode </a>",
		@"<a class='prev' href='/manga/{{manga_root}}/{{chapter:chapter}}'> Chapter Folder </a>",
		@"<a class='next' href='javascript:void(0);'> Next </a>",
		];

	data[@"scan_list"] = entries;
	data[@"page_id"] = @(1);
	data[@"chapter_id"] = @(chapter);
	data[@"manga_id"] = @(112);
	data[@"manga_root"] = mangaRoot;
	data[@"manga_titles"] = @[mangaRoot];

	data[@"nav"] = [nav componentsJoinedByString:@" | "];

	AZErgoTextTemplateProcessor *processor = [[AZErgoTextTemplateProcessor alloc] init];

	NSString *tplPath = [[NSBundle mainBundle] pathForResource:@"reader" ofType:@"tpl" inDirectory:@"web"];
	NSString *template = [NSString stringWithContentsOfFile:tplPath encoding:NSUTF8StringEncoding error:nil];

	NSString *html = [processor processString:template withDataSubstitutioner:[AZErgoSubstitutioner substitutionerWithDataSupplier:[[AZErgoMangaDataSupplier alloc] initWithDictionary:data]]];

	return [[self alloc] initWithDictionary:@{@"content": html, @"title": @"this is title"}];
}

- (id) getDataByKey:(NSString *)key {
	key = [key lowercaseString];

	if ([data objectForKey:key])
		return [data objectForKey:key];

	if ([key isEqualToString:@"title"])
		return @"This is a title";
	
	return nil;
}

@end
