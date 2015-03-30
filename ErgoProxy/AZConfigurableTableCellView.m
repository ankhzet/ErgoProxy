//
//  AZConfigurableTableCellView.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZConfigurableTableCellView.h"
#import "CustomDictionary.h"
#import "KeyedHolder.h"

#import "AZMultipleTargetDelegate.h"

MULTIDELEGATED_INJECT_LISTENER(AZConfigurableTableCellView)

@implementation AZConfigurableTableCellView
@synthesize bindedEntity = _bindedEntity;

- (void) setBindedEntity:(id)bindedEntity {
	if (bindedEntity == _bindedEntity)
		return;

	_bindedEntity = bindedEntity;

	if ([_bindedEntity supportsMultiDelegating])
		[self bindAsDelegateTo:_bindedEntity solo:YES];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	BOOL isDark = backgroundStyle == NSBackgroundStyleDark;
	//	if (!isDark) color = self.textField.textColor;
	//	self.textField.textColor = isDark ? [color highlightWithLevel:0.1] : color;

	[super setBackgroundStyle:isDark?NSBackgroundStyleLowered|NSBackgroundStyleDark:backgroundStyle];
}

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	self.textField.stringValue = [self plainTitle] ?: @"";
}

- (NSString *) plainTitle {
	if ([CustomDictionary isDictionary:self.bindedEntity]) {
		KeyedHolder *holder = ((CustomDictionary *)self.bindedEntity)->owner;
		id object = holder->holdedObject;
		return [object isKindOfClass:[NSString class]] ? [object uppercaseFirstCharString] : [object description];
	}

	return [self.bindedEntity description] ?: @"<!plain title unavailable>";
}

@end
