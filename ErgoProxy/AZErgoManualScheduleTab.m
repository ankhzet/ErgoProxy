//
//  AZErgoManualScheduleTab.m
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoManualScheduleTab.h"
#import "AZErgoTabsComons.h"

#import "AZUtils.h"

#import "AZProxifier.h"
#import "AZDownload.h"
#import "AZDownloader.h"
#import "AZDownloadParams.h"

#import "AZErgoDownloadPrefsWindowController.h"

@interface AZErgoManualScheduleTab ()

@property (weak) IBOutlet NSComboBox *cbManga;
@property (weak) IBOutlet NSTextField *tfChapter;
@property (unsafe_unretained) IBOutlet NSTextView *tvScansList;
@property (weak) IBOutlet NSButton *cbUseDefaults;

@end

@implementation AZErgoManualScheduleTab

- (NSString *) tabIdentifier {
	return AZEPUIDManualScheduleTab;
}

- (NSArray *) scansList {
	NSString *scansList = [[self.tvScansList string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray *scans = [scansList componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[scans count]];

	for (__strong NSString *scan in scans)
		if ([(scan = [scan stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) length])
			[result addObject:scan];

	return result;
}

- (IBAction)actionSchedule:(id)sender {
	NSArray *scans = [self scansList];
	if (![scans count]) return;

	AZDownloadParams *params = [AZDownloadParams defaultParams];
//	AZDownloadParams *params = [[AZErgoDownloadPrefsWindowController sharedController] aquireParams:self.cbUseDefaults.state==NSOnState];

	if (!params)
		return;

	NSString *chapString = self.tfChapter.stringValue;
	if ([chapString rangeOfString:@"."].location != NSNotFound) {
		NSLog(@"%@ (%@) is not a valid float!", chapString, @([chapString floatValue]));
	}

	NSString *manga = self.cbManga.stringValue;
	float chapter = [[chapString stringByReplacingOccurrencesOfString:@"." withString:@","] floatValue];
	NSUInteger pageIDX = 1;

	AZProxifier *proxifier = [AZProxifier sharedProxy];

	for (NSString *scan in scans) {
		NSURL *url = [NSURL URLWithString:scan];
		AZDownload *download = [proxifier downloadForURL:url withParams:params];
		download.manga = manga;
		download.chapter = chapter;
		download.page = pageIDX++;
	}

	self.tvScansList.string = @"";
	self.tfChapter.floatValue = truncf(chapter) + 1.f;
}

- (IBAction)actionChapterStep:(id)sender {
	float v = ((NSStepper *) sender).floatValue;
	v = truncf(v);
	self.tfChapter.floatValue = v;
}

- (IBAction)actionMangaPicked:(id)sender {
	NSArray *fetched = [AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)];

	[self.cbManga removeAllItems];
	[self.cbManga addItemsWithObjectValues:fetched];
	[self.cbManga setCompletes:YES];
}

- (IBAction)actionRefreshMangaList:(id)sender {
	NSArray *scans = [self optimizeScansListForCompare:[self scansList]];
	if (![scans count]) return;

	NSArray *fetched = [AZUtils fetchDirs:PREF_STR(PREFS_COMMON_MANGA_STORAGE)];
	if (![fetched count]) return;

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

	[self.cbManga removeAllItems];
	[self.cbManga addItemsWithObjectValues:sorted];
	if ([sorted count])
		[self.cbManga selectItemAtIndex:0];
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

- (IBAction)actionRefreshChapterField:(id)sender {
}

@end
