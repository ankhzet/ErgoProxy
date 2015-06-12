//
//  AZErgoMangaReader.m
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaReader.h"
#import "AZScanCleanFilter.h"

#import "AZErgoMangaCommons.h"

#import "AZErgoReaderContentProvider.h"

@interface AZErgoMangaReader () {
	id displayedScan;
}
@end

@implementation AZErgoMangaReader

+ (AZErgoReaderContentProvider *) contentProviderForManga:(AZErgoManga *)manga andChapter:(float)chapter {
	AZErgoReaderContentProvider *provider = [[AZErgoReaderContentProvider alloc] initWithManga:manga];
	provider.chapterID = chapter;

	return provider;
}

+ (instancetype) readerForManga:(AZErgoManga *)manga andChapter:(float)chapter {
	return [self readerWithContentProvider:[self contentProviderForManga:manga andChapter:chapter]];
}

- (AZScanCleanFilter *) scanCleanFilter {
	if (!_scanCleanFilter)
		_scanCleanFilter = [AZScanCleanFilter filter];

	return _scanCleanFilter;
}

#pragma mark - Actual loading

- (void) showContents:(BOOL)flushCaches {
	displayedScan = nil;
	[super showContents:flushCaches];
}

- (void) cacheContents {
	for (id uid in self.contentProvider.content)
		[self cachedScan:uid];
}

- (id) cachedScan:(id)uid {
	return [self.contentProvider contentOf:uid
													withProcession:[self imagePreprocessor]
													 andCompletion:^(id uid) { [self scanCached:uid];}];
}

- (void) showContent:(NSInteger)index {
	displayedScan = [self.contentProvider contentID:index];

	if (!![self cachedScan:displayedScan])
		[self updateScanView:displayedScan];

	[super showContent:index];
}

- (void) scanCached:(id)uid {
	NSImageView *holder = [self holderOfContent:uid];
	holder.image = [self.contentProvider contentOf:uid];
	[holder.image setName:nil];

	if (uid == displayedScan)
		[self updateScanView:uid];

	if (self.delegate)
		[self.delegate contentCached:uid];
}

- (void) updateScanView:(id)uid {
	[super updateScanView:uid];

	for (NSView *holder in [self.contentView subviews])
		[holder setHidden:YES];

	NSImageView *holder = [self holderOfContent:uid];
	[holder setHidden:NO];
	[holder setNeedsDisplay:YES];
}

- (id(^)(id, __weak id)) imagePreprocessor {
	static dispatch_queue_t processQueue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    processQueue = dispatch_queue_create("scan-processing", DISPATCH_QUEUE_SERIAL);
	});

	return ^id(id uid, __weak NSImage *image) {
		__block NSImage *pImage = image;

		if (!pImage)
			return nil;

		if (![pImage isValid]) {
			[AZAlert showAlert:AZWarningTitle message:LOC_FORMAT(@"Image %@ can't be loaded!", [pImage name])];
			return pImage;
		}

		dispatch_sync(processQueue, ^{ @autoreleasepool {
			CGSize shrinken = [self shrinkenFit:pImage];
			CGRect rect;
			rect.origin = CGPointZero;
			rect.size = shrinken;
			CGImageRef imageToFilter = [pImage CGImageForProposedRect:&rect
																												context:nil
																													hints:@{
																																	NSImageHintInterpolation: @(NSImageInterpolationHigh),
																																	}];

			GPUImagePicture *picture = [[GPUImagePicture alloc] initWithCGImage:imageToFilter smoothlyScaleOutput:self.mipmapImages];

			[picture addTarget:self.scanCleanFilter];
			[self.scanCleanFilter useNextFrameForImageCapture];
			[picture processImage];
			imageToFilter = [self.scanCleanFilter newCGImageFromCurrentlyProcessedOutput];
			[picture removeAllTargets];
			picture = nil;

			[pImage recache];
			pImage = nil;
			pImage = [[NSImage alloc] initWithCGImage:imageToFilter size:shrinken];

			CGImageRelease(imageToFilter);
		} });

		return pImage;
	};
}

- (CGSize) shrinkenFit:(NSImage *)source {
	CGSize outS = self.contentView.bounds.size;
	CGSize inpS = source.pixelSize;

	CGSize offS = CGSizeMake(outS.width * 1.05f, outS.height * 1.05f);

	BOOL tooWide = offS.width < inpS.width;
	BOOL tooTall = offS.height < inpS.height;
	BOOL needRescale = tooWide || tooTall;

	if (needRescale) {
		float aspect = inpS.width / inpS.height;
		if (tooWide) {
			inpS.width = offS.width;
			inpS.height = inpS.width / aspect;
		}

		BOOL tooTall = offS.height < inpS.height;
		if (tooTall) {
			inpS.height = offS.height;
			inpS.width = inpS.height * aspect;
		}

		inpS.width = MAX((int) inpS.width, 1);
		inpS.height = MAX((int) inpS.height, 1);

//		[source setSize:inpS];
//		[source recache];
	}

	return inpS;
}

@end
