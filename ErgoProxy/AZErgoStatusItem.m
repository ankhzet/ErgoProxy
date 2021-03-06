//
//  AZErgoStatusItem.m
//  ErgoProxy
//
//  Created by Ankh on 25.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoStatusItem.h"

#import "AZProxifier.h"
#import "AZDownload.h"
#import "AZDownloadSpeedWatcher.h"

#import "AZDelayableAction.h"
#import "AZMultipleTargetDelegate.h"

#import "AZErgoBrowserTab.h"
#import "AZErgoMangaCommons.h"
#import "AZErgoUpdatesCommons.h"

#define UNACTIVITY_INTERVAL 5
#define AVERAGE_INTERVAL 60

@interface AZErgoStatusItem () <NSMenuDelegate>

@end

MULTIDELEGATED_INJECT_LISTENER(AZErgoStatusItem)

@implementation AZErgoStatusItem {
	NSStatusItem *item;
	NSMutableDictionary *downloads;
	NSImage *appIcon;

	BOOL noActivity;

	float averageSpeed, maxAverage;

	dispatch_queue_t queue;
	NSMenu *menu;
}

- (id)init {
	if (!(self = [super init]))
		return self;

	appIcon = [NSImage imageNamed:NSImageNameApplicationIcon];
	[appIcon setSize:NSMakeSize(20, 20)];

	item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

	[item setHighlightMode:YES];
	[item setToolTip:LOC_FORMAT(@"Ergo!")];

	[item setView:self];

	[item setMenu:[self popupMenu]];

	downloads = [NSMutableDictionary new];

	queue = dispatch_queue_create("org.ankhzet.status-item-queue", DISPATCH_QUEUE_SERIAL);

	dispatch_async(queue, ^{
		[self queue];
	});

	[self bindAsDelegateTo:[AZProxifier sharedProxifier] solo:YES];

	return self;
}

- (void) queue {
	while ([NSApp isRunning]) {
		AZDownloadSpeedWatcher *watcher = [AZDownloadSpeedWatcher sharedSpeedWatcher];
		@synchronized(self) {
			NSTimeInterval shortTerm = [AZDownloadSpeedWatcher timeWithTimeIntervalSinceNow:-UNACTIVITY_INTERVAL];
			NSTimeInterval longsTerm = [AZDownloadSpeedWatcher timeWithTimeIntervalSinceNow:-AVERAGE_INTERVAL];

			maxAverage = [watcher averageSpeedSince:longsTerm];
			averageSpeed = [watcher averageSpeedSince:shortTerm];

			averageSpeed = MIN(maxAverage, averageSpeed);
			noActivity = averageSpeed < 0.1;
		}

		msleep(0.05);
	}
}

- (void) drawRect:(NSRect)dirtyRect {
	NSRect offsetRect = self.bounds;
	NSInteger offsetX = (appIcon.size.width - offsetRect.size.width) / 2.0;
	NSInteger offsetY = (appIcon.size.height - offsetRect.size.height) / 2.0 - 1.0;

	NSRect sourceRect = NSOffsetRect(dirtyRect, offsetX, offsetY);

	NSUInteger active = [downloads count];
	BOOL isDownloading = !!active;

	float alpha = isDownloading ? 0.5 : 1.0;
	[appIcon drawInRect:dirtyRect fromRect:sourceRect operation:NSCompositeCopy fraction:alpha];

	if (!isDownloading)
		return;

	BOOL isHighlited = NO;

	NSUInteger concurent = MIN(active, 2);

	AZ_Mutable(Array, *percentage);

	NSArray *d = [[downloads allValues] sortedArrayUsingSelector:@selector(compare:)];
	NSUInteger c = [d count];
	d = c ? [d subarrayWithRange:NSMakeRange(0, MIN(concurent, c))] : nil;

	for (AZDownload *download in d) {
		CGFloat percents = download.downloaded / (float)download.totalSize;
		[percentage addObject:@(percents)];
	}

	CGFloat gap = 1.0;
	CGFloat inset = (active < 3) ? 3.0 : 1.0;
	CGRect rect = self.bounds;
	CGRect insetRect = NSInsetRect(rect, inset, inset);
	CGFloat lineH = (insetRect.size.height - gap * (concurent - 1)) / concurent;

	CGRect inrect = insetRect;
	inrect.size.height = (int)lineH;

	for (int i = 0; i < concurent; i++) {
		NSNumber *last = [percentage lastObject];
		if (last)
			[percentage removeObjectIdenticalTo:last];

		CGFloat percents = last ? [last floatValue] : 0.0;

		inrect.origin.y = (int)(inset + gap + i * (lineH + gap));
		[self progress:percents inRect:inrect highlited:isHighlited];
	}

	NSTimeInterval longTerm = [AZDownloadSpeedWatcher timeWithTimeIntervalSinceNow:-(60*5)];
	float longAverage = [[AZDownloadSpeedWatcher sharedSpeedWatcher] averageSpeedSince:longTerm];

	if ((longAverage - 0.01) <= 0)
		return;

	NSString *sLong = [NSString cvtFileSize:longAverage withPrec:1 withLabel:NO];

	NSFont *font = [self bpsFont];
	NSDictionary *outline = @{
															 NSFontAttributeName: font,
															 NSStrokeWidthAttributeName: @(-30.0),
															 NSStrokeColorAttributeName: [NSColor whiteColor],
															 };
	NSDictionary *foreground = @{
															 NSFontAttributeName: font,
															 NSForegroundColorAttributeName: [NSColor blackColor],
//															 NSStrokeWidthAttributeName: @(-1.0),
															 };

	CGSize size = [sLong sizeWithAttributes:foreground];
	CGPoint point = NSMakePoint(rect.origin.x + (rect.size.width - size.width) / 2., rect.origin.y + (rect.size.height - size.height) / 2.);

	[sLong drawAtPoint:point withAttributes:outline];
	[sLong drawAtPoint:point withAttributes:foreground];
}

- (NSFont *) bpsFont {
	static NSFont *font;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    font = [NSFont fontWithName:@"Helvetica" size:10];
	});
	return font;
}

- (void) progress:(CGFloat)progress inRect:(CGRect)rect highlited:(BOOL)isHighlited {
	NSColor *outFrameColor = noActivity ? [NSColor darkGrayColor] : [NSColor blackColor];
	[outFrameColor setFill];
	NSFrameRect(rect);

	if (!noActivity) {
		CGFloat fraction = 0.f;
		@synchronized(self) {
			fraction = averageSpeed / maxAverage;
		}

		NSColor *inFrameColor = [[NSColor redColor] blendedColorWithFraction:fraction ofColor:[NSColor greenColor]];
		[inFrameColor setFill];

		NSFrameRect(NSInsetRect(rect,1.0,1.0));
	}

	NSRect insetRect = NSInsetRect(rect,2.0,2.0);

	NSRect slice, remainder;

	NSDivideRect(insetRect, &slice, &remainder, NSWidth(insetRect) * progress, NSMinXEdge);

	NSColor *sliceColor = noActivity ? [NSColor lightGrayColor] : [NSColor orangeColor];
	NSColor *remainderColor = noActivity ? [NSColor darkGrayColor] : [NSColor blackColor];

	[sliceColor drawSwatchInRect:slice];
	[remainderColor drawSwatchInRect:remainder];
}

- (void) mouseDown:(NSEvent *)theEvent {
	[item popUpStatusItemMenu:[self popupMenu]];
}

- (NSMenu *) popupMenu {
	if (!menu) {
		NSArray *topObjects = nil;
		if ([[NSBundle mainBundle] loadNibNamed:@"StatusMenu" owner:self topLevelObjects:&topObjects]) {
			for (id o in topObjects)
				if ([o isKindOfClass:[NSMenu class]]) {
					menu = o;
					break;
				}
		}
	}
	return menu;
}
- (IBAction)actionArrangeInFront:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
}
- (IBAction)actionShowReader:(id)sender {
	[AZErgoBrowserTab navigateToWithData:nil];
}

- (void) menuNeedsUpdate:(NSMenu *)aMenu {
	NSMenuItem *browserItem = [aMenu itemWithTag:1];
	if (browserItem && [AZErgoBrowserTab sharedTab]) {
		NSString *title = [[AZErgoBrowserTab sharedTab] title];
		if (!title) {
			NSString *uri = [[AZErgoBrowserTab sharedTab] loadedURI];
			title = [self parseBrowserURI:uri];
		}

		[browserItem setEnabled:!!title];
		browserItem.title = title ?: LOC_FORMAT(@"Reader");
	}
}

- (NSString *) parseBrowserURI:(NSString *)uri {
	NSMutableArray *parts = [[uri pathComponents] mutableCopy];
	if ([[parts firstObject] isEqualToString:@"/"])
		[parts shiftObject];

	NSString *root = [[parts shiftObject] lowercaseString];
	if ([root isEqual:@"reader"]) {
		NSString *mangaName = [parts shiftObject];
		AZErgoManga *manga = [AZErgoManga mangaByName:mangaName];
		NSString *title = manga ? manga.mainTitle : [NSString stringWithFormat:@"[%@]", mangaName];

		NSString *chapterIdx = [parts shiftObject];
		if (chapterIdx) {
			NSUInteger idx = _IDX([chapterIdx floatValue]);
			title = [NSString stringWithFormat:@"%@ ⟩ ch. %@", title, @(_IDI(idx))];

			AZErgoUpdateWatch *watch = [AZErgoUpdateWatch any:@"manga ==[c] %@", mangaName];
			for (AZErgoUpdateChapter *chapter in [watch.updates allObjects])
				if (idx == _IDX(chapter.idx)) {
					title = [NSString stringWithFormat:@"%@ %@", title, chapter.title];
					break;
				}
		}
		return title;
	}

	return uri;
}

@end

@implementation AZErgoStatusItem (Delegation)

- (void) download:(AZDownload *)download progressChanged:(double)progress {
	[self redraw];
}

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state {
	NSString *url = download.sourceURL;
	if (!url)
		return;

	if (HAS_BIT(state, AZErgoDownloadStateDownloading))
		downloads[url] = download;
	else
		[downloads removeObjectForKey:url];

	[self redraw];
}

- (void) redraw {
	[[AZDelayableAction shared:@"status-item"] delayed:0.001 execute:^{
		[self setNeedsDisplay:YES];
	}];
}

@end