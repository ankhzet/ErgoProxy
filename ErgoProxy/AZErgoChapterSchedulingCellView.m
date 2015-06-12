//
//  AZErgoChapterSchedulingCellView.m
//  ErgoProxy
//
//  Created by Ankh on 07.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChapterSchedulingCellView.h"
#import "AZErgoUpdateChapter.h"
#import "AZGroupableDataSource.h"

@interface AZErgoChapterSchedulingCellView ()

@property (nonatomic, weak) AZErgoUpdateChapter *bindedEntity;

@property (nonatomic, weak) IBOutlet NSButton *cbSchedule;
@property (nonatomic, weak) IBOutlet NSTextField *tfChapterID;

@end

@implementation AZErgoChapterSchedulingCellView

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	[super configureForEntity:entity inOutlineView:view];

	NSSet *chapters = [self.dataSource userInfoForKey:@""];

	self.cbSchedule.state = [chapters containsObject:entity] ? NSOnState : NSOffState;
	self.tfChapterID.stringValue = LOC_FORMAT(@"ch. %@", self.bindedEntity.formattedString);
}

- (NSString *) plainTitle {
	return self.bindedEntity.fullTitle;
}

@end
