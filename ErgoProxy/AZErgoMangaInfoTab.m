//
//  AZErgoMangaInfoTab.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaInfoTab.h"
#import "AZErgoMangaCommons.h"
#import "AZAlertSheet.h"

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
		self.tvMangaTitles.string = [[@[[manga mainTitle]] arrayByAddingObjectsFromArray:[manga additionalTitles]] componentsJoinedByString:@"\n"] ?: @"";

		self.tvMangaAnnotation.string = manga.annotation ?: @"";

		BOOL isReaded = NO;
		BOOL isComplete = NO;
		NSMutableArray *tags = [NSMutableArray new];
		for (AZErgoMangaTag *tag in [[manga.tags allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)])
			switch ([tag.guid unsignedIntegerValue]) {
				case AZErgoTagGroupComplete:
					isComplete = YES;
					break;
				case AZErgoTagGroupReaded:
					isReaded = YES;
					break;

				default:
					[tags addObject:(![tags count]) ? [tag.tag capitalizedString] : [tag.tag lowercaseString]];
					break;
			}

		self.tfMangaTags.stringValue = (!![tags count]) ? [[tags componentsJoinedByString:@", "] stringByAppendingString:@"."] : @"";
		self.tfMangaFolder.stringValue = manga.name;

		self.cbComplete.state = isComplete ? NSOnState : NSOffState;
		self.cbReaded.state = isReaded ? NSOnState : NSOffState;
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

	NSArray *has = [[manga titleEntities:YES] arrayByAddingObjectsFromArray:[manga titleEntities:NO]];
	NSSet *hasTitles = [NSSet setWithArray:has];

	NSMutableSet *delete = [hasTitles mutableCopy];
	[delete minusSet:cleaned];

	NSMutableSet *add = [cleaned mutableCopy];
	[add minusSet:hasTitles];

	for (NSString *titleToDelete in delete)
		for (AZErgoMangaTitle *title in manga.titles)
			if ([title.title isCaseInsensitiveLike:titleToDelete])
				[title delete];

	for (NSString *titleToAdd in add) {
		AZErgoMangaTitle *titleEntity = [AZErgoMangaTitle insertNew];
		titleEntity.title = titleToAdd;
		titleEntity.manga = manga;
	}
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
			manga.annotation = textView.string;
		}];

	return YES;
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
	[self.tabs navigateTo:AZEPUIDTagBrowserTab withNavData:nil];
}

- (IBAction)actionIsCompleteChanged:(id)sender {
	BOOL isCompleted = self.cbComplete.state == NSOnState;

	[manga toggle:isCompleted tag:AZErgoTagGroupComplete];
	if (!isCompleted) {
		[manga toggle:NO tag:AZErgoTagGroupReaded];
		self.cbReaded.state = NSOffState;
	}
}

- (IBAction)actionIsReadedChanged:(id)sender {
	BOOL isReaded = self.cbReaded.state == NSOnState;

	[manga toggle:isReaded tag:AZErgoTagGroupReaded];
	if (isReaded) {
		[manga toggle:YES tag:AZErgoTagGroupComplete];
		self.cbComplete.state = NSOnState;
	}
}

@end
