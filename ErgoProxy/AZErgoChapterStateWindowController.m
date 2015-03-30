//
//  AZChapterStateWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 06.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChapterStateWindowController.h"
#import "AZErgoChapterStateDataSource.h"

#import "AZErgoMangaCommons.h"
#import "AZErgoUpdatesCommons.h"

@interface AZErgoChapterStateWindowController () {
	AZErgoChapterStateDataSource *_dataSource;
	NSArray *mangas;
}
@property (weak) IBOutlet NSOutlineView *ovChaptersState;
@property (weak) IBOutlet NSPopUpButton *bSelectedManga;
@property (weak) IBOutlet NSMenu *mMangaList;

@end

@implementation AZErgoChapterStateWindowController

- (void) showStateController {
	[self showWithSetup:^AZDialogReturnCode(AZErgoChapterStateWindowController *c) {
		return [self beginSheet];
	} andFiltering:^AZDialogReturnCode(AZDialogReturnCode code, AZErgoChapterStateWindowController *controller) {
		if (code == AZDialogReturnCancel)
			return code;



		return code;
	}];
}

- (void) prepareWindow {
	[super prepareWindow];

	NSString *title = [[self.bSelectedManga selectedItem] title];

	[self.mMangaList removeAllItems];

	NSArray *watches = [AZErgoUpdateWatch all:@"updates.@count > 0"];
	AZ_Mutable(Array, *mangaCandidates);
	for (AZErgoUpdateWatch *watch in watches)
    [mangaCandidates addObject:[AZErgoManga mangaWithName:watch.manga]];

	NSDictionary *map = [mangaCandidates mapWithMapper:^id(AZErgoManga *manga) {
		return manga.mainTitle ?: [NSString stringWithFormat:@"<title format failed for %@>", manga.objectID];
	}];

	NSArray *titles = (id)[[map allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

	mangas = [titles sortValuesOf:map];

	[self.bSelectedManga addItemsWithTitles:titles];

	if ([self.mMangaList numberOfItems] > 0)
		[self.bSelectedManga selectItemAtIndex:MAX(0, [self.mMangaList indexOfItemWithTitle:title])];

	[self fetchChapters];
}

- (AZErgoManga *) selectedManga {
	NSInteger index = MAX(MIN(self.bSelectedManga.indexOfSelectedItem, [mangas count] - 1), 0);
	AZErgoManga *item = mangas[index];

	return item;
}

- (AZErgoUpdateWatch *) associatedWatch {
	AZErgoManga *manga = [self selectedManga];
	if (!manga)
		return nil;

	return [AZErgoUpdateWatch any:@"manga ==[c] %@", manga.name];
}

- (AZErgoChapterStateDataSource *) dataSource {
	if (!_dataSource) {
		_dataSource = [AZErgoChapterStateDataSource new];
		_dataSource.groupped = YES;
		_dataSource.filter = NO;
		self.ovChaptersState.delegate = _dataSource;
		self.ovChaptersState.dataSource = _dataSource;
	}

	return _dataSource;
}

- (IBAction)actionSelectedMangaChanged:(id)sender {
	NSInteger index = MAX(MIN(self.bSelectedManga.indexOfSelectedItem, [mangas count] - 1), 0);
	[self.bSelectedManga setTitle:[self.bSelectedManga itemTitleAtIndex:index]];


	for (NSMenuItem *item in [self.mMangaList itemArray])
		[item setState:NSOffState];

	[[self.mMangaList itemAtIndex:index] setState:NSOnState];
	[self fetchChapters];
}

- (void) fetchChapters {
	AZ_Mutable(Array, *delete);
	NSMutableArray *fetch = [[[[self associatedWatch] updates] allObjects] mutableCopy];

	for (AZErgoUpdateChapter *chapter in fetch)
		if (chapter.idx < 0)
			[delete addObject:chapter];

	if (!![delete count])
		[fetch removeObjectsInArray:delete];

//	[self.ovChaptersState performWithSavedScroll:^{
		self.dataSource.data = fetch;

		[self.ovChaptersState reloadData];

		[self.ovChaptersState expandItem:nil expandChildren:YES];
//	}];
}

@end
