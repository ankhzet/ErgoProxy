//
//  AZErgoUtilsTab.m
//  ErgoProxy
//
//  Created by Ankh on 13.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoUtilsTab.h"

#import "AZErgoMangaCommons.h"
#import "AZDownload.h"
#import "AZDownloadSpeedWatcher.h"

@interface AZErgoUtilsTab ()
@property (weak) IBOutlet NSTextField *tfDownloadedAmount;

@end

@implementation AZErgoUtilsTab

- (NSString *) tabIdentifier {
	return AZEPUIDUtilsTab;
}

- (void) updateContents {
	NSUInteger amount = PREF_INT(PREFS_COMMON_MANGA_DOWNLOADED) + [[AZDownloadSpeedWatcher sharedSpeedWatcher] totalDownloaded];
	self.tfDownloadedAmount.stringValue = [NSString cvtFileSize:amount withPrec:2];
}

- (IBAction)actionCheckUnlinkedFolders:(id)sender {
	NSArray *folders = MANGA_STORAGE_FOLDERS;

	AZ_Mutable(Array, *unlinkedNonDld);
	AZ_Mutable(Array, *unlinkedHasDld);
	for (NSString *folder in folders) {
    AZErgoManga *linked = [AZErgoManga mangaByName:folder];

		if (!linked) {
			if (![AZDownload countOf:[NSPredicate predicateWithFormat:@"manga ==[c] %@", folder]])
				[unlinkedNonDld addObject:folder];
			else
				[unlinkedHasDld addObject:folder];
		}
	}

	if (!([unlinkedNonDld count] + [unlinkedHasDld count])) {
		[AZAlert showAlert:AZInfoTitle message:@"No unlinked folders."];
		return;
	}


	NSString *withDownloads = (![unlinkedHasDld count]) ? @"" : [NSString stringWithFormat:@"Has downloads:\n<%@>", [unlinkedHasDld componentsJoinedByString:@">, <"]];
	NSString *withoutDownloads = (![unlinkedNonDld count]) ? @"" : [NSString stringWithFormat:@"%@Others:\n<%@>", [unlinkedHasDld count] ? @"\n" : @"", [unlinkedNonDld componentsJoinedByString:@">, <"]];

	NSString *all = [NSString stringWithFormat:@"%@%@", withDownloads, withoutDownloads];

	switch ([AZAlert showOkCancel:@"" message:[NSString stringWithFormat:@"There are unlinked folders:\n%@\n\nLink them?", all]]) {
		case AZDialogReturnOk:
			for (NSString *folder in [unlinkedHasDld arrayByAddingObjectsFromArray:unlinkedNonDld]) {
				[AZErgoManga mangaWithName:folder];
			}
			break;

		default:
			break;
	}
}

- (IBAction)actionRecalcDownloaded:(id)sender {
	NSArray * downloads = [AZDownload filter:[NSPredicate predicateWithFormat:@"downloaded > 0"] limit:0];
	NSUInteger downloaded = 0;
	for (AZDownload *download in downloads)
		downloaded += download.downloaded;

	downloaded -= [[AZDownloadSpeedWatcher sharedSpeedWatcher] totalDownloaded];
	PREF_SAVE_INT(downloaded, PREFS_COMMON_MANGA_DOWNLOADED);

	[self updateContents];
}

@end
