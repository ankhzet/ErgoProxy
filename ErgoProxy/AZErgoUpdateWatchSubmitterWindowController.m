//
//  AZErgoUpdateWatchSubmitterWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 28.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdateWatchSubmitterWindowController.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"

#import "AZErgoMangachanSource.h"

#import "AZErgoUpdatesAPI.h"

@interface AZErgoUpdateWatchSubmitterWindowController () {
	AZErgoUpdateWatch *mangaEntity;

	NSDictionary *searchResults;
	NSDictionary *searchTitles;
}

@property (weak) IBOutlet NSComboBox *cbServerList;
@property (weak) IBOutlet NSButton *bSearchManga;
@property (weak) IBOutlet NSComboBox *cbDirectoriesList;
@property (weak) IBOutlet NSTextField *tfIdentifier;

@end

@implementation AZErgoUpdateWatchSubmitterWindowController

- (NSString *) directory {
	NSString *dir = self.cbDirectoriesList.stringValue;
	if ([dir isLike:@"*{*}"])
		dir = [dir match:@"^.*?\\{(.*?)\\}$" atRangeIndex:1];

	return dir;
}

- (NSString *) identifier {
	return self.tfIdentifier.stringValue;
}

- (void) setDirectory:(NSString *)directory {
	self.cbDirectoriesList.stringValue = directory ?: @"";
}

- (void) setIdentifier:(NSString *)identifier {
	self.tfIdentifier.stringValue = identifier ?: @"";
}

- (id)initWithWindow:(NSWindow *)window {
	if (!(self = [super initWithWindow:window]))
		return self;

	return self;
}

- (void) prepareWindow {
	[super prepareWindow];
	[self actionRefreshList:nil];

	NSDictionary *sources;
	@synchronized(sources = [AZErgoUpdatesSource sharedSources]) {
		[self.cbServerList removeAllItems];
		for (AZErgoUpdatesSource *source in [sources allValues]) {
			[self.cbServerList addItemWithObjectValue:[[source class] serverURL]];
			[self.cbServerList selectItemAtIndex:0];
		}
	}
}

- (void) showWatchSubmitter:(AZErgoUpdateWatch *)watch {
	[self showWithSetup:^AZDialogReturnCode(AZSheetWindowController *c) {
		AZErgoUpdateWatchSubmitterWindowController *controller = (id)c;
		if (!!watch) {
			controller.identifier = watch.genData;
			controller.directory = watch.manga;
		}

		return [self beginSheet];
	} andFiltering:^AZDialogReturnCode(AZDialogReturnCode code, AZErgoUpdateWatchSubmitterWindowController *controller) {
		if (code == AZDialogReturnCancel)
			return code;

		mangaEntity = watch;
		AZErgoUpdatesSource *source = [self source];

		if ([source correspondsTo:controller.identifier]) {
			NSString *parsed = [source parseURL:controller.identifier];
			if (!!parsed) {
				[self pickRelatedDirectory:controller.identifier = parsed];
			}
		}

		return code;
	}];
}

- (AZErgoUpdatesSource *) source {
	return [[AZErgoUpdatesSource sharedSources] objectForKey:self.cbServerList.stringValue];
}

- (BOOL) applyChanges {
	NSString *mangaDir = self.directory;

	if ([mangaDir length]) {
		BOOL update = NO;
		if (!mangaEntity) {

			mangaEntity = [AZErgoUpdateWatch any:@"manga ==[c] %@", mangaDir];

			if (mangaEntity) {
				NSString *msg = LOC_FORMAT(@"Manga with source directory \"%@\" already registered in DB. Update it's server URL?", mangaDir);
				if (!AZConfirm(msg))
					return NO;

				update = YES;
			} else
				mangaEntity = [AZErgoUpdateWatch any:@"genData ==[c] %@", self.identifier];

			if (!mangaEntity) {
				mangaEntity = [AZErgoUpdateWatch insertNew];
				update = YES;
			}
		}

		mangaEntity.manga = mangaDir;
		mangaEntity.genData = self.identifier;

		mangaEntity.source = [self source].descriptor;

		if (update)
			dispatch_async_at_background(^{
				[[self source] checkWatch:mangaEntity];
			});

		self.identifier = nil;
		self.directory = nil;

		return YES;
	}

	return NO;
}

- (IBAction)actionRefreshList:(id)sender {
	searchResults = nil;
	NSArray *dirs = [AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)];

	[self.cbDirectoriesList removeAllItems];
	[self.cbDirectoriesList addItemsWithObjectValues:dirs];
	[self.cbDirectoriesList setCompletes:YES];

	[self pickRelatedDirectory:self.directory];
}

- (NSArray *) pickClosest:(NSArray *)list to:(NSString *)string {
	CGFloat fuzzy = 0.01f;
	NSMutableDictionary *compared = [NSMutableDictionary dictionaryWithCapacity:[list count]];
	for (NSString *test in list) {
		CGFloat score = [string scoreAgainst:test fuzziness:@(fuzzy) options:NSStringScoreOptionReducedLongStringPenalty];

		compared[test] = @(score);
	}

	NSArray *sorted = [[compared allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2) {
		return [((NSNumber *)compared[s1]) compare:((NSNumber *)compared[s2])];
	}];

	sorted = [sorted objectsAtIndexes:[sorted indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return [compared[obj] floatValue] >= fuzzy;
	}]];
	
	return sorted;
}

- (void) pickRelatedDirectory:(NSString *)identifier {
	if (![identifier length])
		return;

	searchResults = nil;
	NSMutableArray *dirs = [[AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)] mutableCopy];

	NSArray *closest = [[[self pickClosest:dirs to:identifier] reverseObjectEnumerator] allObjects];
	if ([closest count]) {
		self.directory = closest[0];

		[self.cbDirectoriesList removeAllItems];
		[self.cbDirectoriesList addItemsWithObjectValues:closest];
		[self.cbDirectoriesList addItemWithObjectValue:@"-----"];

		[dirs removeObjectsInArray:closest];
		[self.cbDirectoriesList addItemsWithObjectValues:dirs];

		[self.cbDirectoriesList setCompletes:YES];
	}
}

- (IBAction)actionSearchManga:(id)sender {
	[self.bSearchManga setEnabled:NO];
	[AZ_API(ErgoUpdates) updates:self.source matchingEntities:self.identifier withCompletion:^(BOOL isOk, id data) {
		[self.bSearchManga setEnabled:YES];
		[self.cbDirectoriesList removeAllItems];

		searchResults = [NSMutableDictionary new];
		searchTitles = [NSMutableDictionary new];

		for (AZErgoUpdateMangaInfo *info in data) {
			NSString *proposedDir = info->genData;
			proposedDir = [proposedDir stringByAppendingString:@"-"];
			proposedDir = [proposedDir stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]];
			proposedDir = [proposedDir stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n -"]];

			NSMutableArray *titles = [info->titles mutableCopy];
			NSString *mainTitle = [AZErgoManga mainTitle:titles];
			[titles removeObject:mainTitle];

			titles = [[self pickClosest:titles to:proposedDir] mutableCopy];

			if ([titles count] > 0) {
				NSString *bestCandinateForAdditional = [titles firstObject];
				mainTitle = [NSString stringWithFormat:@"%@ (%@)", mainTitle, bestCandinateForAdditional];
				[titles removeObject:bestCandinateForAdditional];
			}

			[titles insertObject:mainTitle atIndex:0];
			[(NSMutableDictionary *)searchResults setObject:info->genData forKey:proposedDir];
			[(NSMutableDictionary *)searchTitles setObject:[titles componentsJoinedByString:@"; "]?:@"" forKey:proposedDir];

			[self.cbDirectoriesList addItemWithObjectValue:[NSString stringWithFormat:@"%@ - {%@}", mainTitle, proposedDir]];
		}

		if ([data count] > 0) {
			[self.cbDirectoriesList selectItemAtIndex:0];
			[self actionDirectoryChanged:nil];
		}
	}];
}

- (IBAction)actionDirectoryChanged:(id)sender {
	if (!searchResults)
		return;

	self.identifier = searchResults[self.directory];

	[self.tfIdentifier setToolTip:searchTitles[self.directory]];
	if ([self.cbDirectoriesList numberOfItems] < 2)
		[self pickRelatedDirectory:self.directory];
}

- (IBAction)actionConvertGenDataToFolder:(id)sender {
	NSString *genData = [self.source parseURL:self.identifier];
	genData = [self.source genDataToFolder:genData];

	self.directory = [[genData stringByReplacingOccurrencesOfString:@"-" withString:@" "] capitalizedString];
}

@end
