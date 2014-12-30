//
//  AZGroupableDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZGroupableDataSource.h"
#import "AZCoreDataEntity.h"

@implementation AZGroupableDataSource (Groupping)

- (NSString *) rootIdentifierFromItem:(id)item {
	return [[self rootNodeOf:item] description];
}

- (NSString *) groupIdentifierFromItem:(id)item {
	return [[self groupNodeOf:item] description];
}

- (NSString *) itemIdentifierFromItem:(id)item {
	return [NSString stringWithFormat:@"%@ %@", [self rootIdentifierFromItem:item], [self groupIdentifierFromItem:item]];
}

- (id) rootNodeOf:(id)item {
	return item;
}

- (id) groupNodeOf:(id)item {
	return item;
}

- (NSNumber *) orderedUID:(id)item {
	return nil;
}

#define GET_OR_INIT(_left, _init)\
({(_left) ?: ((_left) = (_init));})

- (void) groupData {
	_fetch = [NSMutableDictionary dictionary];
	for (id item in self.data) {
		id identifier = [self rootIdentifierFromItem:item];

		if (!identifier)
			continue;

//		if (!identifier && [item isKindOfClass:[CoreDataEntity class]])
//			[(CoreDataEntity *)item delete];
//		else
		{
//			NSAssert(!!identifier, @"Can't aquire identifier for item root");

			NSMutableArray *rootNodeGroup = GET_OR_INIT(_fetch[identifier], [NSMutableArray array]);
			[rootNodeGroup addObject:item];
		}
	}

	NSMutableDictionary *cachedHolders = [NSMutableDictionary dictionary];

	rootNodes = [RootDictionary custom:nil];
	for (NSArray *rootNode in [_fetch allValues]) {
		for (id item in rootNode) {
			NSString *rootIdentifier = [self rootIdentifierFromItem:item];

			RootHolder *rootNodeHolder = GET_OR_INIT(cachedHolders[rootIdentifier], [RootHolder holderFor:[self rootNodeOf:item]]);

			Class c = self.groupped ? [GroupsDictionary class] : [ItemsDictionary class];
			ItemsDictionary *items = GET_OR_INIT(rootNodes[rootNodeHolder], [c custom:rootNodeHolder]);

			if (self.groupped) {
				id itemIdx = [self itemIdentifierFromItem:item];

				GroupHolder *groupNodeHolder = GET_OR_INIT(cachedHolders[itemIdx], [GroupHolder holderFor:[self groupNodeOf:item]]);

				items = GET_OR_INIT(items[groupNodeHolder], [ItemsDictionary custom:groupNodeHolder]);
			}

			items[[self orderedUID:item]] = item;
		}
	}

	groups = rootNodes;
}

@end

@implementation AZGroupableDataSource

- (void) reload {
	id data = _data;
	_data = nil;

	[self setData:data];
}

- (void) setData:(NSArray *)data {
	if (_data == data)
		return;

	_data = data;
	[self groupData];
	[self sort];
}

- (void) setGroupped:(BOOL)groupped {
	if (groupped == _groupped)
		return;

	_groupped = groupped;
	[self setData:_data];
}

- (void) sort {
	keysMapping = [NSMutableDictionary dictionary];
	keysMapping[@0] = [self sortDictionary:groups];
}

- (NSArray *) sort:(CustomDictionary *)group keys:(NSArray *)keys {
	return [keys sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *) sortDictionary:(CustomDictionary *)dic {
	for (id key in [dic allKeys])
		if ([CustomDictionary isDictionary:dic[key]])
			keysMapping[key] = [self sortDictionary:dic[key]];

	NSArray *keys = dic ? [self sort:dic keys:[dic allKeys]] : @[];
	return keys;
}

- (CGFloat) groupCellHeight:(id)item {
	return 20.f;
}

- (CGFloat) cellHeight:(id)item {
	return 24.f;
}

- (NSString *) outlineView:(NSOutlineView *)outlineView cellTypeForItem:(id)item {
	NSString *cellType = @"ItemCell";

	if (item == outlineView)
		cellType = @"HeaderCell";
	else
		if ([CustomDictionary isDictionary:item])
			cellType = @"GroupCell";

	return cellType;
}

- (id) findOutlineItem:(id)item recursive:(id)holder {
	holder = holder ?: rootNodes;

	for (id holded in [holder allValues])
		if ([CustomDictionary isDictionary:holded]) {
			KeyedHolder *owner = ((CustomDictionary *)holded)->owner;

			if ([KeyedHolder isA:owner] && (owner->holdedObject == item))
				return holded;

			id finded = [self findOutlineItem:item recursive:holded];
			if (!!finded)
				return finded;
		} else
			if (holded == item)
				return item;

	return nil;
}

- (id) cellViewFromSender:(id)sender {
	AZErgoConfigurableTableCellView *ucv = sender;
	while (ucv && ![ucv isKindOfClass:[AZErgoConfigurableTableCellView class]]) {
		ucv = (id)((NSView *)ucv).superview;
	}

	return ucv;
}

@end

@implementation AZGroupableDataSource (DelegateAndDatasource)

- (IBAction) actionDelegatedClick:(id)sender {

}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	NSString *cellType = [self outlineView:outlineView cellTypeForItem:item];

	AZErgoConfigurableTableCellView *cellView = [outlineView makeViewWithIdentifier:cellType owner:self];
	[cellView configureForEntity:item inOutlineView:outlineView];

	return cellView;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSInteger count = 0;

	if (!item) // if root node
		count = [groups count] + (_filter ? 1 : 0);
	else
		if ([CustomDictionary isDictionary:item])
			count = [item count];

	return count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if (!item) { // root node
		if (_filter && !index)
			return outlineView;

		index = index - (_filter ? 1 : 0);
		return groups[keysMapping[@0][index]];
	}

	if ([CustomDictionary isDictionary:item]) {
		id key = ((CustomDictionary *)item)->owner;
		return item[keysMapping[key][index]];
	}

	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return [CustomDictionary isDictionary:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return [CustomDictionary isDictionary:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
	return [self outlineView:outlineView isItemExpandable:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	if ([CustomDictionary isDictionary:item])
		return ((CustomDictionary *)item)->owner;

	return item;
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	return ([CustomDictionary isDictionary:item] || [item isKindOfClass:[NSOutlineView class]])
	? [self groupCellHeight:item]
	: [self cellHeight:item];
}

@end
