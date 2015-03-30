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

@interface AZErgoChapterStateItemCellView ()

@property (weak) IBOutlet NSTextField *tfChapterID;
@property (weak) IBOutlet NSButton *bDownloaded;
@property (weak) IBOutlet NSButton *bChecked;

@end

@implementation AZErgoChapterStateItemCellView

- (void) setBindedEntity:(id)bindedEntity {
	[super setBindedEntity:bindedEntity];

	AZErgoUpdateChapter *chapter = bindedEntity;
	AZErgoManga *manga = [AZErgoManga mangaByName:chapter.watch.manga];
	NSString *chapterFolder = [AZErgoMangaChapter formatChapterID:chapter.idx];
	NSString *path = [NSString pathWithComponents:@[[manga mangaFolder], chapterFolder]];
	BOOL hasFolder = [[NSFileManager defaultManager] fileExistsAtPath:path];
	AZErgoUpdateChapterDownloads state = [chapter.watch chapterState:chapter];

	self.tfChapterID.stringValue = chapterFolder;
	self.bChecked.state = hasFolder ? NSOnState : NSOffState;
	self.bDownloaded.state = (state == AZErgoUpdateChapterDownloadsDownloaded) ? NSOnState : NSOffState;
}

- (NSString *) plainTitle {
	return [self.bindedEntity fullTitle];
}

- (IBAction) actionDownloadChanged:(id)sender {
	BOOL isDownloaded = self.bDownloaded.state == NSOnState;

	if (!isDownloaded) {
		AZErgoUpdateChapter *chapter = self.bindedEntity;
		NSArray *downloads = [AZDownload manga:chapter.watch.manga hasChapterDownloads:chapter.idx];
		for (AZDownload *download in downloads)
			[download reset:nil];

		chapter.state = AZErgoUpdateChapterDownloadsUnknown;
	}
}

- (IBAction) actionCheckedChanged:(id)sender {

}

- (IBAction) actionChapterIDChanged:(id)sender {

}

@end
