//
//  AZErgoManga.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaCommons.h"
#import "AZDataProxy.h"

#import "AZErgoUpdateChapter.h"
#import "AZErgoChapterProtocol.h"
#import "AZErgoUpdateChapterMapping.h"

@implementation AZErgoManga {
	AZErgoMangaProgress *__progress;
}

@dynamic annotation;
@dynamic name;
@dynamic tags;
@dynamic titles;
@dynamic progress;
@dynamic order;
@dynamic downloads;
@dynamic preview;
@dynamic fsCheck;
@dynamic chapterMappings;

+ (instancetype) mangaWithName:(NSString *)name {
	return [self unique:AZF_ALL_OF(@"name ==[c] %@", name) initWith:^(AZErgoManga *entity) {
		entity.name = name;
		[AZErgoMangaTitle mangaTitile:[name capitalizedString]].manga = entity;
	}];
}

+ (instancetype) mangaByName:(NSString *)name {
	return [self any:@"name ==[c] %@", name];
}

+ (NSArray *) allDownloaded:(BOOL)downloaded {
	AZErgoMangaTag *tag = [AZErgoMangaTag tagByGuid:@(AZErgoTagGroupDownloaded)];
	NSArray *allDownloaded = [tag.manga allObjects];

	if (downloaded)
		return allDownloaded;

	NSMutableArray *all = [[AZErgoManga all] mutableCopy];
	[all removeObjectsInArray:allDownloaded];

	return all;
}

- (NSComparisonResult) compare:(AZErgoManga *)another {
	return [self.mainTitle compare:another.mainTitle];
}

- (NSComparisonResult) orderedCompare:(AZErgoManga *)another {
	return (!another) ? NSOrderedSame : SIGN(self.order - another.order);
}

- (NSString *) description {
	NSString *title = self.mainTitle;
	NSString *name = self.name;

	return ([title caseInsensitiveCompare:name] == NSOrderedSame)
	? title
	: [NSString stringWithFormat:@"%@ (%@)", self.mainTitle, self.name];
}

- (NSString *) mangaFolder {
	NSString *root = PREF_STR(PREFS_COMMON_MANGA_STORAGE);
	if (![root hasPrefix:@"/"])
		root = [@"/" stringByAppendingString:root];

	NSString *path = [root stringByAppendingPathComponent:self.name];

	return path;
}

- (NSString *) previewFile {
	if (!self.preview)
		return nil;

	NSString *storageFolder = [self mangaFolder];
	NSString *previewFile = [NSString stringWithFormat:@"%@.%@",self.name,[self.preview pathExtension]];

	previewFile = [storageFolder stringByAppendingPathComponent:previewFile];
	return previewFile;
}

- (BOOL) hasToCheckFS {
	if (!self.fsCheck)
		return YES;

	NSDate *modified = [NSFileManager fileModificationDate:[self mangaFolder]];
	if (!modified)
		return NO;

	return [modified timeIntervalSinceReferenceDate] > [self.fsCheck timeIntervalSinceReferenceDate];
}

- (void) checkFSWithCompletion:(void(^)(AZErgoManga *manga))complete {
	BOOL asynk = !!complete;

	if (![NSFileManager isAccesibleForWriting:[self mangaFolder]]) {
		self.fsCheck = [NSDate date];

		if (asynk)
			dispatch_async_at_background(^{complete(self);});
	} else {

		dispatch_block_t block = ^{
			float lastChapter = [AZErgoMangaChapter lastChapter:self.name];

			dispatch_at_main(^{
				[self.progress setChapters:lastChapter];
				self.fsCheck = [NSDate date];

				if (asynk)
					complete(self);
			});
		};

		dispatch_async_(asynk, at_background, block);
	}


}

- (AZErgoMangaProgress *) progress {
	if (!__progress) {
		__progress = [self primitiveValueForKey:@"progress"];

		if (!__progress) {
			__progress = [AZErgoMangaProgress insertNew];
			__progress.manga = [self inContext:__progress.managedObjectContext];
			__progress.chapter = 1;
			__progress.page = 1;
			__progress.updated = [NSDate date];
		}
	}

	return __progress;
}

- (NSUInteger) remapChapters:(NSArray *)chapters {
	NSUInteger remapped = 0;
	for (AZErgoUpdateChapterMapping *mapping in [self.chapterMappings allObjects]) {
		for (id<AZErgoChapterProtocol> c in chapters)
			if ((c.volume == mapping.volume) && [AZErgoMangaChapter same:c.idx as:mapping.sourceIDX]) {
				c.idx = mapping.mappedIDX;
				remapped++;
				break;
			}
	}

	return remapped;
}

- (AZErgoUpdateChapterMapping *) mappingForChapter:(float)chapter inVolume:(NSUInteger)volume {
	for (AZErgoUpdateChapterMapping *mapping in [self.chapterMappings allObjects])
		if ((volume == mapping.volume) && [AZErgoMangaChapter same:chapter as:mapping.sourceIDX])
			return mapping;

	return nil;
}

@end

@implementation AZErgoManga (Titles)

- (void) setAllTitles:(NSArray *)titles {
	NSSet *new = [NSSet setWithArray:titles];
	NSMutableSet *old = [NSMutableSet new];
	for (AZErgoMangaTitle *titleEntity in [self.titles allObjects]) {
		NSString *title = titleEntity.title;
		if (!(title && [new containsObject:title]))
			[titleEntity delete];
		else
			[old addObject:[title lowercaseStringWithLocale:[NSLocale currentLocale]]];
	}

	for (NSString *title in titles)
		if (![old containsObject:[title lowercaseStringWithLocale:[NSLocale currentLocale]]])
			[AZErgoMangaTitle mangaTitile:title].manga = self;
}

- (void) removeAllTitles {
	for (AZErgoMangaTitle *title in [self.titles allObjects])
		[title delete];
}

- (NSString *) mainTitle {
	return [[self class] mainTitle:[self titleEntities]] ?: self.name;
}

- (NSArray *) additionalTitles {
	NSArray *titles = [self titleEntities];

	NSArray *latin = [[self class] titleEntities:titles cyrylic:NO];

	NSArray *cyr = [[self class] titleEntities:titles cyrylic:YES];

	NSUInteger c = [cyr count];
	switch (c) {
		case 1:
			break;
		case 0: {
			NSUInteger l = [latin count];
			if (!l)
				break;

			c = l;
			cyr = latin;
		}
		default:
			latin = [cyr subarrayWithRange:NSMakeRange(1, c - 1)];
			break;
	}

	return latin;
}

- (NSArray *) titleEntities {
	NSMutableArray *titles = [NSMutableArray new];
	for (AZErgoMangaTitle *title in [self.titles allObjects]) {
		if (!title.title) {
			AZErgoManga *manga = title.manga;
			title.title = manga.name;
		}

		if (!title.title) {
			DDLogError(@"Corrupt manga entity: %@", self);
			continue;
		}
		[titles addObject:title.title];
	}

	return titles;
}

+ (NSString *) mainTitle:(NSArray *)titles {
	NSArray *t = [self titleEntities:titles cyrylic:YES];
	if ([t count])
		return [t firstObject];

	return [[self titleEntities:titles cyrylic:NO] firstObject];
}

+ (NSArray *) titleEntities:(NSArray *)titles cyrylic:(BOOL)cyrylic {
	NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:[titles count]];

	static NSCharacterSet *filter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		filter = [NSCharacterSet characterSetWithCharactersInString:@"йцукенгшщзхъёфывапролджэячсмитьбюїґєі"];
	});

	for (NSString *title in titles) {
		BOOL isCyrylic = [title rangeOfCharacterFromSet:filter].location != NSNotFound;
    if (isCyrylic ^ !cyrylic)
			[filtered addObject:title];
	}

	return (![filtered count]) ? nil : [filtered sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

@end

@implementation AZErgoManga (Tags)

- (NSArray *) tagNames {
	NSMutableArray *tags = [NSMutableArray new];
	for (AZErgoMangaTag *tag in [self.tags allObjects])
		[tags addObject:[tag.tag lowercaseString]];

	return tags;
}

- (void) removeAllTags {
	for (AZErgoMangaTag *tag in [self.tags allObjects])
		[self removeTagsObject:tag];
}

- (void) toggle:(BOOL)on tag:(AZErgoMangaTag *)tag {
	if (on)
		[tag addMangaObject:self];
	else
		[tag removeMangaObject:self];
}

- (AZErgoMangaTag *) toggle:(BOOL)on tagWithName:(NSString *)name {
	AZErgoMangaTag *tag = [AZErgoMangaTag tagWithName:name];
	[self toggle:on tag:tag];
	return tag;
}

- (AZErgoMangaTag *) toggle:(BOOL)on tagWithGUID:(NSUInteger)guid {
	return [self toggle:on tag:guid chain:nil];
}

- (AZErgoMangaTag *) toggle:(BOOL)on tag:(AZErgoTagGroup)guid chain:(NSSet *)chain {
	NSNumber *idGUID = @(guid);
	if (chain && [chain containsObject:idGUID])
		return nil;

	AZErgoMangaTag *tag = [AZErgoMangaTag tagWithGuid:idGUID];
	[self toggle:on tag:tag];

	[(id)GET_OR_INIT(chain, [NSMutableSet new]) addObject:idGUID];

	switch (guid) {
		case AZErgoTagGroupComplete:
			if (!on)
				[self toggle:NO tag:AZErgoTagGroupDownloaded chain:chain];
			break;
		case AZErgoTagGroupDownloaded:
			if (on)
				[self toggle:YES tag:AZErgoTagGroupComplete chain:chain];
			else
				[self toggle:NO tag:AZErgoTagGroupReaded chain:chain];
			break;
		case AZErgoTagGroupReaded:
			if (on)
				[self toggle:YES tag:AZErgoTagGroupDownloaded chain:chain];
			break;

		default:;
	}

	return tag;
}

- (AZErgoMangaTag *) hasTagWithGUID:(NSUInteger)guid {
	__block AZErgoMangaTag *r = nil;
	[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context
		for (AZErgoMangaTag *tag in [self.tags allObjects])
			if ([tag.guid unsignedIntegerValue] == guid) {
				r = tag;
			}
	}];

	return r;
}

- (BOOL) isComplete {
	return !![self hasTagWithGUID:AZErgoTagGroupComplete];
}

- (BOOL) isReaded {
	return !![self hasTagWithGUID:AZErgoTagGroupReaded];
}

- (BOOL) isDownloaded {
	return !![self hasTagWithGUID:AZErgoTagGroupDownloaded];
}

- (BOOL) isWebtoon {
	return !![self hasTagWithGUID:AZErgoTagGroupWebtoon];
}

@end
