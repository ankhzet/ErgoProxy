//
//  AZErgoChapterStateItemCellView.m
//  ErgoProxy
//
//  Created by Ankh on 06.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChapterStateItemCellView.h"

#import "AZErgoUpdateChapter.h"
#import "AZErgoMangaCommons.h"
#import "AZDownload.h"
#import "AZErgoUpdateChapterMapping.h"

@interface AZErgoChapterStateItemCellView () <AZErgoUpdateChapterProtocol>

@property (weak) IBOutlet NSTextField *tfChapterID;
@property (weak) IBOutlet NSButton *bDownloaded;
@property (weak) IBOutlet NSButton *bChecked;

@end

@implementation AZErgoChapterStateItemCellView

- (void) setBindedEntity:(id)bindedEntity {
	[super setBindedEntity:bindedEntity];

	AZErgoUpdateChapter *chapter = bindedEntity;
	double chapterIDX = chapter.idx;
	NSString *chapterFolder;
	BOOL hasFolder = [self hasFolder:&chapterFolder forChapter:&chapterIDX];

	if (!hasFolder && (_IDX(chapterIDX) != _IDX(chapter.idx)))
		self.tfChapterID.textColor = [NSColor blueColor];
	else
		self.tfChapterID.textColor = [NSColor textColor];

	if ([chapter.watch.relatedManga mappingForChapter:chapter.baseIdx inVolume:chapter.volume])
		self.tfChapterID.textColor = [NSColor greenColor];

	AZErgoUpdateChapterDownloads state = [chapter.watch chapterState:chapter];

	self.tfChapterID.stringValue = chapterFolder;
	[self.tfChapterID setToolTip:[@(chapter.baseIdx) stringValue]];

	self.bChecked.state = hasFolder ? NSOnState : NSOffState;

	self.bDownloaded.state = (state == AZErgoUpdateChapterDownloadsDownloaded) ? NSOnState : NSOffState;
}

- (NSString *) plainTitle {
	return [self.bindedEntity fullTitle];
}

- (AZErgoUpdateChapter *) chapter {
	return (id)self.bindedEntity;
}

- (AZErgoManga *) relatedManga {
	return [AZErgoManga mangaByName:self.chapter.watch.manga];
}

- (BOOL) isMarkedAsDownloaded {
	return self.bDownloaded.state == NSOnState;
}

- (BOOL) hasFolder:(NSString **)folder forChapter:(double *)resolvedChapterIDX {
	double chapterIDX = *resolvedChapterIDX;

	NSString *mangaFolder = [self.relatedManga mangaFolder];
	NSString *chapterFolder = [AZErgoMangaChapter formatChapterID:chapterIDX];

	*folder = chapterFolder;

	NSString *path = [NSString pathWithComponents:@[mangaFolder, chapterFolder]];

	BOOL hasFolder = [[NSFileManager defaultManager] fileExistsAtPath:path];
	if (!hasFolder && (chapterIDX > 999)) {
		chapterIDX = ((int)(chapterIDX * 10) % 10000) / 10.;

		chapterFolder = [AZErgoMangaChapter formatChapterID:chapterIDX];
		path = [NSString pathWithComponents:@[mangaFolder, chapterFolder]];

		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			*folder = chapterFolder;
			*resolvedChapterIDX = chapterIDX;
		}
	} else {
	}

	return hasFolder;
}

- (IBAction) actionCheckedChanged:(id)sender {
	AZErgoUpdateChapter *chapter = self.bindedEntity;
	double chapterIDX = chapter.idx;
	NSString *chapterFolder = [AZErgoMangaChapter formatChapterID:chapterIDX];
	NSString *newFolder = chapterFolder;

	BOOL hasFolder = [self hasFolder:&chapterFolder forChapter:&chapterIDX];

	if (hasFolder || (_IDX(chapterIDX) == _IDX(chapter.idx)))
		return;

	NSString *mangaFolder = [self.relatedManga mangaFolder];
	NSString *pathOld = [NSString pathWithComponents:@[mangaFolder, chapterFolder]];
	NSString *pathNew = [NSString pathWithComponents:@[mangaFolder, newFolder]];

	NSError *error;
	if (![[NSFileManager defaultManager] moveItemAtPath:pathOld toPath:pathNew error:&error])
		AZErrorTip(LOC_FORMAT(@"Rename failed!\nFrom: %@\nTo: %@", pathOld, pathNew));
	else {
		self.tfChapterID.textColor = [NSColor textColor];
		self.tfChapterID.stringValue = newFolder;
	}
}

- (IBAction) actionChapterIDChanged:(id)sender {
	NSString *newID = self.tfChapterID.stringValue;
	if (![newID length])
		return;

	if ([newID rangeOfString:@":"].location == NSNotFound)
		return;

	double chapterIDX = [[newID stringByReplacingOccurrencesOfString:@":" withString:@""] doubleValue];
	double oldIDX = self.chapter.idx;

	if (AZ_KEYDOWN(Shift)) {
		AZErgoUpdateChapterMapping *mapping = [self.relatedManga mappingForChapter:oldIDX inVolume:self.chapter.volume];
		if (!mapping) {
			mapping = [AZErgoUpdateChapterMapping insertNew];
			mapping.manga = self.relatedManga;
			mapping.volume = self.chapter.volume;
			mapping.sourceIDX = self.chapter.baseIdx;
		}

		mapping.mappedIDX = chapterIDX;
	}

	[self.chapter setIdx:chapterIDX];

	self.tfChapterID.textColor = [NSColor textColor];
	self.tfChapterID.stringValue = [AZErgoMangaChapter formatChapterID:chapterIDX];
}

- (void) update:(AZErgoUpdateChapter *)update stateChanged:(AZErgoUpdateChapterDownloads)state {
	self.bDownloaded.state = (state == AZErgoUpdateChapterDownloadsDownloaded) ? NSOnState : NSOffState;
}

@end
