//
//  AZErgoScanView.m
//  ErgoProxy
//
//  Created by Ankh on 18.05.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoScanView.h"

@implementation AZErgoScanHelper

@end

@interface AZErgoScanView () {
	NSMutableDictionary *scanHelpers;
}

@end

@implementation AZErgoScanView

- (id)initWithFrame:(NSRect)frameRect {
	if (!(self = [super initWithFrame:frameRect]))
		return self;

	self.gutter = 16;
	self.gutterEdge = NSMaxXEdge;
	return self;
}

- (void) setScans:(NSUInteger)scans {
	scanHelpers = [NSMutableDictionary new];

	_scans = scans;
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	
	NSRect displayRect = [self displayRect];

	if (![self needsToDrawRect:displayRect])
		return;

	if (!self.scans)
		return;

	NSRect rect = NSZeroRect;
	rect.size = displayRect.size;
	rect = NSInsetRect(rect, (int)(rect.size.width * 0.1), (int)(rect.size.height * 0.1));

	NSInteger dirX = 0, dirY = 0;
	NSInteger stepX = rect.size.width;
	NSInteger stepY = rect.size.height;

	if (displayRect.size.width >= displayRect.size.height) {
		dirX = 1;
		stepX = (int)(stepX / self.scans);
		stepY = 0;
		rect.size.width = stepX;
	} else {
		dirY = 1;
		stepY = (int)(stepY / self.scans);
		stepX = 0;
		rect.size.height = stepY;
	}


	NSColor *cached = [NSColor grayColor];
	NSColor *caching = [NSColor lightGrayColor];
	NSColor *shown = [NSColor whiteColor];

	NSInteger insetCached = 1;
	NSInteger insetShown = 2;
	for (int i = 0; i < self.scans; i++) {

		BOOL isCached = !!scanHelpers[@(i)];

		NSColor *cachedColor = isCached ? cached : caching;
		[cachedColor setFill];

		NSInteger cachedInsetSize = isCached ? insetCached : insetCached * 2;
		NSRect cachedMark = NSInsetRect(rect, cachedInsetSize, cachedInsetSize);
		NSRectFill(cachedMark);

		if (i <= self.currentScan) {
			NSRect shownMark = NSInsetRect(rect, insetShown, insetShown);
			[shown setFill];
			NSRectFill(shownMark);
		}

		rect.origin.x += (int)stepX;
		rect.origin.y += (int)stepY;
	}

}

- (NSRect) displayRect {
	NSRect rect = self.bounds, slice, remainder;

	NSDivideRect(rect, &slice, &remainder, self.gutter, self.gutterEdge);

	return slice;
}

- (void) redrawGutter {
	dispatch_at_main(^{
		[self setNeedsDisplayInRect:[self displayRect]];
		[[AZDelayableAction shared:@"cached-gutter-redisplay"] delayed:0.1 execute:^{
			[self display];
		}];
	});
}

- (void) scan:(NSUInteger)scan cached:(AZErgoScanHelper *)helper {
	scanHelpers[@(scan)] = helper;

	[self redrawGutter];
}

- (void) scan:(NSUInteger)scan shown:(AZErgoScanHelper *)helper {
	self.currentScan = scan;

	[self redrawGutter];
}

@end
