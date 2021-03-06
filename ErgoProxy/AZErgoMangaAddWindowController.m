//
//  AZErgoMangaAddWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaAddWindowController.h"
#import "AZErgoMangaCommons.h"


@interface AZErgoMangaAddWindowController ()
@property (unsafe_unretained) IBOutlet NSTextView *tvMangaTitles;
@property (weak) IBOutlet NSComboBox *cbMangaDirectory;

@end

@implementation AZErgoMangaAddWindowController

- (void) prepareWindow {
	[super prepareWindow];
	[self actionRefreshDirectories:nil];
}

- (IBAction)actionRefreshDirectories:(id)sender {
	NSArray *dirs = [AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)];

	[self.cbMangaDirectory removeAllItems];
	[self.cbMangaDirectory addItemsWithObjectValues:dirs];
	[self.cbMangaDirectory setCompletes:YES];
}

- (BOOL) applyChanges {
	NSString *dir = self.cbMangaDirectory.stringValue;

	if (![dir length])
		return NO;

	NSArray *titles = [self.tvMangaTitles.string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSMutableSet *cleanedTitles = [NSMutableSet new];
	for (NSString *title in titles) {
    NSString *clean = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if ([clean length])
			[cleanedTitles addObject:clean];
	}

	if (![cleanedTitles count])
		return NO;

	AZErgoManga *manga = [AZErgoManga mangaByName:dir];
	if (manga) {
		AZErrorTip(LOC_FORMAT(@"Manga with source directory \"%@\" already registered in DB", dir));
		return NO;
	}

	manga = [AZErgoManga any:@"any titles.title in %@", cleanedTitles];

	if (manga) {
		AZErrorTip(LOC_FORMAT(@"Manga with such titles (%@) already registered in DB", [[cleanedTitles allObjects] componentsJoinedByString:@"; "]));
		return NO;
	}

	manga = [AZErgoManga insertNew];
	manga.name = dir;
	for (NSString *title in cleanedTitles) {
    AZErgoMangaTitle *titleEntity = [AZErgoMangaTitle insertNew];
		titleEntity.title = title;
		titleEntity.manga = manga;
	}

	self.tvMangaTitles.string = @"";
	self.cbMangaDirectory.stringValue = @"";

	return YES;
}

@end
