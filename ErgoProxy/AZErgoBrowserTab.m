//
//  AZErgoBrowserTab.m
//  ErgoProxy
//
//  Created by Ankh on 26.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoBrowserTab.h"
#import "AZErgoTabsComons.h"
#import <WebKit/WebKit.h>

#import "HTTPServer.h"
#import "AZErgoHTTPConnection.h"

#import "AZDownload.h"
#import "AZErgoMangaCommons.h"
#import "AZErgoUpdatesCommons.h"

#import "AZSyncedScrollView.h"

#import "AZErgoReaderContentProvider.h"
#import "AZErgoMangaReader.h"
#import "AZErgoWebtoonReader.h"

#import "AZErgoScanView.h"

@interface AZErgoBrowserTab () <AZSyncedScrollViewProtocol> {
	HTTPServer *httpServer;

	NSString *mangaURI;

	id monitor;

	NSUInteger cached;

}
@property (weak) IBOutlet WebView *wvWebView;
@property (weak) IBOutlet NSTextField *tfAddressField;
@property (weak) IBOutlet NSView *vAddressPanel;

@property (weak) IBOutlet NSLayoutConstraint *lcScrollViewWidth;
@property (weak) IBOutlet NSLayoutConstraint *lcScrollViewHeight;
@property (weak) IBOutlet AZSyncedScrollView *scvScrollView;


@property (weak) IBOutlet AZErgoScanView *vScanView;


@property (nonatomic) BOOL webMode;
@property (nonatomic) float chapter;
@property (nonatomic) AZErgoManga *manga;
@property (nonatomic) AZErgoReader *reader;

@end

@interface AZErgoBrowserTab (Delegated) <AZErgoReaderDelegateProtocol>

- (void) navigatedToChapter;

@end


@implementation AZErgoBrowserTab
@synthesize reader = _reader, manga = _manga, chapter = _chapter, vScanView = _vScanView;

- (float) chapter {
	return _chapter;
}

- (void) setChapter:(float)chapter {
	_chapter = chapter;
	self.reader.contentProvider.chapterID = _chapter;
}

- (AZErgoReader *) reader {
	if (self.webMode)
		return nil;

	if (!_reader) {
		Class readerClass = self.manga.isWebtoon ? [AZErgoWebtoonReader class] : [AZErgoMangaReader class];

		_reader = [readerClass readerForManga:self.manga andChapter:self.chapter];
		_reader.delegate = (id)self;

	}

	return _reader;
}

- (AZErgoManga *) manga {
	AZErgoManga *pickNew = self.navData ? self.navData : nil;

	if (pickNew && ![pickNew isKindOfClass:[AZErgoManga class]])
		pickNew = [AZErgoManga mangaByName:(id)pickNew];

	if (pickNew && (_manga != pickNew)) {
		if (_reader) {
			[_reader unsetKeyMonitor];

			_reader = nil;
		}
	}
	return pickNew ? (_manga = pickNew) : _manga;
}

+ (NSString *) tabIdentifier {
	return AZEPUIDBrowserTab;
}

- (void) show {
	[self.scvScrollView setDelegate:self];

	mangaURI = nil;

	AZErgoManga *manga = [self manga];

	self.webMode = AZ_KEYDOWN(Shift) || manga.isWebtoon;
	[self.wvWebView setHidden:!self.webMode];
	[[self.vScanView scrollView] setHidden:self.webMode];

	float chapter = 0.f;

	if (AZ_KEYDOWN(Command))
		chapter = [AZErgoMangaChapter lastChapter:manga.name];
	else {
		AZErgoMangaProgress *p = manga.progress;
		if (p && !!p.chapter)
			chapter = p.chapter;
	}

	if (self.webMode) {
		_reader = nil;
		[self showWeb:manga chapter:chapter];
	} else {

		if (!manga)
			AZErrorTip(LOC_FORMAT(@"Manga not selected!"));
		else {
			mangaURI = [self chapterPath:chapter];
			self.chapter = chapter;

			[self.reader show];
		}

	}

	[super show];
}

- (NSString *) chapterPath:(float)chapter {
	AZErgoManga *manga = [self manga];
	NSArray *path = manga ? @[@"/reader", self.manga.name] : @[@"/manga"];
	path = [path arrayByAddingObject:[@(chapter) stringValue]];

	return [NSString pathWithComponents:path];
}

- (void) showWeb:(AZErgoManga *)manga chapter:(float)chapter {
	if (!httpServer) {
		httpServer = [[HTTPServer alloc] init];
		[httpServer setConnectionClass:[AZErgoHTTPConnection class]];
		[httpServer setType:@"_http._tcp."];

		NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"web"];

		[httpServer setDocumentRoot:webPath];
		[httpServer setPort:2012];

		NSError *error;
		if([httpServer start:&error]) {
		} else {
			DDLogError(@"Error starting HTTP Server: %@", error);
		}
		
	}
	
	if (!(([[self loadedURI] length] > 0) && !self.navData))
		[self loadURI:[self chapterPath:chapter]];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	self.tfAddressField.stringValue = [sender.mainFrameURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ?: @"oO";

	[self navigatedToChapter];
}

- (void) reload {
	[self loadURI:[self loadedURI]];
}

- (NSString *) host {
	return [NSString stringWithFormat:@"localhost:%hu", httpServer.listeningPort];
}

- (NSString *) loadedURI {
	if (mangaURI)
		return mangaURI;

	NSString *host = [NSString stringWithFormat:@"http://%@", [self host]];
	NSString *uri = self.wvWebView.mainFrameURL;
	uri = [uri stringByReplacingOccurrencesOfString:host withString:@""];
	uri = [uri stringByReplacingPercentEscapes];
	return uri;
}

- (void) loadURI:(NSString *)uri {
	if (![httpServer isRunning])
		return;

	NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:[self host] path:uri];

	[[self.wvWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void) frame:(NSScrollView *)view sizeChanged:(NSSize)size {
	self.lcScrollViewWidth.constant = size.width;
	self.lcScrollViewHeight.constant = size.height;

	if (mangaURI)
		return;

	if (self.manga.isWebtoon)
		size.height = [self.reader contentSize].height;
}

- (void) frameResized {
	if (mangaURI)
		[self delayed:@"rescale" forTime:0.1 withBlock:^{
			[self.reader loadContents:YES];
		}];
	else {
		[self.vAddressPanel setCollapsed:[[NSApp mainWindow] isInFullScreenMode]];

		[self reload];
	}
}

- (NSString *) title {
	if (mangaURI) {
		return self.reader.readedTitle;
	}

	return self.wvWebView.mainFrameTitle;
}

- (NSView *) vScanView {
	if (![_vScanView isKindOfClass:[AZErgoScanView class]]) {
		AZErgoScanView *scanView = [[AZErgoScanView alloc] initWithFrame:_vScanView.frame];
		[scanView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

		[_vScanView addSubview:scanView];
		_vScanView = scanView;
	}

	return _vScanView;
}

- (void) setVScanView:(AZErgoScanView *)vScanView {
	_vScanView = vScanView;
}

@end

@implementation AZErgoBrowserTab (Delegated)

- (void) navigatedToChapter {
	[[NSApp mainWindow] setTitle:LOC_FORMAT(@"%@ - Reader", [self title])];
}

- (void) loadedChapter {
	if (self.manga.isWebtoon)
		[self frame:nil sizeChanged:self.view.frame.size];

	AZErgoReaderContentProvider *content = self.reader.contentProvider;
	NSArray *corruptedScans = [content corruptedScans];

	if (![corruptedScans count])
		return;

	AZ_Mutable(IndexSet, *downloads);
	AZ_Mutable(IndexSet, *skipped);
	for (NSString *imageUID in corruptedScans) {
    NSUInteger idx = [content contentIDX:imageUID];
		if (idx == NSNotFound)
			continue;

		AZDownload *download = [AZDownload any:@"forManga = %@ and (abs(chapter - %f) < 0.01) and page == %lu", self.manga, self.chapter, idx + 1];

//		NSString *summary = LOC_FORMAT(@"p. %lu (%@)", idx + 1, imageUID);

		if (download) {
			[downloads addIndex:idx + 1];
			[download reset:nil];
			download.updateChapter.state = AZErgoUpdateChapterDownloadsPartial;
		} else
			[skipped addIndex:idx + 1];
//			[skipped addObject:summary];
	}

	AZ_Mutable(Array, *total);
	if (!![downloads count])
		[total addObject:LOC_FORMAT(@"Rescheduled downloads for pages %@", [downloads plainDescription])];

	if (!![skipped count])
		[total addObject:LOC_FORMAT(@"Downloads not found for pages %@", [skipped plainDescription])];

	AZErrorTip(LOC_FORMAT(@"Corrupted scans in <%@> ch. %@:\n\n%@", self.manga, [AZErgoMangaChapter formatChapterID:self.chapter], [total componentsJoinedByString:@"\n\n"]));
}

- (NSView *) superview {
	return self.vScanView;
}

- (void) willRecache {
	cached = 0;
	self.vScanView.scans = [self.reader scanCount];
	
	[self navigatedToChapter];
}

- (void) contentShow:(id)uid {
	[self.vScanView scan:[self.reader.contentProvider contentIDX:uid] shown:(id)[NSNull null]];
}

- (void) contentCached:(id)uid {
	@synchronized(self) {
		[self.vScanView scan:[self.reader.contentProvider contentIDX:uid] cached:(id)[NSNull null]];

		cached++;

		if (cached >= self.reader.scanCount) {
			[self delayed:@"loaded-chapter" forTime:0.5 withBlock:^{
				[self loadedChapter];
			}];			
		}
	}
}

- (BOOL) isKey {
	return self.isKeyTab;
}

- (void) noContents:(float)chapter navigatedBackward:(BOOL)navigatedBackward {
	[self delayed:@"chapter-nav" withBlock:^{
		float next = [self.reader.contentProvider hasNext:navigatedBackward];

		if ([AZErgoMangaChapter same:next as:chapter]) {
			float prev = [self.reader.contentProvider hasNext:!navigatedBackward];

			NSString *direction = LOC_FORMAT(navigatedBackward ? @"first" : @"last");

			AZInfoTip(LOC_FORMAT(@"This is %@ available chapter (%.1f) of manga \"%@\"",
													 direction,
													 prev,
													 self.manga
													 ));
		} else
			AZInfoTip(LOC_FORMAT(@"Chapter (%.1f) of manga \"%@\" is unavailable. Next available chapter is (%.1f).",
													 chapter,
													 self.manga,
													 next
													 ));
	}];
}

@end
