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

#import "AZErgoMangaCommons.h"
#import "AZErgoUpdatesCommons.h"

#import "AZSyncedScrollView.h"

#import "AZErgoReaderContentProvider.h"
#import "AZErgoMangaReader.h"
#import "AZErgoWebtoonReader.h"

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


@property (weak) IBOutlet NSView *vScanView;


@property (nonatomic) BOOL webMode;
@property (nonatomic) float chapter;
@property (nonatomic) AZErgoManga *manga;
@property (nonatomic) AZErgoReader *reader;

@end

@implementation AZErgoBrowserTab
@synthesize reader = _reader, manga = _manga, chapter = _chapter;

__weak static AZErgoBrowserTab *__browserTab;

+ (AZErgoBrowserTab *) browserTab {
	return __browserTab;
}

- (id)init {
	if (!(self = [super init]))
		return self;

	__browserTab = self;

	return self;
}

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
		if (_reader)
			[_reader unsetKeyMonitor];

		_reader = nil;
	}
	return pickNew ? (_manga = pickNew) : _manga;
}

- (NSString *) tabIdentifier {
	return AZEPUIDBrowserTab;
}

- (void) show {
	[self.scvScrollView setDelegate:self];

	mangaURI = nil;

	AZErgoManga *manga = [self manga];

	self.webMode = AZ_KEYDOWN(Shift);
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
			[AZAlert showAlert:AZWarningTitle message:LOC_FORMAT(@"Manga not selected!")];
		else {
			mangaURI = [NSString pathWithComponents:@[@"reader", manga.name, [@(chapter) stringValue]]];

			self.chapter = chapter;

			[self.reader show];
		}

	}

	[super show];
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
	
	NSArray *path = manga ? @[@"/reader", manga.name] : @[@"/manga"];

	path = [path arrayByAddingObject:[@(chapter) stringValue]];

	if (!(([[self loadedURI] length] > 0) && !self.navData))
		[self loadURI:[NSString pathWithComponents:path]];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	self.tfAddressField.stringValue = [sender.mainFrameURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ?: @"oO";

	[[NSApp mainWindow] setTitle:LOC_FORMAT(@"%@ - Reader", sender.mainFrameTitle)];
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
	uri = [uri stringByRemovingPercentEncoding];
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

@end

@interface AZErgoBrowserTab (Delegated) <AZErgoReaderDelegateProtocol>
@end

@implementation AZErgoBrowserTab (Delegated)

- (void) navigatedToChapter {
	[[NSApp mainWindow] setTitle:LOC_FORMAT(@"%@ - Reader", self.reader.readedTitle)];
}

- (void) loadedChapter {
	if (self.manga.isWebtoon)
		[self frame:nil sizeChanged:self.view.frame.size];
}

- (NSView *) superview {
	return self.vScanView;
}

- (void) willRecache {
	cached = 0;
	[self navigatedToChapter];
}

- (void) contentCached:(id)uid {
	cached++;

	if (cached >= [self.reader.contentProvider.content count])
		[self loadedChapter];
}

- (BOOL) isKey {
	return YES;
}

- (void) noContents:(float)chapter navigatedBackward:(BOOL)navigatedBackward {
	[[AZDelayableAction shared:@"chapter-nav"] delayed:0 execute:^{
		NSString *direction = LOC_FORMAT(navigatedBackward ? @"first" : @"last");

		[AZAlert showAlert:AZInfoTitle
							 message:LOC_FORMAT(@"This is %@ available chapter (%.1f) of manga \"%@\"",
																	direction,
																	chapter,
																	self.manga
																	)];
	}];
}

@end
