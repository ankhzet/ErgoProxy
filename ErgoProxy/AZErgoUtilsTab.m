//
//  AZErgoUtilsTab.m
//  ErgoProxy
//
//  Created by Ankh on 13.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoUtilsTab.h"

#import "AZErgoMangaCommons.h"
#import "AZErgoUpdatesCommons.h"
#import "AZDownload.h"
#import "AZStorage.h"
#import "AZProxifier.h"
#import "AZDownloadSpeedWatcher.h"
#import "AZErgoAPI.h"
#import "AZErgoChapterProtocol.h"

#import "AZDataProxy.h"

#import "AZErgoAPIRequest.h"

@interface AZErgoUtilsTab ()
@property (weak) IBOutlet NSTextField *tfDownloadedAmount;
@property (weak) IBOutlet NSTextField *tfSynkIP;

@property (weak) IBOutlet NSComboBox *cbServersList;
@property (weak) IBOutlet NSButton *bAPICall;
@property (weak) IBOutlet NSComboBox *cbAPICallText;
@property (unsafe_unretained) IBOutlet NSTextView *tfAPIResponse;

@end

@implementation AZErgoUtilsTab

+ (NSString *) tabIdentifier {
	return AZEPUIDUtilsTab;
}

- (void) updateContents {
	NSUInteger amount = PREF_INT(PREFS_COMMON_MANGA_DOWNLOADED) + [[AZDownloadSpeedWatcher sharedSpeedWatcher] totalDownloaded];
	self.tfDownloadedAmount.stringValue = [NSString cvtFileSize:amount withPrec:2];

	NSArray *storages = [AZStorage all];
	[self.cbServersList removeAllItems];
	for (AZStorage *storage in storages) {
		if ([storage.url length] > 0)
	    [self.cbServersList addItemWithObjectValue:storage.url];
	}
	if ([storages count] > 0)
		[self.cbServersList selectItemAtIndex:0];

//	id null = [NSNull null];
//	NSMutableDictionary *chaptersHash = [NSMutableDictionary new];
//	NSArray *downloads = [AZDownload all];
//	for (AZDownload *d in downloads) {
//		[d fixState];
//		if (HAS_BIT(d.state, AZErgoDownloadStateDownloaded))
//			d.proxifierHash = nil;
//
//		NSString *manga = d.forManga.name;
//		if (!manga) {
//			DDLogError(@"Download with unset manga! \n %@", d);
//			[d delete];
//			continue;
//		}
//
//		NSMutableDictionary *chapters = GET_OR_INIT(chaptersHash[manga], [NSMutableDictionary new]);
//		AZErgoUpdateWatch *watch = GET_OR_INIT(chapters[@(-2)], ([AZErgoUpdateWatch any:@"manga ==[c] %@", manga] ?: null));
//		if (watch != null) {
//			AZErgoUpdateChapter *chapter = GET_OR_INIT(chapters[@(d.chapter)], [watch chapterByIDX:d.chapter] ?: null);
//			if (chapter != null)
//				d.updateChapter = chapter;
//		}
//	}
}

- (void) synkDBs {
	NSDictionary *mangas = [[AZErgoManga all] mapWithKeyFromValueMapper:^id(AZErgoManga *entity) {
		return [entity.name lowercaseString];
	}];

	NSDictionary *mapping = @{
														@"heroicfantasy": @"heroic fantasy",
														@"web": @"webtoon",
														};
	[AZ_API(Ergo) aquireMangaDataFromIP:self.tfSynkIP.stringValue withCompletion:^(BOOL isOk, id data) {
		if (isOk) {
			AZ_Mutable(Array, *new);
			AZ_Mutable(Array, *unknownTags);

			NSArray *mangaData = data;

			for (NSDictionary *data in mangaData) {
				NSString *dirName = JSON_S(data, @"link");
				if (dirName) {
					[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context
						AZErgoManga *manga = mangas[[dirName lowercaseString]];
						if (!manga) {
							manga = [AZErgoManga mangaWithName:dirName];
							[new addObject:manga];
						}

						if (![manga.annotation length])
							manga.annotation = JSON_S(data, @"descr");

						if (![manga.tags count]) {
							for (NSString *tagName in JSON_O(data, @"jenres"))
								if (![tagName length])
									continue;
								else {
									AZErgoMangaTag *tag = [AZErgoMangaTag tagByName:mapping[tagName] ?: tagName];
									if (!tag) {
										[unknownTags addObject:tagName];
										DDLogWarn(@"Unknown tag: %@", tagName);
									} else
										[manga toggle:YES tag:tag];
								}
						}

						if ([manga.titles count] <= 1)
							[manga setAllTitles:JSON_O(data, @"titles")];

						float f = [JSON_F(data, @"progress") floatValue];
						AZErgoMangaProgress *p = manga.progress;
						BOOL noLocalP = _IDX(p.chapter) <= _IDX(1.f);
						BOOL hsRemotP = _IDX(f) >= _IDX(1.f);
						if ((!p) || (noLocalP && hsRemotP)) {
							p = manga.progress;
							p.chapter = f;
							p.page = 1;
							p.chapters = [AZErgoMangaChapter lastChapter:manga.name];
						}
					}];
				}
			}

			if ((!![new count])) {
				NSString *message = [new componentsJoinedByString:@". "];
				[AZAlert showAlert:LOC_FORMAT(@"There are new mangas (%@)", @([new count])) message:message];
			}
			if ((!![unknownTags count])) {
				NSString *message = [unknownTags componentsJoinedByString:@", "];
				[AZAlert showAlert:LOC_FORMAT(@"There are unknown tags") message:message];
			}

			if ((![new count]) && (![unknownTags count]))
				AZInfoTip(LOC_FORMAT(@"Done."));

		} else
			[AZAlert showAlert:LOC_FORMAT(@"Request error") message:data];

	}];
}

- (IBAction)actionSynchronizeData:(id)sender {
	[self synkDBs];
}

- (IBAction)actionCheckUnlinkedFolders:(id)sender {
	NSArray *folders = MANGA_STORAGE_FOLDERS;

	AZ_Mutable(Array, *unlinkedNonDld);
	AZ_Mutable(Array, *unlinkedHasDld);
	for (NSString *folder in folders) {
    AZErgoManga *linked = [AZErgoManga mangaByName:folder];

		if (!linked) {
			if (![AZDownload countOf:@"forManga.name ==[c] %@", folder])
				[unlinkedNonDld addObject:folder];
			else
				[unlinkedHasDld addObject:folder];
		}
	}

	if (!([unlinkedNonDld count] + [unlinkedHasDld count])) {
		AZInfoTip(LOC_FORMAT(@"No unlinked folders."));
		return;
	}


	NSString *withDownloads = (![unlinkedHasDld count]) ? @"" : LOC_FORMAT(@"Has downloads:\n<%@>", [unlinkedHasDld componentsJoinedByString:@">, <"]);
	NSString *withoutDownloads = (![unlinkedNonDld count]) ? @"" : LOC_FORMAT(@"%@Others:\n<%@>", [unlinkedHasDld count] ? @"\n" : @"", [unlinkedNonDld componentsJoinedByString:@">, <"]);

	NSString *all = [NSString stringWithFormat:@"%@%@", withDownloads, withoutDownloads];

	if (AZConfirm(LOC_FORMAT(@"There are unlinked folders:\n%@\n\nLink them?", all)))
		for (NSString *folder in [unlinkedHasDld arrayByAddingObjectsFromArray:unlinkedNonDld])
			[AZErgoManga mangaWithName:folder];
}

- (IBAction)actionRecalcDownloaded:(id)sender {

	NSDictionary *sum = [AZDownload fetch:[AZF_ANY pick:[[AZFE of:@"downloads" as:NSDecimalAttributeType] sum:@"downloaded"]]];

	NSUInteger downloaded = [sum[@"downloads"] unsignedIntegerValue];
	
//	NSArray * downloads = [AZDownload all:@"downloaded > 0"];
//	NSUInteger downloaded = 0;
//	for (AZDownload *download in downloads)
//		downloaded += download.downloaded;

	downloaded -= [[AZDownloadSpeedWatcher sharedSpeedWatcher] totalDownloaded];
	PREF_SAVE_INT(downloaded, PREFS_COMMON_MANGA_DOWNLOADED);

	[self updateContents];
}

- (IBAction)actionAPICall:(id)sender {
	NSString *call = self.cbAPICallText.stringValue;
	if (![call length])
		return;

	NSString *action = call;
	NSRange r = [call rangeOfString:@"?"];
	AZ_Mutable(Dictionary, *params);

	if (r.length != 0) {
		action = [call substringToIndex:r.location];
		call = [call substringFromIndex:r.location + 1];

		NSArray *parts = [call componentsSeparatedByString:@"&"];
		for (NSString *p in parts) {
			NSArray *p2 = [p componentsSeparatedByString:@"="];
			NSString *param = [p2 firstObject];
			if (!![param length])
				params[param] = [[p2 subarrayWithRange:NSMakeRange(1, [p2 count] - 1)] componentsJoinedByString:@"="];
		}
	}
	AZErgoAPIRequest *request = [AZErgoAPIRequest actionWithName:action];
	request.serverURL = [NSURL URLWithString:self.cbServersList.stringValue];
	request.parameters = params;
	request.timeout = 120;

	[self.bAPICall setEnabled:NO];
	[[[request success:^BOOL(AZHTTPRequest *action, __autoreleasing id *data) {
		dispatch_at_main(^{
			self.tfAPIResponse.string = [NSString stringWithFormat:@"REQUEST (%@):\n%@\n\nRESPONSE:\n%@", [NSDate date], action, *data];
			[self.bAPICall setEnabled:YES];
		});
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		dispatch_at_main(^{
			self.tfAPIResponse.string = [NSString stringWithFormat:@"REQUEST (%@):\n%@\n\nERROR:\n%@", [NSDate date], action, response];
			[self.bAPICall setEnabled:YES];
		});
		return YES;
	}] execute];
}

- (IBAction)actionCheckDBConsistency:(id)sender {
	NSArray *watches = [AZErgoUpdateWatch all];
	AZ_Mutable(Set, *sameGData);
	AZ_Mutable(Set, *sameManga);
	for (AZErgoUpdateWatch *watch in watches) {
		if (watch.genData) {
			NSString *genData = [[watch.source relatedSource] parseURL:watch.genData];
			if (![genData isEqualToString:watch.genData]) {
				watch.genData = genData;
			}
		}

    for (AZErgoUpdateWatch *test in [watches copy])
			if (watch != test) {
				if ([watch.genData isEqualToString:test.genData])
					[sameGData addObject:test];

				if ([watch.manga isEqualToString:test.manga])
					[sameManga addObject:test];
			}
	}

	if (!!([sameGData count] + [sameManga count])) {
		if (AZConfirm(LOC_FORMAT(@"There %lu colliding watches with same generic data and %lu pointed to same manga. Delete collisions?", [sameGData count], [sameManga count]))) {

			NSMutableArray *d = [NSMutableArray new];
			for (AZErgoUpdateWatch *watch in sameGData) {
				if (![AZErgoManga mangaByName:watch.manga]) {
					[d addObject:watch];
				}
			}

			for (AZErgoUpdateWatch *watch in sameManga) {
				if (![watch.updates count]) {
					[d addObject:watch];
				}
			}

			AZInfoTip((![d count]) ? LOC_FORMAT(@"Nothing can be deleted automatically") : LOC_FORMAT(@"Delete %lu colliding watches?\n\n%@", [d count], [d componentsJoinedByString:@"\n"]));
		}
	}

	[self checkProxifiers];

	[self checkStorages];

	[self checkFolders];
}

- (void) checkProxifiers {
	NSArray *proxifiers = [AZProxifier all];
	AZ_Mutable(Dictionary, *mapped);
	for (AZProxifier *proxifier in proxifiers) {
    id key = proxifier.url ?: @"";
		NSMutableArray *a = mapped[key] ?: (mapped[key] = [NSMutableArray new]);
		[a addObject:proxifier];
	}

	NSUInteger overlaps = 0;
	for (NSArray *proxifiers in [mapped allValues])
    if ([proxifiers count] > 1) {
			overlaps += [proxifiers count] - 1;
		}

	if (overlaps > 0)
		if (AZConfirm(LOC_FORMAT(@"Proxifiers: %lu, groups: %lu (%@), overlaps: %lu\nFix?", [proxifiers count], [mapped count], [[mapped allKeys] componentsJoinedByString:@"~"], overlaps))) {

			for (NSArray *proxifiers in [mapped allValues])
				if ([proxifiers count] > 1) {
					NSMutableArray *copy = [proxifiers mutableCopy];
					AZProxifier *base = [copy lastObject];
					[copy removeObjectIdenticalTo:base];

					for (AZProxifier *proxifier in copy)
						if ([proxifier.storages count] + [proxifier.downloads count] > 0) {
							[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context
								base.storages = [base.storages setByAddingObjectsFromSet:proxifier.storages];
								base.downloads = [base.downloads setByAddingObjectsFromSet:proxifier.downloads];
							}];
						} else
							[proxifier delete];
				}

			AZInfoTip(LOC_FORMAT(@"Fixed"));
		}
}

- (void) checkStorages {
	NSString *noURI = @"";
	NSUInteger duplicates = 0;
	NSArray *storages = [AZStorage all];
	AZ_Mutable(Dictionary, *mapped);
	for (AZStorage *storage in storages) {
    id key = storage.url ?: noURI;
		NSMutableArray *a = mapped[key] ?: (mapped[key] = [NSMutableArray new]);
		[a addObject:storage];
	}

	NSUInteger sDownloads = 0, tDownloads = 0;
	for (NSArray *storages in [mapped allValues])
		if ([storages count] > 0) {
			if ([storages count] > 1)
				duplicates += [storages count];

			NSUInteger sd = 0;
			for (AZStorage *storage in storages) {
				NSUInteger d = [storage.downloads count];

				if ((d > 0) && (sd != 0))
					sDownloads += d;

				sd += d;
			}

			tDownloads += sd;
		}

	if (duplicates) {
		NSString *message = LOC_FORMAT(@"Storages: %lu (%@), duplicates: %lu, downloads in duplicates: %lu (/%lu), storages without url: %lu\nFix?",
																	 [[mapped allKeys] count], [[mapped allKeys] componentsJoinedByString:@"~"],
																	 duplicates, sDownloads, tDownloads,
																	 [mapped[noURI] count]);

		if (AZConfirm(message)) {
			for (NSArray *storages in [mapped allValues])
				if ([storages count] > 1) {
					NSMutableArray *copy = [storages mutableCopy];

					AZStorage *base = [copy firstObject];
					[copy removeObjectIdenticalTo:base];

					for (AZStorage *storage in copy)
						if ([storage.downloads count] > 0) {
							[[AZDataProxy sharedProxy] detachContext:^(NSManagedObjectContext *context) {
			//TODO:detached context
								base.downloads = [base.downloads setByAddingObjectsFromSet:storage.downloads];
							}];
						} else
							[storage delete];
				}

			AZInfoTip(LOC_FORMAT(@"Fixed"));
		}
	}
}

- (void) checkFolders {
	NSUInteger mod = 0;
	NSArray *watches = [AZErgoUpdateWatch all];
	for (AZErgoUpdateWatch *watch in watches) {
    AZErgoManga *manga = [AZErgoManga mangaByName:watch.manga];
		if (![watch.manga isEqualToString:manga.name]) {
			mod++;

			NSString *folder = [[NSFileManager defaultManager ] fileExistsAtPath:watch.manga isDirectory:NULL] ? watch.manga : manga.name;

			manga.name = folder;
			watch.manga = folder;
		}
	}

	if (mod > 0)
		AZInfoTip(LOC_FORMAT(@"There was %lu unmatched watch->manga folder links", mod));
}

@end
