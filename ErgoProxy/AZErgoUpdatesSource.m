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

+ (NSUInteger) checkAll {
	_synchronized({
		NSUInteger inProcess = 0;
		for (AZErgoUpdatesSource *source in [sources allValues])
			inProcess += [source checkAll] ? 0 : 1;

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

- (BOOL) checkAll {
	if (inProcess)
		return NO;

	@synchronized(self) {
		if (inProcess)
			return NO;

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self queuedCheck:[self.descriptor.watches mutableCopy]];
		});
	}

	return YES;
}

- (void) queuedCheck:(NSMutableSet *)queue {
	if (![queue count])
		return;

	AZErgoUpdateWatch *watch = [queue anyObject];
	[queue removeObject:watch];

	[self checkWatch:watch withBlock:^(AZErgoUpdateWatch *watch, NSUInteger updates) {
		[self queuedCheck:queue];
	}];
}

- (void) checkWatch:(AZErgoUpdateWatch *)watch {
	[self checkWatch:watch withBlock:nil];
}

- (void) checkWatch:(AZErgoUpdateWatch *)watch withBlock:(void(^)(AZErgoUpdateWatch *watch, NSUInteger updates))block {
	OSAtomicIncrement32(&inProcess);
	watch.checking = YES;
	if (self.delegate)
		[self.delegate updatesSource:self checkingWatch:watch];

	[AZ_API(ErgoUpdates) updates:self watch:watch chaptersWithCompletion:^(BOOL isOk, NSArray *chapters) {
		NSUInteger updates = 0;

		@try {
			if ([chapters count]) {

				for (AZErgoUpdateChapter *update in chapters) {

					if ((![update isDeleted]) && ![watch.updates containsObject:update]) {
						update.watch = watch;
						if (update.mangaName)
							watch.title = watch.title ?: update.mangaName;

						updates++;
					}
				}

				[[AZDataProxy sharedProxy] saveContext];
			}

		}
		@finally {
			OSAtomicDecrement32(&inProcess);
			watch.checking = NO;

			if (self.delegate)
				[self.delegate updatesSource:self watch:watch checked:!!updates];

			if (block)
				block(watch, updates);
		}

	}];
}

- (void) checkUpdate:(AZErgoUpdateChapter *)chapter withBlock:(void(^)(AZErgoUpdateChapter *chapter, NSArray *scans))block {
	OSAtomicIncrement32(&inProcess);
	[AZ_API(ErgoUpdates) updates:self chapter:chapter scansWithCompletion:^(BOOL isOk, NSArray *scans) {
		@try {
				block(chapter, scans);
		}
		@finally {
			OSAtomicDecrement32(&inProcess);
		}
	}];
}

@end

@implementation AZErgoUpdatesSource (SourceRelated)

- (id) chaptersAction:(AZErgoUpdateWatch *)watch {
	return [self action:@"manga" request:watch.genData];
}

- (id) scansAction:(AZErgoUpdateChapter *)chapter {
	return [self action:@"online" request:chapter.genData];
}

- (id) action:(NSString *)action request:(NSString *)genData {
	AZHTMLRequest *request = [AZHTMLRequest actionWithName:action];
	request.url = [@"http://" stringByAppendingString:self.descriptor.serverURL];
	return request;
}

- (NSArray *) chaptersFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

- (NSArray *) scansFromDocument:(TFHpple *)document {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
}

+ (NSString *) chapter:(NSString *)pattern element:(NSUInteger)element {
	NSAssert(false, @"Unimplemented %s", __PRETTY_FUNCTION__);
	return nil;
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

