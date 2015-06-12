//
//  AZErgoChaptersSchedulingPopover.m
//  ErgoProxy
//
//  Created by Ankh on 06.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChaptersSchedulingPopover.h"
#import "AZErgoUpdatesDataSource.h"
#import "AZErgoUpdateChapter.h"

#import "AZErgoSchedulingQueue.h"

@interface AZErgoChaptersSchedulingPopover () <AZActionDelegate> {
	NSMutableSet *schedulableChapters;
}

@property (weak) IBOutlet NSOutlineView *ovChaptersView;

@property (nonatomic) AZErgoUpdatesDataSource *dataSource;

@end

MULTIDELEGATED_INJECT_LISTENER(AZErgoChaptersSchedulingPopover)

@implementation AZErgoChaptersSchedulingPopover

+ (NSString *) nibName {
	return @"ChapterSchedulingPopover";
}

- (NSRectEdge) preferredEdge {
	return NSMaxXEdge;
}

- (AZErgoUpdatesDataSource *) dataSource {
	if (!_dataSource) {
		_dataSource = (id)self.ovChaptersView.dataSource;
		_dataSource.groupped = YES;
		_dataSource.filter = NO;
		_dataSource.expanded = YES;
		[self bindAsDelegateTo:_dataSource solo:NO];

		schedulableChapters = [NSMutableSet new];
		[_dataSource setUserInfo:schedulableChapters forKey:@""];
	}

	return _dataSource;
}

- (void) setAssociatedData:(id)associatedData {
	if (self.dataSource.data) {
		associatedData = [NSMutableArray arrayWithArray:associatedData];
		[associatedData addObjectsFromArray:self.dataSource.data];
	}

	[super setAssociatedData:associatedData];
	[schedulableChapters addObjectsFromArray:self.associatedData];

	self.dataSource.data = self.associatedData;

//	[[AZDelayableAction shared:@"chapter-scheduling-popover"] delayed:0.0 execute:^{
		[self.ovChaptersView reloadData];
		[self.ovChaptersView expandItem:nil expandChildren:YES];
//	}];
}

- (IBAction)actionScheduleChapters:(id)sender {
	for (AZErgoUpdateChapter *chapter in [[schedulableChapters allObjects] sortedArray])
		[[AZErgoSchedulingQueue sharedQueue] queueChapterDownloadTask:chapter];

	[self close];
}

- (void) delegatedAction:(AZActionIntent *)action {
	if ([action is:@"schedulable"])
		[self mark:action.initiatorRelatedEntity schedulable:action.isCheckboxInitiatorChecked];
}

- (void) mark:(id)entity schedulable:(BOOL)schedulable {
	if ([CustomDictionary isDictionary:entity]) {
		for (id sub in [entity allValues])
			[self mark:sub schedulable:schedulable];
	} else
		if ([entity isKindOfClass:[AZErgoUpdateChapter class]]) {
			if (schedulable)
				[schedulableChapters addObject:entity];
			else
				[schedulableChapters removeObject:entity];

			NSInteger row = [self.ovChaptersView rowForItem:entity];
			if (row >= 0) {
				AZConfigurableTableCellView *cellView = [self.ovChaptersView viewAtColumn:0 row:row makeIfNecessary:NO];

				[cellView reload];
			}
		}
}

- (void)popoverDidClose:(NSNotification *)notification {
	[schedulableChapters removeAllObjects];
	self.dataSource.data = nil;
}

@end
