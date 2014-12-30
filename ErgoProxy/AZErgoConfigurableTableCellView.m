//
//  AZErgoConfigurableTableCellView.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoConfigurableTableCellView.h"

@implementation AZErgoConfigurableTableCellView
@synthesize bindedEntity;

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	BOOL isDark = backgroundStyle == NSBackgroundStyleDark;
	//	if (!isDark) color = self.textField.textColor;
	//	self.textField.textColor = isDark ? [color highlightWithLevel:0.1] : color;

	[super setBackgroundStyle:isDark?NSBackgroundStyleLowered|NSBackgroundStyleDark:backgroundStyle];
}

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	bindedEntity = entity;
}



@end
