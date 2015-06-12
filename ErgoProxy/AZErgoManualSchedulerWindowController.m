//
//  AZErgoManualSchedulerWindowController.m
//  ErgoProxy
//
//  Created by Ankh on 29.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoManualSchedulerWindowController.h"
#import "AZErgoDownloadPrefsWindowController.h"

#import "AZProxifier.h"
#import "AZDownload.h"
#import "AZErgoMangaCommons.h"
#import "AZErgoUpdatesCommons.h"

#import "AZErgoChapterDownloadParams.h"

@interface AZErgoManualSchedulerWindowController ()

@property (weak) IBOutlet NSComboBox *cbMangaFolder;
@property (weak) IBOutlet NSTextField *tfChapter;
@property (unsafe_unretained) IBOutlet NSTextView *tvScansList;
@property (weak) IBOutlet NSButton *bUseDefaultPrefs;

@end

@implementation AZErgoManualSchedulerWindowController

#pragma mark - Basic functionality

- (void) prepareWindow {
	[super prepareWindow];
	[self actionRefreshList:nil];
}

- (BOOL) applyChanges {
	NSString *mangaName = self.mangaDirectory;
	AZErgoManga *manga = [AZErgoManga mangaWithName:mangaName];

	AZDownloadParams *params = [[AZErgoDownloadPrefsWindowController sharedController] aquireParams:[self isUsingDefaults] forManga:manga];

	if (!params)
		return NO;
	
	NSArray *scans = self.scansList;
	if (![scans count]) return NO;

	AZErgoChapterDownloadParams *downloads = [AZErgoChapterDownloadParams new];
	downloads.manga = manga;
	downloads.chapterID = self.mangaChapter;
	downloads.scans = scans;
	downloads.scanDownloadParams = params;

	[downloads registerDownloads:[AZProxifier sharedProxifier]];

	self.scansList = nil;
	self.mangaChapter = ((int)self.mangaChapter) + 1.f;

	return YES;
}

#pragma mark - UI related stuff

- (BOOL) isUsingDefaults {
	return self.bUseDefaultPrefs.state == NSOnState;
}

- (NSString *) mangaDirectory {
	return self.cbMangaFolder.stringValue;
}

- (void) setMangaDirectory:(NSString *)mangaDirectory {
	self.cbMangaFolder.stringValue = mangaDirectory ?: @"";
}

- (float) mangaChapter {
	NSString *chapString = self.tfChapter.stringValue;
	if ([chapString rangeOfString:@"."].location != NSNotFound) {
		DDLogVerbose(@"%@ (%@) is not a valid float!", chapString, @([chapString floatValue]));
	}

	return [[chapString stringByReplacingOccurrencesOfString:@"." withString:@","] floatValue];
}

- (void) setMangaChapter:(float)mangaChapter {
	self.tfChapter.floatValue = mangaChapter;
}

- (NSArray *) scansList {
	NSString *scansList = [[self.tvScansList string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray *scans = [scansList componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[scans count]];

	for (__strong NSString *scan in scans) {
		NSRange r = [scan rangeOfString:@"#"];
		if (!!r.length)
			scan = [scan substringToIndex:r.location];

		if ([(scan = [scan stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) length])
			[result addObject:scan];
	}

	return result;
}

- (void) setScansList:(NSArray *)scansList {
	NSString *text = [scansList componentsJoinedByString:@"\n"] ?: @"";
	self.tvScansList.string = text;
}

- (NSArray *) optimizeScansListForCompare:(NSArray *)scans {
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[scans count]];
	for (NSString *scan in scans) {
    NSString *clean = [[scan stringByReplacingOccurrencesOfString:@"http://" withString:@""] stringByDeletingPathExtension];
		NSMutableArray *components = [[clean pathComponents] mutableCopy];
		[components removeObjectAtIndex:0];
		clean = [[components componentsJoinedByString:@" "] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
		clean = [clean stringByReplacingOccurrencesOfString:@"-" withString:@" "];
		clean = [clean stringByReplacingOccurrencesOfString:@"  " withString:@" "];
		[result addObject:clean];
	}
	return result;
}

- (IBAction)actionRefreshList:(id)sender {
	NSArray *fetched = [AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)];

	if (![fetched count]) return;

	[self.cbMangaFolder removeAllItems];
	[self.cbMangaFolder addItemsWithObjectValues:fetched];

	NSArray *scans = [self optimizeScansListForCompare:self.scansList];
	if ([scans count]) {
		CGFloat fuzzy = 0.01f;
		NSMutableDictionary *compared = [NSMutableDictionary dictionaryWithCapacity:[fetched count]];
		for (NSString *dir in fetched) {
			CGFloat score = 0.f;

			for (NSString *scan in scans)
				score += [scan scoreAgainst:dir fuzziness:@(fuzzy) options:NSStringScoreOptionReducedLongStringPenalty];

			score /= [scans count];

			compared[dir] = @(score);
		}

		NSArray *sorted = [[compared allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *dir1, NSString *dir2) {
			return [((NSNumber *)compared[dir2]) compare:((NSNumber *)compared[dir1])];
		}];

		sorted = [sorted objectsAtIndexes:[sorted indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			return [compared[obj] floatValue] >= fuzzy;
		}]];

		if ([sorted count])
			self.mangaDirectory = sorted[0];
	}

	[self.cbMangaFolder setCompletes:YES];
}

- (IBAction)actionPickLastChapter:(id)sender {
	NSString *mangaName = self.mangaDirectory;
	if (![mangaName length])
		return;
	
	NSArray *chapters = [AZUtils fetchDirs:[PREF_STR(PREFS_COMMON_MANGA_STORAGE) stringByAppendingPathComponent:mangaName]];

	NSCharacterSet *nonNumeric = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
	NSArray *sorted = [chapters sortedArrayUsingComparator:^NSComparisonResult(NSString *chName1, NSString *chName2) {
		if ([chName1 rangeOfCharacterFromSet:nonNumeric].location != NSNotFound)
			return NSOrderedAscending;

		return SIGN([chName2 floatValue] - [chName1 floatValue]);
	}];

	self.mangaChapter = MAX(1, (sorted && [sorted count]) ? [sorted[0] floatValue] : 1);
}

- (IBAction)actionStepChapter:(id)sender {
	float v = ((NSStepper *) sender).floatValue;
	v = truncf(v);
	self.tfChapter.floatValue = v;
}

- (IBAction)actionFindSimilar:(id)sender {
	NSArray *scans = self.scansList;
	AZ_MutableI(Array, *result, arrayWithCapacity:[scans count]);

	for (NSString *scan in scans) {
    NSArray *downloads = [AZDownload all:@"sourceURL == %@", scan];
		AZ_Mutable(Dictionary, *mangas);
		for (AZDownload *download in downloads) {
			NSString *chapterTitle = nil;
			AZErgoUpdateWatch *watch = download.forManga ? [AZErgoUpdateWatch watchByManga:download.forManga.name] : nil;
			AZErgoUpdateChapter *chapter = [watch chapterByIDX:download.chapter];
			if (chapter) {
				chapterTitle = [chapter fullTitle];
			} else
				chapterTitle = [NSString stringWithFormat:@"ch. %.1f", download.chapter];

			NSMutableArray *chaps = GET_OR_INIT(mangas[download.forManga.name], [NSMutableArray new]);
			[chaps addObject:[NSString stringWithFormat:@"%@ (p. %lu)", chapterTitle, download.page]];
		}

		AZ_MutableI(Array, *chapters, arrayWithCapacity:[downloads count]);
		for (NSString *mangaName in [mangas allKeys]) {
			[chapters addObject:[NSString stringWithFormat:@"%@ :: %@", [AZErgoManga mangaByName:mangaName], [mangas[mangaName] componentsJoinedByString:@", "]]];
		}

		NSString *summary = [NSString stringWithFormat:@"%@ # \t\t %@", scan, (![chapters count]) ? @"not found" : [chapters componentsJoinedByString:@", "]];

		[result addObject:summary];
	}

	self.scansList = result;
}

@end
