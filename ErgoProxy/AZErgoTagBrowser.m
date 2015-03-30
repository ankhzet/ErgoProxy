//
//  AZErgoTagBrowser.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoTagBrowser.h"
#import "AZErgoTagsDataSource.h"
#import "AZErgoRelatedMangaCellView.h"
#import "AZErgoTagCellView.h"

@interface AZErgoTagBrowser () <AZErgoTagsDataSourceDelegate> {
	AZGroupableDataSource *relatedManga;

	BOOL showOnlyRelatedManga;

	NSArray *pickedTags;
}

@property (weak) IBOutlet NSOutlineView *ovTags;

@property (weak) IBOutlet NSTextField *tfTagName;
@property (unsafe_unretained) IBOutlet NSTextView *tvTagAnnotation;
@property (weak) IBOutlet NSTextField *tfTagGuid;
@property (weak) IBOutlet NSButton *cbSkipTaggedManga;

@property (weak) IBOutlet NSButton *bTagAdd;

@property (weak) IBOutlet NSOutlineView *ovRelatedManga;
@property (weak) IBOutlet NSButton *cbFilterRelatedManga;


@property (nonatomic) AZErgoTagsDataSource *tags;

@end

MULTIDELEGATED_INJECT_LISTENER(AZErgoTagBrowser)

@implementation AZErgoTagBrowser
@synthesize tags = _tags;

- (NSString *) tabIdentifier {
	return AZEPUIDTagBrowserTab;
}

- (AZErgoTagsDataSource *) tags {
	if (!_tags) {
		_tags = (id)self.ovTags.dataSource;
		_tags.groupped = NO;
		[self bindAsDelegateTo:_tags solo:NO];
	}

	return _tags;
}

- (void) show {
	[self tags];

	if (!relatedManga) {
		relatedManga = (id)self.ovRelatedManga.dataSource;
		relatedManga.groupped = NO;

		[self bindAsDelegateTo:relatedManga solo:NO];
	}

	[super show];
}

- (void) updateContents {
	showOnlyRelatedManga = self.cbFilterRelatedManga.state == NSOnState;

	if (self.navData) {
		AZErgoManga *manga = [AZErgoManga mangaByName:self.navData];
		pickedTags = [manga.tags allObjects];
	}

	[self delayedFetch:YES];
}

- (void) delayedFetch:(BOOL)full {
	[self delayed:@"tags-fetch" withBlock:^{
		[self fetchTags:full];
	}];
}

- (void) fetchTags:(BOOL)full {
	NSArray *fetch = [AZErgoMangaTag all];
	self.tags.data = fetch;

	[self.ovTags performWithSavedScroll:^{
		[self.ovTags reloadData];
		[self.ovTags expandItem:nil expandChildren:YES];

		if ([pickedTags count]) {
			NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
			for (id tag in pickedTags) {
				[indexSet addIndex:[self.ovTags rowForItem:tag]];
			}
			[self.ovTags selectRowIndexes:indexSet byExtendingSelection:NO];
			[self pickTagsAndFetch:NO];
		}
	}];

}

- (IBAction)actionTagAdd:(id)sender {
	NSString *tagName = self.tfTagName.stringValue;

	if (!tagName)
		return;

	NSString *annotation = [self.tvTagAnnotation.string copy] ?: @"";

	NSString *tagGuidText = self.tfTagGuid.stringValue ?: @"";
	NSNumber *tagGuid = (!![tagGuidText length]) ? @([tagGuidText integerValue]) : nil;

	AZErgoMangaTag *tag = [AZErgoMangaTag unique:[NSPredicate predicateWithFormat:@"tag ==[c] %@", tagName] initWith:nil];

	tag.tag = tagName;
	tag.annotation = annotation;
	tag.guid = tagGuid;
	tag.skip = self.cbSkipTaggedManga.state == NSOnState;

	self.tfTagName.stringValue = @"";
	self.tvTagAnnotation.string = @"";
	self.cbSkipTaggedManga.state = NSOffState;

	pickedTags = @[tag];
	[self pickTagsAndFetch:YES];
}

- (void) pickTagsAndFetch:(BOOL)doFetch {
	BOOL oneTag = [pickedTags count] == 1;
	if (oneTag) {
		AZErgoMangaTag *pickedTag = [pickedTags firstObject];

		self.tfTagName.stringValue = pickedTag.tag ?: @"<unset>";
		self.tvTagAnnotation.string = pickedTag.annotation ?: @"";
		self.tfTagGuid.stringValue = [pickedTag.guid stringValue] ?: @"";
		self.cbSkipTaggedManga.state = pickedTag.skip ? NSOnState : NSOffState;
	} else {
		self.tfTagName.stringValue = @"";
		self.tvTagAnnotation.string = @"";
		self.tfTagGuid.stringValue = @"";
		self.cbSkipTaggedManga.state = NSOffState;
	}


	[self fetchRelated];

	if (doFetch) {
		[self delayedFetch:YES];
	}
}

- (void) fetchRelated {
	[self delayed:@"fetch-manga" withBlock:^{
		NSMutableSet *cross = nil;
		for (AZErgoMangaTag *tag in pickedTags) {
			if (![cross count])
				cross = [tag.manga mutableCopy];
			else
				[cross intersectSet:tag.manga];
		}

		NSArray *tagged = [cross allObjects];
		if (!showOnlyRelatedManga) {
			NSMutableArray *mangas = [[AZErgoManga all] mutableCopy];
			[mangas removeObjectsInArray:tagged];
			tagged = [tagged arrayByAddingObjectsFromArray:mangas];
		}

		relatedManga.data = tagged;
		[relatedManga setUserInfo:pickedTags forKey:AZErgoRelatedMangaCellViewTagKey];

		[self.ovRelatedManga performWithSavedScroll:^{
			[self.ovRelatedManga reloadData];
			[self.ovRelatedManga expandItem:nil expandChildren:YES];

			if (self.navData) {
				AZErgoManga *manga = [AZErgoManga mangaByName:self.navData];
				NSInteger row = [self.ovRelatedManga rowForItem:manga];
				if (row >= 0)
					[self.ovRelatedManga selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			}
		}];
	}];

}

- (void) tagSelected:(AZErgoMangaTag *)tag {
	if (!tag)
		pickedTags = nil;

	if (![tag isKindOfClass:[AZErgoMangaTag class]])
		return;

	if (!pickedTags)
		pickedTags = @[tag];
	else
		pickedTags = [pickedTags arrayByAddingObject:tag];

	[self pickTagsAndFetch:NO];
}

- (void) tagDeleted:(AZErgoMangaTag *)tag {
	if (![tag isKindOfClass:[AZErgoMangaTag class]])
		return;

	[tag delete];
	[self delayedFetch:YES];
}

- (IBAction)actionDelegatedClick:(id)sender {

	while (sender && ![sender isKindOfClass:[AZErgoRelatedMangaCellView class]])
		sender = [sender superview];

	if (!sender)
		return;

	AZErgoRelatedMangaCellView *view = (id)sender;

	for (AZErgoMangaTag *tag in pickedTags) {
		[(id)view.bindedEntity toggle:view.isChecked tag:tag];


		NSInteger row = [self.ovTags rowForItem:tag];
		if (row >= 0) {
			AZErgoTagCellView *view = [self.ovTags viewAtColumn:0 row:row makeIfNecessary:NO];
			if (!!view) {
				[view configureForEntity:tag inOutlineView:self.ovTags];
			}
		}
	}
}

- (IBAction)actionToggleFilter:(id)sender {
	showOnlyRelatedManga = [sender state] == NSOnState;

	[self fetchRelated];
}

@end
