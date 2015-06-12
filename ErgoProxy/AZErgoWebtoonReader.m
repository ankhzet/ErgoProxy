//
//  AZErgoWebtoonReader.m
//  ErgoProxy
//
//  Created by Ankh on 28.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoWebtoonReader.h"
#import "AZErgoReaderContentProvider.h"
#import "AZErgoManga.h"

@implementation AZErgoWebtoonReader {
	CGFloat contentHeight;
}

- (CGSize) shrinkenFit:(NSImage *)source {
//	CGSize outS = self.contentView.bounds.size;
	CGSize inpS = source.size;

	CGFloat maxWidth = 500.f;

	BOOL tooWide = maxWidth < inpS.width;
	BOOL needRescale = tooWide;

	if (needRescale) {
		float aspect = inpS.width / inpS.height;
		if (tooWide) {
			inpS.width = (int) maxWidth;
			inpS.height = (int) (inpS.width / aspect);
		}

		[source setSize:inpS];
		[source recache];
	}

	return inpS;
}

- (CGSize) contentSize {
	CGSize size = self.contentView.frame.size;
	size.height = contentHeight;
	return size;
}

- (void) scanCached:(id)uid {
	[super scanCached:uid];

	NSImageView *holder = [self holderOfContent:uid];
	NSImage *image = [self.contentProvider contentOf:uid];

	[holder setFrameSize:image.size];

	contentHeight = 0.f;
	for (NSImageView *holder in [self.contentView subviews]) {
		NSImage *image = holder.image;
		BOOL loaded = !image.name;

		if (loaded) {
//			[holder setNeedsDisplay:YES];
			contentHeight += image.size.height;
		}
	}
}

- (void) updateScanView:(id)uid {
	
}

- (void) alignViewTree:(NSView *)contentTree withContents:(NSArray *)content withNodes:(NSArray *)contentNodes {
	[contentTree setSubviews:@[]];

	[contentTree setFrameSize:NSMakeSize(20000, 100000)];

	if (![contentNodes count])
		return;

	NSDictionary *map = [contentNodes mapWithKeyFromValueMapper:^id(id entity) {
		return [NSString stringWithFormat:@"node%@", @([contentNodes indexOfObjectIdenticalTo:entity])];
	}];

	NSArray *nodes = [[map allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSString *format = [NSString stringWithFormat:@"V:|[%@]|", [nodes componentsJoinedByString:@"]["]];

	[contentTree setSubviews:contentNodes];
	[contentTree addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format
																																			options:0
																																			metrics:nil
																																				views:map]];

	for (NSView *node in contentNodes) {
		[contentTree addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[node]|"
																																				options:0 metrics:0
																																					views:NSDictionaryOfVariableBindings(node)]];
	}
}

@end
