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
	CGRect rect = self.bounds;

	NSString *text = self.text;
	BOOL drawProgress = !self.maxValue || self.doubleValue < self.maxValue;

	if (!text) {
		if (!drawProgress) {
			text = [NSString cvtFileSize:self.maxValue];
		} else {
			if (self.maxValue) {
				text = self.doubleValue ? [[NSString cvtFileSize:self.doubleValue] stringByAppendingString:@" / "] : @"";
				text = [text stringByAppendingString:[NSString cvtFileSize:self.maxValue]];
			} else
				text = @"";
			}
	}

	NSFrameRect(rect);

	NSDictionary *foreground = (!drawProgress) ? nil : @{
																											 NSForegroundColorAttributeName: [NSColor whiteColor],
																											 NSStrokeWidthAttributeName: @10,
																											 };

	CGSize size = [text sizeWithAttributes:foreground];
	CGPoint point = NSMakePoint(rect.origin.x + (rect.size.width - size.width) / 2., rect.origin.y + (rect.size.height - size.height) / 2.);

	if (drawProgress) {
		NSRect slice, remainder;
		NSRect insetRect = NSInsetRect(rect,2.0,2.0);

		double size = (self.maxValue - self.minValue);
		double percent = size ? (self.doubleValue - self.minValue) / size : 0;

		NSDivideRect(insetRect, &slice, &remainder, NSWidth(insetRect) * percent, NSMinXEdge);

		[[NSColor orangeColor] drawSwatchInRect:slice];
		[[NSColor blackColor] drawSwatchInRect:remainder];

		NSDictionary *background = @{
																 NSForegroundColorAttributeName: [NSColor darkGrayColor],
																 NSStrokeWidthAttributeName: @10,
																 };


		point.y ++;
		point.x ++;
		[text drawAtPoint:point withAttributes:background];

		point.y --;
		point.x --;
	}

	[text drawAtPoint:point withAttributes:foreground];
}

- (void) setText:(NSString *)text {
	if (_text == text)
		return;
	
	_text = text;
	[self setNeedsDisplay:YES];
}

@end
