//
//  AZErgoUpdatesGroupCellView.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesGroupCellView.h"
#import "KeyedHolder.h"
#import "CustomDictionary.h"

#import "AZErgoUpdatesCommons.h"
#import "AZErgoMangaCommons.h"

@interface AZErgoUpdatesGroupCellView () <AZErgoUpdateWatchDelegate>

@end

MULTIDELEGATED_INJECT_LISTENER(AZErgoUpdatesGroupCellView)

@implementation AZErgoUpdatesGroupCellView

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	KeyedHolder *holder = ((CustomDictionary *)entity)->owner;
	self.bindedEntity = holder->holdedObject;

	AZ_IFCLASS(self.bindedEntity, AZErgoUpdatesSourceDescription, *source, {
		self.tfHeader.stringValue = LOC_FORMAT(@"%@ (%@ watches)", source.serverURL ?: @"", @([source.watches count]));

		[self showState:nil];
		[self watch:nil stateChanged:NO];
	}) else
		AZ_IFCLASS(self.bindedEntity, AZErgoUpdateWatch, *watch, {
			[self bindAsDelegateTo:watch solo:NO];

			NSString *mangaName = watch.manga ?: LOC_FORMAT(@"<manga name not set>");

			AZErgoManga *manga = [AZErgoManga mangaByName:mangaName];

			NSString *title = LOC_FORMAT(@" ⟩ %@", [manga description]);

			[self showState:watch];
			self.tfHeader.stringValue = title;

			[self watch:watch stateChanged:watch.checking];

		});
}

- (void) showState:(AZErgoUpdateWatch *)watch {
	[self.vStatusBlock setCollapsed:!watch];
	[self.bInfo setHidden:!watch];
	if (!watch) {
		self.tfHeader.textColor = [NSColor textColor];
		return;
	}

	NSArray *updates = [[watch.updates allObjects] sortedArrayUsingComparator:^NSComparisonResult(AZErgoUpdateChapter *c1, AZErgoUpdateChapter *c2) {
		return SIGN(c2.idx - c1.idx);
	}];

	NSUInteger scheduled = 0, new = 0, total = [updates count];
	BOOL skip = NO;
	for (AZErgoUpdateChapter *chapter in updates)
		if (chapter.idx < 0)
			total--;
		else
			if (!skip)
				switch ([watch chapterState:chapter]) {
					case AZErgoUpdateChapterDownloadsDownloaded:
						skip = YES;
						break;

					case AZErgoUpdateChapterDownloadsNone:
						new++;
						break;

					case AZErgoUpdateChapterDownloadsPartial:
						scheduled++;
						break;
					default:
						new++;
				}

	NSUInteger downloaded = total - (new + scheduled);

	[self.tfDownloaded setHidden:!downloaded];
	[self.ivDownloaded setHidden:!downloaded];

	[self.tfScheduled setHidden:!scheduled];
	[self.ivScheduled setHidden:!scheduled];

	[self.tfNew setHidden:!new];
	[self.ivNew setHidden:!new];

	AZErgoManga *manga = [AZErgoManga mangaByName:watch.manga];

	BOOL hasUpdates = (downloaded > 0) && (new > 0);
	BOOL isNew = (downloaded == 0) && (new > 0);
	BOOL isComplete = manga.isComplete;
	BOOL isReaded = manga.isReaded;
	NSColor *tc = [NSColor textColor];

	if (isReaded && (hasUpdates || isNew))
		tc = [NSColor magentaColor];
	else
		if (hasUpdates)
			tc = [NSColor blueColor];
		else
			if (isNew)
				tc = [NSColor darkGreenColor];
			else
				if (isComplete)
					tc = [NSColor tealColor];

	self.tfHeader.textColor = tc;

	self.tfDownloaded.stringValue = [@(downloaded) stringValue];
	self.tfScheduled.stringValue = [@(scheduled) stringValue];
	self.tfNew.stringValue = [@(new) stringValue];
}

- (void) watch:(AZErgoUpdateWatch *)watch stateChanged:(BOOL)checking {
	__weak id wSelf = self;

	dispatch_async_at_background(^{
		dispatch_sync_at_main(^{
			AZErgoUpdatesGroupCellView *sSelf = wSelf;
			if (!sSelf)
				return;

			if (checking)
				[sSelf.piProgressIndicator startAnimation:watch];
			else
				[sSelf.piProgressIndicator stopAnimation:watch];

			[sSelf setNeedsLayout:YES];
		});
	});
}

@end
