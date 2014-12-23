//
//  AZProgressIndicator.m
//  ErgoProxy
//
//  Created by Ankh on 16.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZProgressIndicator.h"

@implementation AZProgressIndicator

- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];

	CGRect rect = self.bounds;

	NSRect slice, remainder;
	NSRect insetRect = NSInsetRect(rect,2.0,2.0);

	NSFrameRect(rect);


	double percent = (self.doubleValue - self.minValue) / (self.maxValue - self.minValue);
	NSDivideRect(insetRect, &slice, &remainder, NSWidth(insetRect) * percent, NSMinXEdge);

	[[NSColor orangeColor] drawSwatchInRect:slice];
	[[NSColor blackColor] drawSwatchInRect:remainder];

	NSDictionary *foreground = @{
														NSForegroundColorAttributeName: [NSColor whiteColor],
														NSStrokeWidthAttributeName: @10,
														};
	NSDictionary *background = @{
														NSForegroundColorAttributeName: [NSColor darkGrayColor],
														NSStrokeWidthAttributeName: @10,
														};

	CGSize size = [self.text sizeWithAttributes:foreground];
	CGPoint point = NSMakePoint(rect.origin.x + (rect.size.width - size.width) / 2., rect.origin.y + (rect.size.height - size.height) / 2.);

	point.y ++;
	point.x ++;
	[self.text drawAtPoint:point withAttributes:background];

	point.y --;
	point.x --;
	[self.text drawAtPoint:point withAttributes:foreground];
    // Drawing code here.
}

- (void) setText:(NSString *)text {
	if (_text == text)
		return;

	_text = text;

	[self setNeedsDisplay:YES];
}

@end
