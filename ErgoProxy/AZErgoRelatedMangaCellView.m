//
//  AZErgoRelatedMangaCellView.m
//  ErgoProxy
//
//  Created by Ankh on 20.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoRelatedMangaCellView.h"
#import "AZErgoMangaCommons.h"
#import "AZGroupableDataSource.h"

NSString *const AZErgoRelatedMangaCellViewTagKey = @"AZErgoRelatedMangaCellViewTagKey";

@interface AZErgoRelatedMangaCellView () {
	__weak AZGroupableDataSource *dataSource;
}

@property(weak) IBOutlet NSButton *checked;

@end

@implementation AZErgoRelatedMangaCellView

- (void) configureForEntity:(AZErgoManga *)entity inOutlineView:(NSOutlineView *)view {
	self.bindedEntity = entity;

	NSArray *titles = entity.additionalTitles;
	NSString *subtitles = (![titles count]) ? @"" : [NSString stringWithFormat:@" (%@)", [titles firstObject]];
	NSString *title = [NSString stringWithFormat:@"%@%@", entity.mainTitle ?: @"<no title>", subtitles];
	self.textField.stringValue = title;

	NSArray *tags = [(dataSource = (id)view.dataSource) userInfoForKey:AZErgoRelatedMangaCellViewTagKey];
	NSSet *tagsSet = (![tags count]) ? [NSSet new] : [NSSet setWithArray:tags];

	self.isChecked = [tagsSet isSubsetOfSet:entity.tags];
}

- (BOOL) isChecked {
	return self.checked.state == NSOnState;
}

- (void) setIsChecked:(BOOL)isChecked {
	[self.checked setState:isChecked ? NSOnState : NSOffState];
}

@end
