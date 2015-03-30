//
//  AZGroupableDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZGroupableDataSource.h"
#import "AZCoreDataEntity.h"

MULTIDELEGATED_INJECT_MULTIDELEGATED(AZGroupableDataSource)

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

- (id<NSCopying>) orderedUID:(id)item {
	return [item description];
}

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

- (void) expandFirstLevelIn:(NSOutlineView *)outlineView {
	NSArray *sources = [self orderedItemsInGroup:nil];

	for (id item in sources)
		[outlineView expandItem:item expandChildren:NO];
}

- (id) parentOf:(id)item inGroup:(CustomDictionary *)group {
	if (!item)
		return nil;

	group = group ?: self->groups;

	for (id parent in [group allValues])
		if (parent == item)
			return group;
		else
			if ([CustomDictionary isDictionary:parent]) {
				id subparent = [self parentOf:item inGroup:parent];
				if (!!subparent)
					return subparent;
			}

	return nil;
}

- (void) diff:(NSArray *)newData {
	NSSet *old = [NSSet setWithArray:self.data];
	NSMutableSet *deleted = [old mutableCopy];
	NSMutableSet *inserted = [NSMutableSet setWithArray:newData];

	[deleted minusSet:inserted];
	[inserted minusSet:old];

	//	dispatch_async_at_main(^{

	[self.target beginUpdates];

	AZ_Mutable(Dictionary, *deletedItems);
	for (id item in deleted) {
		id parentItem = [self parentOf:item inGroup:nil];
		id parent = parentItem ? ((CustomDictionary *)parentItem)->owner : [NSNull null];

		NSDictionary *r = deletedItems[parent] ?: (deletedItems[parent] = @{@0: parentItem ?: [NSNull null], @1: [NSMutableIndexSet new]});

		NSUInteger index = [self itemIndex:item inGroup:parentItem];
		[r[@1] addIndex:index];
	}

	for (id parent in [deletedItems allKeys]) {
		NSDictionary *r = deletedItems[parent];
		id parentItem = r[@0];
		[self.target removeItemsAtIndexes:r[@1] inParent:parentItem withAnimation:NSTableViewAnimationSlideLeft];
	}

	[self setData:newData];
//	[self.target reloadData];

	AZ_Mutable(Dictionary, *insertedItems);
	for (id item in inserted) {
		id parentItem = [self parentOf:item inGroup:nil];
		id parent = parentItem ? ((CustomDictionary *)parentItem)->owner : [NSNull null];

		NSDictionary *r = insertedItems[parent] ?: (insertedItems[parent] = @{@0: parentItem ?: [NSNull null], @1: [NSMutableIndexSet new]});

		NSUInteger index = [self itemIndex:item inGroup:parentItem];
		[r[@1] addIndex:index];
	}

	for (id parent in [insertedItems allKeys]) {
		NSDictionary *r = insertedItems[parent];
		id parentItem = r[@0];
//		[self.target reloadItem:parentItem];
//		[self.target expandItem:parentItem];
		[self.target insertItemsAtIndexes:r[@1] inParent:parentItem withAnimation:NSTableViewAnimationSlideLeft];
	}

	[self.target endUpdates];
	//	});
}

- (instancetype) setTo:(id)target {
	if ([target respondsToSelector:@selector(setDelegate:)])
		[target setDelegate:self];

	if ([target respondsToSelector:@selector(setDataSource:)])
		[target setDataSource:(id)self];

	self.target = target;

	return self;
}

- (void) reload {
	[self groupData];
	[self sort];
}

- (void) setData:(NSArray *)data {
	if (_data == data)
		return;

	_data = data;
	[self reload];
}

- (void) setGroupped:(BOOL)groupped {
	if (groupped == _groupped)
		return;

	_groupped = groupped;
	[self setData:_data];
}

- (NSArray *) orderedItemsInGroup:(id)group {
	BOOL inGroup = (!!group) && [CustomDictionary isDictionary:group];
	id key = inGroup ? ((CustomDictionary *)group)->owner : @0;
	NSDictionary *mapping = keysMapping[key];

	CustomDictionary *dictionary = (!group) ? groups : group;
	AZ_MutableI(Array, *ordered, arrayWithCapacity:[dictionary count]);

	for (id key in mapping)
		[ordered addObject:dictionary[key]];

	return ordered;
}

- (id) orderedItemAtIndex:(NSInteger)index inGroup:(id)group {
	BOOL inGroup = (!!group) && [CustomDictionary isDictionary:group];
	id key = inGroup ? ((CustomDictionary *)group)->owner : @0;
	NSArray *mapping = keysMapping[key];
	CustomDictionary *dictionary = (!group) ? groups : group;

	if (!group) { // root node
		if (_filter && !index)
			return nil;

		index = index - (_filter ? 1 : 0);
	}

	if ((index < 0) || (index >= [mapping count]))
		return nil;

	return dictionary[mapping[index]];
}

- (NSUInteger) itemIndex:(id)item inGroup:(id)group {
	BOOL inGroup = (!!group) && [CustomDictionary isDictionary:group];

	id key = inGroup ? ((CustomDictionary *)group)->owner : @0;

	CustomDictionary *dictionary = (!group) ? groups : group;

	id key2 = [[dictionary allKeysForObject:item] firstObject];

	NSUInteger index = [keysMapping[key] indexOfObject:key2];

	if (_filter && !group)
		index--;

	return index;
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
	AZConfigurableTableCellView *ucv = sender;
	while (ucv && ![ucv isKindOfClass:[AZConfigurableTableCellView class]]) {
		ucv = (id)((NSView *)ucv).superview;
	}

	return ucv;
}

- (void) setUserInfo:(id)object forKey:(id<NSCopying>)key {
	if (!object)
		return;

	if (!self.userInfo)
		self.userInfo = [NSMutableDictionary new];

	self.userInfo[key] = object;
}

- (id) userInfoForKey:(id<NSCopying>)key {
	return self.userInfo[key];
}

@end

@implementation AZGroupableDataSource (AccessorsBehaviour)

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

- (IBAction) actionDelegatedClick:(id)sender {
	NSString *action = [sender respondsToSelector:@selector(identifier)] ? [sender identifier] : nil;

	[self.md_delegate delegatedAction:[AZActionIntent action:action intentFrom:self withSender:sender]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	NSString *cellType = [self outlineView:outlineView cellTypeForItem:item];

	AZConfigurableTableCellView *cellView = [outlineView makeViewWithIdentifier:cellType owner:self];
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
