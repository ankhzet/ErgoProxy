//
//  AZErgoUpdateChapter.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdateChapter.h"

@implementation AZErgoUpdateChapter
@dynamic watch, title, genData, idx, volume, date, downloads;
@synthesize state, mangaName;

- (float) baseIdx {
	return self.idx;
}

- (BOOL) isDummy {
	return self.idx < 0;
}

- (BOOL) isBonus {
	return !!((int)(self.idx * 10) % 10);
}

- (NSComparisonResult) compare:(AZErgoUpdateChapter *)another {
	return (!!another) ? SIGN(self.idx - another.idx) : NSOrderedAscending;
}

@end

@implementation AZErgoUpdateChapter (Formatting)

- (NSString *) formattedString {
	return self.isBonus ? [NSString stringWithFormat:@"%.1f", self.idx] : [@((int)(self.idx)) stringValue];
}

- (NSString *) fullTitle {
	BOOL dummy = self.isDummy;

	NSString *title = self.title;

	if (!![title length]) {
		if (!dummy)
			title = [@"- " stringByAppendingString:title];
	} else
			title = @"";

	if (!dummy)
		title = [NSString stringWithFormat:@"v %d\t  ch %@\t  %@", (int)self.volume, [self formattedString], title];

	return title;
}

@end