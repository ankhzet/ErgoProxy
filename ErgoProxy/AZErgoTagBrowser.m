//
//  AZErgoTagBrowser.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoTagBrowser.h"
#import "AZErgoTagsDataSource.h"

@interface AZErgoTagBrowser () <AZErgoTagsDataSourceDelegate> {
	AZErgoTagsDataSource *tags;
}

@property (weak) IBOutlet NSOutlineView *ovTags;

@property (weak) IBOutlet NSTextField *tfTagName;
@property (unsafe_unretained) IBOutlet NSTextView *tvTagAnnotation;
@property (weak) IBOutlet NSTextField *tfTagGuid;
@property (weak) IBOutlet NSButton *cbSkipTaggedManga;

@property (weak) IBOutlet NSButton *bTagAdd;

@property (weak) IBOutlet NSOutlineView *ovRelatedManga;

@end

@implementation AZErgoTagBrowser

- (NSString *) tabIdentifier {
	return AZEPUIDTagBrowserTab;
}

- (void) show {
	if (!tags) {
		tags = (id)self.ovTags.dataSource;
		tags.groupped = NO;
		tags.delegate = self;
	}

	[super show];
}

- (void) updateContents {
	[self delayedFetch:YES];
}

- (void) delayedFetch:(BOOL)full {
	[self delayed:@"tags-fetch" withBlock:^{
		[self fetchTags:full];
	}];
}

- (void) fetchTags:(BOOL)full {
	NSArray *fetch = [AZErgoMangaTag all];
	tags.data = fetch;

	[self.ovTags performWithSavedScroll:^{
		[self.ovTags reloadData];
		[self.ovTags expandItem:nil expandChildren:YES];
	}];
}

- (IBAction)actionTagAdd:(id)sender {
	NSString *tagName = self.tfTagName.stringValue;

	if (!tagName)
		return;

	NSString *annotation = [self.tvTagAnnotation.string copy] ?: @"";

	NSString *tagGuidText = self.tfTagGuid.stringValue ?: @"";
	NSNumber *tagGuid = (!![tagGuidText length]) ? @([tagGuidText integerValue]) : nil;

	AZErgoMangaTag *tag = [AZErgoMangaTag unique:[NSPredicate predicateWithFormat:@"tag ==[c] %@", tagName]
																			initWith:^(AZErgoMangaTag *entity) {
		entity.tag = tagName;
	}];

	tag.annotation = annotation;
	tag.guid = tagGuid;
	tag.skip = self.cbSkipTaggedManga.state == NSOnState;

	self.tfTagName.stringValue = @"";
	self.tvTagAnnotation.string = @"";
	self.cbSkipTaggedManga.state = NSOffState;
	[self pickTag:tag fetch:YES];
}

- (void) pickTag:(AZErgoMangaTag *)tag fetch:(BOOL)doFetch {
	self.tfTagName.stringValue = tag.tag ?: @"<unset>";
	self.tvTagAnnotation.string = tag.annotation ?: @"";
	self.tfTagGuid.stringValue = [tag.guid stringValue] ?: @"";
	self.cbSkipTaggedManga.state = tag.skip ? NSOnState : NSOffState;

	if (doFetch)
		[self delayedFetch:YES];
}

- (void) tagSelected:(AZErgoMangaTag *)tag {
	if (![tag isKindOfClass:[AZErgoMangaTag class]])
		return;

	[self pickTag:tag fetch:NO];
}

- (void) tagDeleted:(AZErgoMangaTag *)tag {
	if (![tag isKindOfClass:[AZErgoMangaTag class]])
		return;

	[tag delete];
	[self delayedFetch:YES];
}

@end
