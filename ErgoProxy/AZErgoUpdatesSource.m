//
//  AZErgoUpdatesSource.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesCommons.h"

#import "AZErgoUpdatesAPI.h"
#import "AZHTMLRequest.h"
#import "AZDataProxy.h"

#import "AZErgoMangaCommons.h"
#import "AZErgoSchedulingQueue.h"

#define _synchronized(_block) ({\
NSMutableDictionary *sources;\
@synchronized(sources = (id)[AZErgoUpdatesSource sharedSources]) {\
_block;\
}\
})\

const NSUInteger LABEL_ELEMENT_TITLE   = 4;
const NSUInteger LABEL_ELEMENT_VOLUME  = 2;
const NSUInteger LABEL_ELEMENT_CHAPTER = 3;
const NSUInteger LABEL_ELEMENT_TIP     = 1;

@implementation AZErgoUpdatesSource (Commons)

+ (NSUInteger) checkAll:(void(^)(dispatch_block_t block))block {
	_synchronized({
		NSUInteger inProcess = 0;
		for (AZErgoUpdatesSource *source in [sources allValues])
			inProcess += [source checkAll:block] ? 0 : 1;

		return inProcess;
	});
}

+ (BOOL) inProcess {
	_synchronized({
		for (AZErgoUpdatesSource *source in [sources allValues])
			if (!!source.inProcess)
				return YES;

		return NO;
	});
}

+ (instancetype) sharedSource {
	_synchronized({
		NSString *url = [self serverURL];
		AZErgoUpdatesSource *instance = sources[url];
		if (!instance)
			instance = sources[url] = [self new];

		return instance;
	});
}

+ (NSDictionary *) sharedSources {
	static NSMutableDictionary *sources;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    sources = [NSMutableDictionary dictionary];
	});

	return sources;
}

+ (NSString *) serverURL {
	return nil;
}

@end


@implementation AZErgoUpdatesSource
@synthesize descriptor = _descriptor, inProcess, delegate;

- (AZErgoUpdatesSourceDescription *) descriptor {
	if (_descriptor)
		return _descriptor;

	NSString *url = [[self class] serverURL];

	_descriptor = [AZErgoUpdatesSourceDescription unique:[NSPredicate predicateWithFormat:@"serverURL ==[c] %@", url] initWith:^(AZErgoUpdatesSourceDescription *instantiated) {
		instantiated.serverURL = url;
	}];

	return _descriptor;
}

- (BOOL) isInProcess {
	return inProcess > 0;
}

- (BOOL) checkAll:(void(^)(dispatch_block_t block))block {
	if (self.isInProcess)
		return NO;

	@synchronized(self) {
		if (self.isInProcess)
			return NO;

		NSArray *watches = [[self.descriptor.watches allObjects] sortedArrayUsingSelector:@selector(compare:)];
		inProcess = 0;
		for (AZErgoUpdateWatch *watch in watches)
			if (watch.requiresCheck)
				block(^{
					[self checkWatch:watch];
				});
	}

	return YES;
}

- (void) checkWatch:(AZErgoUpdateWatch *)watch {
	OSAtomicIncrement32(&inProcess);
	watch.checking = YES;

	if (self.delegate)
		[self.delegate updatesSource:self checkingWatch:watch];

	[AZErgoWaitBreakTask executeTask:^(AZErgoWaitBreakTask *task) {
		[AZ_API(ErgoUpdates) updates:self watch:watch infoWithCompletion:^(BOOL isOk, AZErgoUpdateMangaInfo *info) {
			[self updates:watch retrived:info];

			[task break];
		}];
	}];
}

- (void) updates:(AZErgoUpdateWatch *)watch retrived:(AZErgoUpdateMangaInfo *)info {
	__block NSUInteger updates = 0;
	if (!!info) {
		__block AZErgoManga *manga;
		[[AZDataProxy sharedProxy] securedTransaction:^(NSManagedObjectContext *context, BOOL *propagateChanges) {
			manga = [AZErgoManga mangaByName:watch.manga];

			BOOL new = (!manga) || (![manga.annotation length]);

			if (new) {
				manga = manga ?: [AZErgoManga insertNew];
				manga.name = watch.manga;
			}

			NSSet *titles = [NSSet setWithArray:[manga titleEntities]];
			if (![titles isEqualToSet:[NSSet setWithArray:info->titles]]) {
				for (AZErgoMangaTitle *title in manga.titles)
					[title delete];

				for (NSString *title in info->titles)
					[AZErgoMangaTitle mangaTitile:title].manga = manga;
			}

			if (!manga.annotation)
				manga.annotation = info->annotation;

			if (!manga.preview)
				manga.preview = info->preview;

			if (![manga.tags count])
				for (NSString *tag in info->tags) // tag names must already be mapped
					[manga toggle:YES tagWithName:tag];

			if ([info->chapters count]) {
				updates = [self synk:watch chapters:info->chapters];

				if (!!updates)
					[manga toggle:NO tagWithGUID:AZErgoTagGroupSuspended];

					if (manga.isComplete != info->isComplete)
						[manga toggle:info->isComplete tagWithGUID:AZErgoTagGroupComplete];

					if (!info->isComplete) {
						[manga toggle:NO tagWithGUID:AZErgoTagGroupReaded];
						[manga toggle:NO tagWithGUID:AZErgoTagGroupDownloaded];
				}
			}
			

		}];

	}

	watch.checking = NO;
	OSAtomicDecrement32(&inProcess);
	if (self.delegate)
		[self.delegate updatesSource:self watch:watch checked:!!updates];
}

typedef void(^__guardedBlock)(BOOL isOk, id data);
typedef void(^__blockWithBlockParameter)(__guardedBlock block);

- (void) processIn:(__blockWithBlockParameter)in guarded:(__guardedBlock)guarded out:(dispatch_block_t)out {
	OSAtomicIncrement32(&inProcess);
	in(^(BOOL isOk, id data){
		@try {
			guarded(isOk, data);
		}
		@finally {
			if (out)
				out();

			OSAtomicDecrement32(&inProcess);
		}
	});
}

- (NSUInteger) synk:(AZErgoUpdateWatch *)watch chapters:(NSArray *)chapters {
	void (^initBlock)(AZErgoUpdateChapter *chapter, id<AZErgoChapterProtocol> chapterData) = ^void(AZErgoUpdateChapter *chapter, id<AZErgoChapterProtocol> chapterData) {
		chapter.genData = chapterData.genData;
		chapter.title = chapterData.title;
		chapter.idx = chapterData.idx;
		chapter.volume = chapterData.volume;
		chapter.date = chapterData.date;
		chapter.mangaName = chapterData.mangaName;

		if (!!chapter.watch)
			chapter.watch.title = chapter.mangaName;
	};

	AZ_Mutable(Array, *newChapters);
	AZ_Mutable(Array, *allChapters);

	NSMutableArray *old = [[watch.updates allObjects] mutableCopy];

	for (id<AZErgoChapterProtocol> chapterData in chapters) {
		AZErgoUpdateChapter *chapter = [AZErgoUpdateChapter any:@"genData == %@", chapterData.genData];

		if (!chapter)
			[newChapters addObject:chapterData];
		else {
			initBlock(chapter, chapterData);
			[allChapters addObject:chapter];
		}
	}


	if (!![newChapters count]) {
		AZ_Mutable(Array, *newEntities);

		if ([[AZDataProxy sharedProxy] securedTransaction:^(NSManagedObjectContext *context, BOOL *propagateChanges) {
			for (id<AZErgoChapterProtocol> data in newChapters) {
				AZErgoUpdateChapter *new = [AZErgoUpdateChapter insertNew];
				initBlock(new, data);
				[newEntities addObject:new];
			}
		}])
			for (AZErgoUpdateChapter *inserted in newEntities)
				[allChapters addObject:[inserted inContext:nil]];
	}

	[[AZDataProxy sharedProxy] securedTransaction:^(NSManagedObjectContext *context, BOOL *propagateChanges) {
		for (AZErgoUpdateChapter *update in allChapters)
			if (!([update isDeleted] || update.watch)) {
				update.watch = watch;

				if (update.mangaName && !watch.title)
					watch.title = update.mangaName;
			}
	}];

	old = [[old sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
	[old removeObjectsInArray:allChapters];
	for (AZErgoUpdateChapter *chapter in old)
		[chapter delete];

	return [newChapters count];
}

- (void) checkUpdate:(AZErgoUpdateChapter *)chapter withBlock:(void(^)(NSArray *scans))block {
	[self processIn:^(__guardedBlock guarded) {
		[AZ_API(ErgoUpdates) updates:self chapter:chapter scansWithCompletion:^(BOOL isOk, NSArray *scans) {
			guarded(isOk, scans);
		}];
	} guarded:^(BOOL isOk, id data) {
		block(data);
	} out:nil];
}

@end

@implementation AZErgoUpdatesSource (SourceRelated)

- (BOOL) correspondsTo:(NSString *)resoureURL {
	return NO;
}

- (NSString *) parseURL:(NSString *)url {
	return nil;
}

- (NSString *) genDataToFolder:(NSString *)genData {
	return nil;
}

- (NSSet *) parseTitles:(NSString *)string {
	return [NSSet setWithObject:string];
}

- (NSString *) genDataFromResourceURL:(NSString *)url {
	if (![self correspondsTo:url])
		return nil;

	return [self parseURL:url];
}

- (id) infoAction:(AZErgoUpdateWatch *)watch {
	return [self action:@"manga" request:watch.genData];
}

- (id) scansAction:(AZErgoUpdateChapter *)chapter {
	return [self action:@"online" request:chapter.genData];
}

-(id) searchAction:(NSString *)query {
	return [self action:@"search" request:query];
}

- (id) action:(NSString *)action request:(NSString *)genData {
	AZHTMLRequest *request = [AZHTMLRequest actionWithName:action];
	request.url = [@"http://" stringByAppendingString:self.descriptor.serverURL];
	return request;
}

- (NSDictionary *) entitiesFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSArray *) chaptersFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSArray *) scansFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSArray *) titlesFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSArray *) tagsFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSString *) annotationFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSString *) previewFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

+ (NSString *) chapter:(NSString *)pattern element:(NSUInteger)element {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (BOOL) isCompleteFromDocument:(TFHpple *)document {
	return NO;
}

+ (float) chapterIdx:(NSString *)pattern {
	return [[self chapter:pattern element:LABEL_ELEMENT_CHAPTER] floatValue];
}

+ (int) chapterVolume:(NSString *)pattern {
	return [[self chapter:pattern element:LABEL_ELEMENT_VOLUME] intValue];
}

+ (NSString *) chapterTitle:(NSString *)pattern {
	NSString *title = [self chapter:pattern element:LABEL_ELEMENT_TITLE];
	return title ? [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : nil;
}

+ (NSString *) chapterTip:(NSString *)pattern {
	return [[self chapter:pattern element:LABEL_ELEMENT_TIP] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) mappedTagName:(NSString *)name {
	return name;
}

@end

@implementation AZErgoUpdatesSourceDescription (DelayedBind)

- (AZErgoUpdatesSource *) relatedSource {
	_synchronized({
		AZErgoUpdatesSource *related = sources[self.serverURL];

		NSAssert(!!related, @"Source server description accessed earlier than it's handler instance");
		
		return related;
	});
}

@end

