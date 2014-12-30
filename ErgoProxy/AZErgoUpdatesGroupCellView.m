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

#import "AZErgoUpdateChapter.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdatesSource.h"
#import "AZErgoUpdatesSourceDescription.h"

@interface AZErgoUpdatesGroupCellView () <AZErgoUpdateWatchDelegate>

@end

@implementation AZErgoUpdatesGroupCellView

- (void) configureForEntity:(id)entity inOutlineView:(NSOutlineView *)view {
	KeyedHolder *holder = ((CustomDictionary *)entity)->owner;
	self.bindedEntity = holder->holdedObject;

	if ([self.bindedEntity isKindOfClass:[AZErgoUpdatesSourceDescription class]]) {
		AZErgoUpdatesSourceDescription *source = self.bindedEntity;

		self.tfHeader.stringValue = source.serverURL ?: @"";

		[self watch:nil stateChanged:NO];
	} else
		if ([self.bindedEntity isKindOfClass:[AZErgoUpdateWatch class]]) {
			AZErgoUpdateWatch *watch = self.bindedEntity;

			watch.delegate = self;

			NSString *mangaName = watch.manga ?: @"<manga name not set>";
			NSString *title = watch.title ? [NSString stringWithFormat:@"%@ (%@)", watch.title, mangaName] : mangaName;

			self.tfHeader.stringValue = title;

			[self watch:watch stateChanged:watch.checking];
		}

}

- (void) watch:(AZErgoUpdateWatch *)watch stateChanged:(BOOL)checking {
	__weak id wSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		dispatch_sync(dispatch_get_main_queue(), ^{
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
