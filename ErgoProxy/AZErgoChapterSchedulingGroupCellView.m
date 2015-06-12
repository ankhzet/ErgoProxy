//
//  AZErgoChapterSchedulingGroupCellView.m
//  ErgoProxy
//
//  Created by Ankh on 07.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChapterSchedulingGroupCellView.h"

#import "AZGroupableDataSource.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoManga.h"

@interface AZErgoChapterSchedulingGroupCellView ()

@property (nonatomic, weak) IBOutlet NSButton *cbSchedule;

@property (nonatomic, weak) ItemsDictionary *bindedEntity;

@end

@implementation AZErgoChapterSchedulingGroupCellView

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	[super configureForEntity:entity inOutlineView:view];

	NSSet *schedulableChapters = [self.dataSource userInfoForKey:@""];

	NSSet *allChapters = [NSSet setWithArray:[entity allValues]];

	self.cbSchedule.state = ([schedulableChapters isEqual:allChapters]) ? NSOnState : NSOffState;
}

- (NSString *) plainTitle {
	if ([ItemsDictionary isDictionary:self.bindedEntity]) {
		AZErgoUpdateChapter *chapter = [[self.bindedEntity allValues] firstObject];
		return [chapter.watch.relatedManga description];
	}

	return [super plainTitle];
}

@end
