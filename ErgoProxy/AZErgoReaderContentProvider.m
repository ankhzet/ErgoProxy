//
//  AZErgoReaderContentProvider.m
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoReaderContentProvider.h"

#import "AZErgoMangaCommons.h"
#import "AZErgoChapterProtocol.h"

#import "AZDataProxy.h"
#import "AZDownload.h"

@implementation AZErgoReaderContentProvider {
	NSArray *scansList;

	NSMutableArray *corrupted;

	NSMutableDictionary *contentCache;
}
@synthesize chapterID = _chapterID;

- (id)initWithManga:(AZErgoManga *)manga {
	if (!(self = [super init]))
		return self;

	_manga = manga;
	return self;
}

- (void) dealloc {
	[self flushCache];
}

- (void) setChapterID:(float)chapterID {
	@synchronized(self) {
		if (_IDX(chapterID) == _IDX(_chapterID))
			return;

		_navigatedBackward = chapterID < _chapterID;
		_chapterID = chapterID;

		scansList = nil;
		corrupted = nil;
		[self flushCache];
	}
}

- (float) chapterID {
	return _chapterID;
}

- (NSArray *) content {
	@synchronized(self) {
		if (!scansList) {
			scansList = [AZUtils fetchFiles:self.contentPath];

			corrupted = [NSMutableArray arrayWithCapacity:[scansList count]];
		}

		return scansList;
	}
}

- (BOOL) hasContent {
	return !![self.content count];
}

@end

@implementation AZErgoReaderContentProvider (Commons)

- (NSArray *) corruptedScans {
	return corrupted;
}

- (void) flushCache {
	for (NSImage *image in [contentCache allValues])
		[image recache];
	
	contentCache = nil;
	
}

- (NSInteger) constraintIndex:(NSInteger)index {
	return CLAMP(index, 0, (int)[self.content count] - 1);
}

- (NSString *) contentPath {
	return  [NSString pathWithComponents:@[
																				 [AZErgoMangaChapter mangaStorage],
																				 self.manga.name,
																				 [AZErgoMangaChapter formatChapterID:self.chapterID]
																				 ]];
}

- (NSUInteger) contentIDX:(id)uid {
	@synchronized(self) {
		return [self.content indexOfObject:uid];
	}
}

- (NSString *) contentID:(NSInteger)index {
	@synchronized(self) {
		index = [self constraintIndex:index];
		return self.content[index];
	}
}

- (void) viewingContentAtIndex:(NSInteger)index {
	AZErgoMangaProgress *progress = self.manga.progress;

	float lastChapter = [AZErgoMangaChapter lastChapter:self.manga.name];
	progress.chapters = MAX(progress.chapters, lastChapter);

	float prev = progress.chapter;

	[progress setChapter:self.hasContent ? self.chapterID : MAX(self.chapterID, prev) andPage:index + 1];

	if ((!index) && [AZErgoMangaChapter same:prev as:lastChapter]) {
		if (self.manga.isDownloaded)
			[self.manga toggle:YES tagWithGUID:AZErgoTagGroupReaded];
	}

	//TODO: BAD!
	[[AZDataProxy sharedProxy] saveContext:YES];
}

- (float) hasNext:(BOOL)backward {
	return [AZErgoMangaChapter seekManga:self.manga.name chapter:self.chapterID withDelta:backward ? -1 : 1];
}

- (BOOL) seekNext:(BOOL)backward {
	float old = self.chapterID;
	float new = [self hasNext:backward];

	BOOL diff = ![AZErgoMangaChapter same:new as:old];

	if (diff)
		self.chapterID = new;

	return diff;
}

- (id) contentOf:(id)uid {
	return [self contentOf:uid withProcession:nil andCompletion:nil];
}

- (id) contentOf:(id)uid withProcession:(id(^)(id uid, id content))process andCompletion:(void(^)(id uid))complete {
	@synchronized(self) {
		NSUInteger index = [scansList indexOfObject:uid];
		if (index == NSNotFound)
			return nil;

		uid = [scansList objectAtIndex:index];

		@synchronized(uid) {
			if (!contentCache)
				contentCache = [NSMutableDictionary dictionaryWithCapacity:[scansList count]];

			id cached = contentCache[uid];
			if (cached)
				return cached;

			NSString *imageName = uid;
			NSString *scanFileName = [self.contentPath stringByAppendingPathComponent:imageName];

			dispatch_async_at_background(^{
				NSImage *image = nil;

				if (scanFileName && [NSImage isImageFile:scanFileName]) {
					if ([NSImage isJPEG:scanFileName]) {
						NSData *data = [NSData dataWithContentsOfFile:scanFileName];

						if ([NSImage isCorruptJPEGWithData:data]) {
//							image = [NSImage imageNamed:NSImageNameApplicationIcon];
							image = [[NSImage alloc] initWithData:data];

							[corrupted addObject:imageName];
						} else
							image = [[NSImage alloc] initWithData:data];
					} else
						image = [[NSImage alloc] initByReferencingFile:scanFileName];
				} else
					image = [NSImage imageNamed:NSImageNameApplicationIcon];

				[image setName:imageName];

				image = [self prepareContent:image];

				@synchronized(self) {
					@synchronized(uid) {
						contentCache[uid] = image;
					}
				}
				image = nil;

				if (process) {
					__weak NSImage *weakRef = contentCache[uid];
					image = process(uid, weakRef);

					if (!image)
						return;

					@synchronized(self) {
						@synchronized(uid) {
							contentCache[uid] = image;
						}
					}
				}

				if (complete)
					complete(uid);
			});

			return nil;
		}
	}
}

- (id) prepareContent:(id)content {
	return content;
}

@end
