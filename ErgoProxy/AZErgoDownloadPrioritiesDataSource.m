//
//  AZErgoDownloadPrioritiesDataSource.m
//  ErgoProxy
//
//  Created by Ankh on 04.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoDownloadPrioritiesDataSource.h"

#import "AZErgoManga.h"

NSString *const LOCAL_REORDER_PASTEBOARD_TYPE = @"AZ_LOCAL_REORDER_PASTEBOARD_TYPE";

@implementation AZErgoDownloadPrioritiesDataSource {
	NSArray *draggedNodes;
}

- (id<NSCopying>) orderedUID:(AZErgoManga *)item {
	if (![item isKindOfClass:[AZErgoManga class]])
		item = [self unfold:item];

	id o = @(item.order);
	DDLogVerbose(@"Order: %@", o);

	return o;
}

- (id) rootNodeOf:(id)item {
	return @"root";
}

- (instancetype) setTo:(id)target {
	[super setTo:target];

	if ([target isKindOfClass:[NSOutlineView class]]) {
		[target registerForDraggedTypes:@[LOCAL_REORDER_PASTEBOARD_TYPE]];

		[target setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
		[target setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
	}

	return self;
}

- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
	NSPasteboardItem *i = [NSPasteboardItem new];
	[i setData:[NSData data] forType:NSPasteboardTypeString];

	return i;
}

- (void) outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
	draggedNodes = draggedItems;
	[session.draggingPasteboard setData:[NSData data] forType:LOCAL_REORDER_PASTEBOARD_TYPE];
}

- (void) outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
	draggedNodes = nil;
}

- (BOOL) dragIsLocalReorder:(id <NSDraggingInfo>)info {
	// It is a local drag if the following conditions are met:
	if ([info draggingSource] == self.target) {

		if (draggedNodes != nil) {
			// Our nodes were saved off
			if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:LOCAL_REORDER_PASTEBOARD_TYPE]] != nil) {
				// Our pasteboard marker is on the pasteboard
				return YES;
			}
		}
	}
	return NO;
}

- (NSDragOperation) outlineView:(NSOutlineView *)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)childIndex {
	NSDragOperation result = NSDragOperationGeneric;

	if (childIndex == NSOutlineViewDropOnItemIndex)
		result = NSDragOperationNone;
	else

	if ([draggedNodes indexOfObjectIdenticalTo:item] != NSNotFound)
		result = NSDragOperationNone;

	return result;
}

- (id) unfold:(id)item {
	while ([CustomDictionary isDictionary:item])
		item = [[((CustomDictionary *)item) allValues] firstObject];

	return item;
}

- (BOOL) outlineView:(NSOutlineView *)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)parent childIndex:(NSInteger)childIndex {
	NSUInteger count = [self.data count];

	if (childIndex < 0)
		childIndex = count;

	AZ_MutableI(Array, *untouched, arrayWithCapacity:count);

	untouched = [self.data mutableCopy];
	[untouched removeObjectsInArray:draggedNodes];

	id pasteAfter = [self unfold:[self orderedItemAtIndex:childIndex - 1 inGroup:parent]];

	NSArray *items = [self orderedItemsInGroup:parent];

	AZ_MutableI(Array, *before, arrayWithCapacity:count);
	AZ_MutableI(Array, *after, arrayWithCapacity:count);
	AZ_MutableI(Array, *tmpOrder, arrayWithCapacity:count);

	NSMutableArray *current = before;

	for (AZErgoManga *item in items) {
		NSUInteger index =
		item.order;
		if (!index)
			index =
			[self.data indexOfObjectIdenticalTo:item] + 1;

		[tmpOrder addObject:@(index)];

    if (!pasteAfter)
			current = after;

		if (![draggedNodes containsObject:item])
			[current addObject:item];

    if (item == pasteAfter)
			current = after;
	}

	AZ_MutableI(Array, *ordered, arrayWithCapacity:[tmpOrder count]);

	NSMutableArray *dublicates = [tmpOrder mutableCopy];

	while ([tmpOrder count] > 0) {
		NSNumber *idx = [tmpOrder firstObject];
		[tmpOrder removeObjectIdenticalTo:idx];

		if ([dublicates containsObject:idx]) {
			[dublicates removeObjectIdenticalTo:idx];
			[ordered addObject:idx];
		}

		if ([dublicates containsObject:idx]) {
			NSUInteger value = [idx unsignedIntegerValue], replacement = 0;
			for (NSNumber *d in dublicates)
				if ((replacement = [d unsignedIntegerValue]) >= value) {
					NSUInteger index = [dublicates indexOfObjectIdenticalTo:d];

					[dublicates replaceObjectAtIndex:index withObject:@(replacement + 1)];
				}
		}
	}

	NSArray *moved = [[before arrayByAddingObjectsFromArray:draggedNodes] arrayByAddingObjectsFromArray:after];

	for (id i in moved) {
    NSUInteger index = [moved indexOfObjectIdenticalTo:i];

		if (index == NSNotFound)
			continue;

		NSNumber *order = ordered[index];

		AZErgoManga *item = [self unfold:i];

		item.order = [order unsignedIntegerValue];
	}

//	[self reload];
//	[self.target beginUpdates];
//
//	for (id item in draggedNodes) {
//    [self.target moveItemAtIndex:[items indexOfObjectIdenticalTo:item]
//												inParent:parent
//												 toIndex:[moved indexOfObjectIdenticalTo:item]
//												inParent:parent];
//	}
//
//	NSArray *classes = [NSArray arrayWithObject:[NSPasteboardItem class]];
//	NSInteger outlineColumnIndex = [[self.target tableColumns] indexOfObject:[self.target outlineTableColumn]];
//	[info enumerateDraggingItemsWithOptions:0 forView:self.target classes:classes searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger index, BOOL *stop) {
//		id node = [draggedNodes objectAtIndex:index];
//		NSInteger row = [self.target rowForItem:node];
//		draggingItem.draggingFrame = [self.target frameOfCellAtColumn:outlineColumnIndex row:row];
//	}];
//
//	[self.target endUpdates];

	dispatch_async_at_background(^{
		[self reload];
		dispatch_async_at_main(^{
			[self.target reloadData];
			[self.target expandItem:nil expandChildren:YES];
		});
	});

	return YES;
}

@end
