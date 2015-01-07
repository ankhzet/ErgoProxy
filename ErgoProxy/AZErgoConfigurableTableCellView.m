//
//  AZErgoConfigurableTableCellView.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoConfigurableTableCellView.h"
#import "CustomDictionary.h"
#import "KeyedHolder.h"

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

- (NSString *) plainTitle {
	if ([CustomDictionary isDictionary:self.bindedEntity]) {
		KeyedHolder *holder = ((CustomDictionary *)self.bindedEntity)->owner;
		id object = holder->holdedObject;
		return [object isKindOfClass:[NSString class]] ? [object capitalizedString] : [object description];
	}

	return [self.bindedEntity description] ?: @"<!plain title unavailable>";
}

@end
