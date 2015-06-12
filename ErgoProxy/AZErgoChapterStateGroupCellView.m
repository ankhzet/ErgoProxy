//
//  AZErgoChapterStateGroupCellView.m
//  ErgoProxy
//
//  Created by Ankh on 06.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoChapterStateGroupCellView.h"
#import "CustomDictionary.h"
#import "AZErgoUpdatesCommons.h"
#import "AZDownload.h"

@interface AZErgoChapterStateGroupCellView ()

@property (weak) IBOutlet NSButton *cbDownloaded;

@end

@implementation AZErgoChapterStateGroupCellView

- (void) setBindedEntity:(id)bindedEntity {
	[super setBindedEntity:bindedEntity];

	self.cbDownloaded.state = [self isDownloaded:bindedEntity] ? NSOnState : NSOffState;
}

- (IBAction) actionDownloadedChanged:(id)sender {
	[self markEntity:self.bindedEntity downloaded:[self isMarkedAsDownloaded]];
}

- (BOOL) isDownloaded:(id)entity {
	AZ_IFCLASS(entity, CustomDictionary, *entities, {
		BOOL result = YES;
		for (id entity in [entities allValues])
			result &= [self isDownloaded:entity];

		return result;
	}) else
		return [(AZErgoUpdateChapter *)entity state] == AZErgoUpdateChapterDownloadsDownloaded;
}

- (void) markEntity:(id)entity downloaded:(BOOL)downloaded {
	AZ_IFCLASS(entity, CustomDictionary, *entities, {
		for (id entity in [entities allValues])
			[self markEntity:entity downloaded:downloaded];
	}) else {
		AZErgoUpdateChapter *chapter = entity;

		if (!downloaded) {
			for (AZDownload *download in chapter.downloads)
				[download reset:nil];

			chapter.state = AZErgoUpdateChapterDownloadsUnknown;
		} else
			chapter.state = AZErgoUpdateChapterDownloadsDownloaded;
	}
}

- (BOOL) isMarkedAsDownloaded {
	return self.cbDownloaded.state == NSOnState;
}

@end
