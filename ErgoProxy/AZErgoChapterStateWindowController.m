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
#import "AZErgoCountingConflictsSolver.h"

@interface AZErgoChapterStateWindowController () {
	AZErgoChapterStateDataSource *_dataSource;
	NSArray *mangas;

	AZErgoManga *pickedManga;
}
@property (weak) IBOutlet NSOutlineView *ovChaptersState;
@property (weak) IBOutlet NSPopUpButton *bSelectedManga;
@property (weak) IBOutlet NSMenu *mMangaList;

@property (nonatomic) AZErgoManga *selectedManga;

@end

@implementation AZErgoChapterStateWindowController

- (void) showStateController:(AZErgoManga *)manga {
	pickedManga = manga;

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

	NSArray *watches = [AZErgoUpdateWatch fetch:[AZF_ALL prefetchEntities]];//:@"updates.@count > 0"];
	AZ_Mutable(Dictionary, *mangaCandidates);
	for (AZErgoUpdateWatch *watch in watches) {
		NSString *name = watch.manga;
		AZErgoManga *manga = [AZErgoManga mangaWithName:name];
		if (!manga) {
			manga = [AZErgoManga mangaWithName:name];
			DDLogInfo(@"Created manga instance for watch: %@", name);
		}
		mangaCandidates[manga.mainTitle ?: name] = manga;
	}

	NSDictionary *map = [[mangaCandidates allValues] mapWithKeyFromValueMapper:^id(AZErgoManga *manga) {
		return [self titleOf:manga];
	}];

	NSArray *titles = [[[map allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] unshiftObject:@""];

	mangas = [titles sortValuesOf:map];


	if (!pickedManga) {
		NSString *title = [[self.bSelectedManga selectedItem] title];
		pickedManga = title ? mangaCandidates[title] : nil;
	}

	[self.mMangaList removeAllItems];
	[self.bSelectedManga addItemsWithTitles:titles];

	self.selectedManga = pickedManga;
}

- (NSString *) titleOf:(AZErgoManga *)manga {
	return manga.mainTitle ?: [NSString stringWithFormat:@"<title format failed for %@>", manga.objectID];
}

- (NSInteger) selectedIndex {
	return CLAMP(self.bSelectedManga.indexOfSelectedItem, -1, (NSInteger)[mangas count] - 1);
}

- (void) setSelectedIndex:(NSInteger)index {
	index = CLAMP(index, 0, (NSInteger)[mangas count] - 1);

	[self.bSelectedManga selectItemAtIndex:index];
	[self.bSelectedManga setTitle:[self.bSelectedManga itemTitleAtIndex:index]];

	for (NSMenuItem *item in [self.mMangaList itemArray])
		[item setState:NSOffState];

	[[self.mMangaList itemAtIndex:index] setState:NSOnState];

	[self fetchChapters];
}

- (AZErgoManga *) selectedManga {
	NSInteger index = self.selectedIndex;
	if (index < 0)
		return nil;

	AZErgoManga *item = mangas[index];

	return ((id)item != [NSNull null]) ? item : nil;
}

- (void) setSelectedManga:(AZErgoManga *)manga {
	NSUInteger index = [mangas indexOfObject:manga];

	if (index == NSNotFound)
		self.selectedIndex = -1;
	else
		self.selectedIndex = index;
}

- (AZErgoUpdateWatch *) associatedWatch {
	AZErgoManga *manga = self.selectedManga;
	if (!manga)
		return nil;

	return [AZErgoUpdateWatch watchByManga:manga.name];
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
	AZErgoManga *selected = self.selectedManga;

	self.selectedManga = selected;
}

- (NSArray *) pickChapters {
	AZ_Mutable(Array, *delete);
	NSMutableArray *fetch = [[[[self associatedWatch] updates] allObjects] mutableCopy];

	for (AZErgoUpdateChapter *chapter in fetch)
		if (chapter.idx < 0)
			[delete addObject:chapter];

	if (!![delete count]) {
		[fetch removeObjectsInArray:delete];
		DDLogInfo(@"Deleted from fetch %lu chapters", [delete count]);
	}

	return fetch;
}

- (void) fetchChapters {
	[self fetchChapters:[self pickChapters]];
}

- (void) fetchChapters:(NSArray *)chapters {
//	[self.ovChaptersState performWithSavedScroll:^{
		self.dataSource.data = chapters;

		[self.ovChaptersState reloadData];

		[self.ovChaptersState expandItem:nil expandChildren:YES];
//	}];
}

- (BOOL) applyChanges {
	NSArray *chapters = [self pickChapters];

//	AZ_Mutable(Array, *cloned);
//	for (AZErgoUpdateChapter *chapter in chapters) {
//    Chapter *clone = [Chapter chapter:chapter.baseIdx ofVolume:chapter.volume];
//		[cloned addObject:clone];
//	}
//
	AZErgoManga *manga = self.selectedManga;
	[manga remapChapters:chapters];

	[[AZErgoCountingConflictsSolver solverForChapters:chapters] solveConflicts];

	[self fetchChapters:chapters];

	return YES;
}

@end
