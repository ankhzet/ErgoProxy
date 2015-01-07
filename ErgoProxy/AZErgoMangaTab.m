//
//  AZErgoMangaTab.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaTab.h"
#import "AZErgoMangaCommons.h"
#import "AZErgoMangaAddWindowController.h"
#import "AZErgoMangaViewItem.h"

@interface AZErgoMangaTab () <AZErgoMangaViewItemDelegate>
@property (weak) IBOutlet NSCollectionView *cvManga;

@end

@implementation AZErgoMangaTab

- (NSString *) tabIdentifier {
	return AZEPUIDMangaTab;
}

- (void) show {
	self.cvManga.delegate = (id)self;
	self.cvManga.minItemSize = NSMakeSize(300, 102);
	self.cvManga.maxItemSize = NSMakeSize(0, 102);
	[super show];
}

- (void) updateContents {
	[self delayed:@"fetch" withBlock:^{
		[self fetchManga:YES];
	}];
}

- (void) fetchManga:(BOOL)full {
	NSPredicate *filter = nil;//[NSPredicate predicateWithFormat:@"tags.skip.@count <= 0"];
	NSArray *fetch = [AZErgoManga filter:filter limit:0];

	fetch = [fetch sortedArrayUsingComparator:^NSComparisonResult(AZErgoManga *m1, AZErgoManga *m2) {
		return [m1.mainTitle caseInsensitiveCompare:m2.mainTitle];
	}];

	fetch = [fetch objectsAtIndexes:[fetch indexesOfObjectsPassingTest:^BOOL(AZErgoManga *manga, NSUInteger idx, BOOL *stop) {
		for (AZErgoMangaTag *tag in [manga.tags allObjects])
			if (tag.skip)
				return NO;

		return YES;
	}]];

	self.cvManga.content = nil;
	self.cvManga.content = fetch;
}

- (IBAction)actionShowTagBrowser:(id)sender {
	[self.tabs navigateTo:AZEPUIDTagBrowserTab withNavData:nil];
}

- (void) viewItem:(id)sender read:(AZErgoManga *)entity {
	[self.tabs navigateTo:AZEPUIDBrowserTab withNavData:entity.name];
}

- (void) viewItem:(id)sender showInfo:(AZErgoManga *)entity {
	[self.tabs navigateTo:AZEPUIDMangaInfoTab withNavData:@{@"manga": entity}];
}

@end
