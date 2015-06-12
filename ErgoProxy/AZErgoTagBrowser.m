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

#import "AZErgoTabsComons.h"

#import "AZErgoTemplateProcessor.h"
#import "AZErgoSubstitutioner.h"
#import "AZErgoMangaDataSupplier.h"
#import "AZErgoUpdatesCommons.h"

@interface AZErgoTagBrowser () <AZErgoTagsDataSourceDelegate, AZActionDelegate> {
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

+ (NSString *) tabIdentifier {
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

	AZErgoMangaTag *tag = [AZErgoMangaTag unique:AZF_ALL_OF(@"tag ==[c] %@", tagName) initWith:nil];

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
		NSArray *tagged;

		if (!![pickedTags count]) {
			NSMutableSet *cross = nil;
			for (AZErgoMangaTag *tag in pickedTags) {
				if (![cross count])
					cross = [tag.manga mutableCopy];
				else
					[cross intersectSet:tag.manga];
			}

			tagged = [cross allObjects];
			if (!showOnlyRelatedManga) {
				NSMutableArray *mangas = [[AZErgoManga all] mutableCopy];
				[mangas removeObjectsInArray:tagged];
				tagged = [tagged arrayByAddingObjectsFromArray:mangas];
			}
		} else {
			tagged = [AZErgoManga all];

			NSArray *tags = [AZErgoMangaTag fetch:AZF_ALL_OF(@"skip > 0")];
			if ([tags count]) {
				NSMutableArray *mfetch = [tagged mutableCopy];
				for (AZErgoMangaTag *tag in tags)
					[mfetch removeObjectsInArray:[tag.manga allObjects]];

				tagged = mfetch;
			}

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

	if (![tag isKindOfClass:[AZErgoMangaTag class]]) {
		[self fetchRelated];
		return;
	}

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

	pickedTags = [pickedTags mutableCopy];
	[(id)pickedTags removeObject:tag];

	[self delayedFetch:YES];
}

- (void) delegatedAction:(AZActionIntent *)action {
	if ([action is:@"delete"]) {
		[self tagDeleted:action.initiatorRelatedEntity];
	}

	if ([action is:@"check"]) {
		if (!action.initiator)
			return;

		AZErgoRelatedMangaCellView *mangaCellView = (id)action.initiatorContainedBy;
		BOOL checked = mangaCellView.isChecked;

		for (AZErgoMangaTag *tag in pickedTags) {
			[action.initiatorRelatedEntity toggle:checked tag:tag];

			NSInteger row = [self.ovTags rowForItem:tag];
			if (row >= 0) {
				AZErgoTagCellView *tagCellView = [self.ovTags viewAtColumn:0 row:row makeIfNecessary:NO];
				if (!!tagCellView) {
					[tagCellView configureForEntity:tag inOutlineView:self.ovTags];
				}
			}
		}

	}

	if ([action is:@"filter"]) {
		showOnlyRelatedManga = [action.initiator state] == NSOnState;

		[self fetchRelated];
	}

	if ([action is:@"info"]) {
		[AZErgoMangaInfoTab navigateToWithData:action.initiatorRelatedEntity];
	}
	if ([action is:@"read"]) {
		[AZErgoBrowserTab navigateToWithData:action.initiatorRelatedEntity];
	}
}

- (NSArray *) jenresList:(NSArray *)jenres {
	NSArray *list = [[[jenres mapWithKeyFromValueMapper:^id(AZErgoMangaTag *tag) {
		return tag.tag;
	}] allKeys] sortedArray];

	return list;
}

- (IBAction)actionExport:(id)sender {

	NSString *mangaItemTemplate = [AZErgoTextTemplateProcessor template:@"jenre-manga-item"];
	AZErgoTextTemplateProcessor *mitemProcessor = [AZErgoTextTemplateProcessor new];
	AZErgoSubstitutioner *itemSubstitutioner = [AZErgoSubstitutioner substitutionerWithDataSupplier:nil];

	const NSUInteger descLimit = 300;
	NSMutableArray *items = [NSMutableArray new];
	for (AZErgoManga *manga in [relatedManga.data sortedArray]) {
		AZErgoUpdateWatch *watch = [AZErgoUpdateWatch watchByManga:manga.name];
		NSString *annotation = manga.annotation ?: @"";
		NSUInteger length = [annotation length];
		if (!!length && (length > descLimit + 3))
			annotation = [[annotation substringToIndex:MIN(descLimit, [annotation length] - 1)] stringByAppendingString:@"..."];

		NSArray *jenres = [self jenresList:[manga.tags allObjects]];

		NSString *previewURL = watch.source ? [NSString stringWithFormat:@"http://%@", watch.source.serverURL] : nil;
		previewURL = previewURL ? [[NSURL URLWithString:manga.preview
																		 relativeToURL:[NSURL URLWithString:previewURL]] absoluteString] : @"";

		itemSubstitutioner.dataSupplier =
		[AZErgoDictionaryDataSupplier dataSupplier:@{@"title": [manga description],
																								 @"link": watch.mangaURL ?: @"",
																								 @"jenres": [jenres componentsJoinedByString:@", "] ?: @"",
																								 @"description": annotation,
																								 @"preview": previewURL,
																								 }];
		NSString *item = [mitemProcessor processString:mangaItemTemplate withDataSubstitutioner:itemSubstitutioner];
		[items addObject:item];
	}

	NSString *jenresPlainList = [[self jenresList:pickedTags] componentsJoinedByString:@", "] ?: @"all";
	AZErgoSubstitutioner *substitutioner =
	[AZErgoDictionaryDataSupplier dataSubstitutioner:@{@"title": [@"ErgoProxy Reader - Manga list - " stringByAppendingString:jenresPlainList],
																										 @"jenres": jenresPlainList,
																										 @"list": [items componentsJoinedByString:@"\n"] ?: @""
																										 }];

	NSString *result = [AZErgoTextTemplateProcessor processTemplate:@"jenre-export" withDataSubstitutioner:substitutioner];

	NSURL *url = [NSURL URLWithString:@"jenre-manga.html" relativeToURL:[AZUtils applicationDocumentsDirectory]];
	if (![result writeToURL:url
							 atomically:NO
								 encoding:NSUTF8StringEncoding
										error:nil])
		AZErrorTip(LOC_FORMAT(@"Failed to save report to [%@]", url));
}

@end
