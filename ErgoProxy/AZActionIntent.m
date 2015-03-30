//
//  AZActionIntent.m
//  ErgoProxy
//
//  Created by Ankh on 20.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZActionIntent.h"
#import "AZGroupableDataSource.h"

@implementation AZActionIntent
@synthesize action, modifiers, initiator, source, initiatorContainedBy, initiatorRelatedEntity;

+ (instancetype) action:(NSString *)action intentFrom:(AZGroupableDataSource *)source withSender:(id)sender {
	AZActionIntent *intent = [self new];

	intent->action = action;
	intent->modifiers = [NSEvent modifierFlags];
	intent->source = source;
	intent->initiator = sender;

	AZConfigurableTableCellView *container = [source cellViewFromSender:sender];

	intent->initiatorContainedBy = container;
	intent->initiatorRelatedEntity = container.bindedEntity;

	return intent;
}

- (BOOL) is:(NSString *)actionIdentifier {
	return (action == actionIdentifier) || [action isEqualToString:actionIdentifier];
}

- (BOOL) key:(NSUInteger)mask {
	return HAS_BIT(self->modifiers, mask);
}

@end

