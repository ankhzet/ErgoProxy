//
//  AZErgoUpdatesDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesDataSource.h"

#import "AZErgoUpdatesDataSource.h"
#import "AZErgoUpdatesSourceDescription.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdateChapter.h"

#import "AZErgoUpdatesGroupCellView.h"

@implementation AZErgoUpdateActionIntent
@synthesize action, initiator, source, initiatorContainedBy, initiatorRelatedEntity;

+ (instancetype) action:(NSString *)action intentFrom:(AZErgoUpdatesDataSource *)source withSender:(id)sender {
	AZErgoUpdateActionIntent *intent = [self new];

	intent->action = action;
	intent->source = source;
	intent->initiator = sender;

	AZErgoUpdatesCellView *container = [source cellViewFromSender:sender];

	intent->initiatorContainedBy = container;
	intent->initiatorRelatedEntity = container.bindedEntity;

	return intent;
}

- (BOOL) is:(NSString *)actionIdentifier {
	return (action == actionIdentifier) || [action isEqualToString:actionIdentifier];
}

@end

@implementation AZErgoUpdatesDataSource

- (CGFloat) cellHeight:(id)item {
	return 24.0;
}

- (CGFloat) groupCellHeight:(id)item {
	return 24.0;
}

- (NSString *) rootIdentifierFromItem:(id)item {
	return ((AZErgoUpdatesSourceDescription *)[self rootNodeOf:item]).serverURL;
}

- (NSString *) groupIdentifierFromItem:(id)item {
	return ((AZErgoUpdateWatch *)[self groupNodeOf:item]).manga;
}

- (id) rootNodeOf:(AZErgoUpdateChapter *)item {
	return item.watch.source;
}

- (id) groupNodeOf:(AZErgoUpdateChapter *)item {
	return item.watch;
}

- (NSNumber *) orderedUID:(AZErgoUpdateChapter *)item {
	return @(item.volume * 10000 + item.idx);
}

- (NSArray *) sort:(CustomDictionary *)group keys:(NSArray *)keys {
	return [[[keys sortedArrayUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return self.expanded ? [CustomDictionary isDictionary:item] : [item isKindOfClass:[GroupsDictionary class]];
}

- (IBAction) actionDelegatedClick:(id)sender {
	if (!self.delegate)
		return;

	NSString *action = [sender respondsToSelector:@selector(identifier)] ? [sender identifier] : nil;

	[self.delegate delegatedAction:[AZErgoUpdateActionIntent action:action intentFrom:self withSender:sender]];
}

@end
