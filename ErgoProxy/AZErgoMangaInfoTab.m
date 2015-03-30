//
//  AZErgoMangaInfoTab.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaInfoTab.h"
#import "AZErgoMangaCommons.h"

@interface AZErgoMangaInfoTab () <NSTextViewDelegate> {
	AZErgoManga *manga;
	BOOL updating;
}
@property (unsafe_unretained) IBOutlet NSTextView *tvMangaTitles;
@property (unsafe_unretained) IBOutlet NSTextView *tvMangaAnnotation;
@property (weak) IBOutlet NSTextField *tfMangaTags;
@property (weak) IBOutlet NSTextField *tfMangaFolder;
@property (weak) IBOutlet NSButton *cbReaded;
@property (weak) IBOutlet NSButton *cbComplete;
@property (weak) IBOutlet NSButton *cbDownloaded;
@property (weak) IBOutlet NSImageView *ivMangaPreview;

@end

@implementation AZErgoMangaInfoTab

- (NSString *) tabIdentifier {
	return AZEPUIDMangaInfoTab;
}

- (void) navigateTo:(id)data {
	manga = [((NSDictionary *)data) objectForKey:@"manga"];

	[super navigateTo:data];
}

- (void) updateContents {
	updating = YES;
	@try {
		self.tvMangaTitles.string = [[@[[manga mainTitle] ?: @""] arrayByAddingObjectsFromArray:[manga additionalTitles]] componentsJoinedByString:@"\n"] ?: @"";

		self.tvMangaAnnotation.string = manga.annotation ?: @"";

		BOOL isReaded = NO;
		BOOL isComplete = NO;
		BOOL isDownloaded = NO;
		NSMutableArray *tags = [NSMutableArray new];
		for (AZErgoMangaTag *tag in [[manga.tags allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)])
			switch ([tag.guid unsignedIntegerValue]) {
				case AZErgoTagGroupComplete:
					isComplete = YES;
					break;
				case AZErgoTagGroupReaded:
					isReaded = YES;
					break;

				case AZErgoTagGroupDownloaded:
					isDownloaded = YES;
					break;

				default:
					[tags addObject:(![tags count]) ? [tag.tag capitalizedString] : [tag.tag lowercaseString]];
					break;
			}

		self.tfMangaTags.stringValue = (!![tags count]) ? [[tags componentsJoinedByString:@", "] stringByAppendingString:@"."] : @"";
		self.tfMangaFolder.stringValue = manga.name ?: @"";

		self.cbComplete.state = isComplete ? NSOnState : NSOffState;
		self.cbReaded.state = isReaded ? NSOnState : NSOffState;
		self.cbDownloaded.state = isDownloaded ? NSOnState : NSOffState;

		NSString *previewFileName = [manga previewFile];
		NSImage *preview = previewFileName ? [[NSImage alloc] initByReferencingFile:[manga previewFile]] : [NSImage imageNamed:NSImageNameApplicationIcon];


		self.ivMangaPreview.image = preview;
	}
	@finally {
    updating = NO;
	}
}

- (void) pickTitles {
	if (updating)
		return;

	NSArray *titles = [self.tvMangaTitles.string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSMutableSet *cleaned = [NSMutableSet new];

	NSCharacterSet *filter = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	for (NSString *title in titles) {
    NSString *clean = [title stringByTrimmingCharactersInSet:filter];
		if ([clean length])
			[cleaned addObject:clean];
	}

	[manga setAllTitles:[cleaned allObjects]];
}

- (IBAction)actionTagsChanged:(id)sender {
	if (updating)
		return;

	NSArray *tags = [self.tfMangaTags.stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", ."]];

	NSMutableSet *cleaned = [NSMutableSet new];

	NSCharacterSet *filter = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	for (NSString *tag in tags) {
    NSString *clean = [tag stringByTrimmingCharactersInSet:filter];
		if ([clean length])
			[cleaned addObject:[clean lowercaseString]];
	}

	NSArray *has = [manga tagNames];
	NSSet *hasTags = [NSSet setWithArray:has];

	NSMutableSet *delete = [hasTags mutableCopy];
	[delete minusSet:cleaned];
	[delete removeObject:@"readed"];
	[delete removeObject:@"complete"];
	[delete removeObject:@"downloaded"];

	NSMutableSet *add = [cleaned mutableCopy];
	[add minusSet:hasTags];


	for (NSString *tagToDelete in delete)
		for (AZErgoMangaTag *tag in [manga.tags allObjects])
			if ([tag.tag isCaseInsensitiveLike:tagToDelete])
				[manga removeTagsObject:tag];

	for (NSString *tagToAdd in add) {
		AZErgoMangaTag *tagEntity = [AZErgoMangaTag unique:[NSPredicate predicateWithFormat:@"tag ==[c] %@", tagToAdd] initWith:^(AZErgoMangaTag *tag) {
			tag.tag = [tagToAdd capitalizedString];
		}];
		[manga addTagsObject:tagEntity];
	}
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray *)affectedRanges replacementStrings:(NSArray *)replacementStrings {
	if (updating)
		return YES;

	if (textView == self.tvMangaTitles)
		[self delayed:@"titles-changed" forTime:0.5 withBlock:^{
			[self pickTitles];
		}];

	if (textView == self.tvMangaAnnotation)
		[self delayed:@"annotation-changed" forTime:0.5 withBlock:^{
			manga.annotation = [textView.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}];

	return YES;
}

- (IBAction)actionRead:(id)sender {
	[self.tabs navigateTo:AZEPUIDBrowserTab withNavData:manga.name];
}

- (IBAction)actionDelete:(id)sender {
	NSString *title = NSLocalizedString(@"You really want to delete \"%@\"?", @"Manga deletion warning");
	switch ([AZAlert showOkCancel:AZWarningTitle message:[NSString stringWithFormat:title, [manga mainTitle]]]) {
		case AZDialogReturnOk:
			[manga delete];
			[self.tabs navigateTo:AZEPUIDMangaTab withNavData:nil];
			break;

		default:
			break;
	}
}

- (IBAction)actionShowTagsEditor:(id)sender {
	[self.tabs navigateTo:AZEPUIDTagBrowserTab withNavData:manga.name];
}

- (IBAction)actionIsCompleteChanged:(id)sender {
	BOOL isCompleted = self.cbComplete.state == NSOnState;
	[self toggle:isCompleted tag:AZErgoTagGroupComplete];
}

- (IBAction)actionIsReadedChanged:(id)sender {
	BOOL isReaded = self.cbReaded.state == NSOnState;
	[self toggle:isReaded tag:AZErgoTagGroupReaded];
}

- (IBAction)actionIsDownloadedChanged:(id)sender {
	BOOL isDownloaded = self.cbDownloaded.state == NSOnState;
	[self toggle:isDownloaded tag:AZErgoTagGroupDownloaded];
}

- (void) toggle:(BOOL)on tag:(AZErgoTagGroup)guid {
	[self toggle:on tag:guid chain:nil];
}

- (void) toggle:(BOOL)on tag:(AZErgoTagGroup)guid chain:(NSSet *)chain {
	if ([chain containsObject:@(guid)])
		return;

	[manga toggle:on tagWithGUID:guid];
	[(NSMutableSet *)(chain = chain ?: [NSMutableSet new]) addObject:@(guid)];

	NSButton *b = nil;
	switch (guid) {
		case AZErgoTagGroupComplete:
			b = self.cbComplete;
			if (!on) {
				[self toggle:NO tag:AZErgoTagGroupDownloaded chain:chain];
			}
			break;
		case AZErgoTagGroupDownloaded:
			b = self.cbDownloaded;
			if (!on) {
				[self toggle:NO tag:AZErgoTagGroupReaded chain:chain];
			} else {
				[self toggle:YES tag:AZErgoTagGroupComplete chain:chain];
			}
			break;
		case AZErgoTagGroupReaded:
			b = self.cbReaded;
			if (on) {
				[self toggle:YES tag:AZErgoTagGroupDownloaded chain:chain];
			}
			break;

		default:
			break;
	}
	if (b)
		b.state = on ? NSOnState : NSOffState;
}

@end
