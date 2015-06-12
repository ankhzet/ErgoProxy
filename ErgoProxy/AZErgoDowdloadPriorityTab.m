//
//  AZErgoDowdloadPriorityTab.m
//  ErgoProxy
//
//  Created by Ankh on 04.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoDowdloadPriorityTab.h"
#import "AZErgoDownloadPrioritiesDataSource.h"
#import "AZErgoMangaCommons.h"
#import "AZDownload.h"
#import "AZDataProxy.h"

@interface AZErgoDowdloadPriorityTab () {
	AZGroupableDataSource *_priorities;
}

@property (weak) IBOutlet NSOutlineView *ovPriorities;

@end

@implementation AZErgoDowdloadPriorityTab

+ (NSString *) tabIdentifier {
	return AZEPUIDDownloadPriorityTab;
}

- (AZGroupableDataSource *) priorities {
	if (!_priorities) {
		_priorities = [[AZErgoDownloadPrioritiesDataSource new] setTo:self.ovPriorities];
		_priorities.groupped = NO;
	}
	return _priorities;
}

- (void) updateContents {
	[self delayed:@"fetch-priorities" withBlock:^{
		[self fetch:YES];
	}];
}

- (void) fetch:(BOOL)fullFetch {
	NSArray *fetched = [AZErgoManga allDownloaded:NO];
	AZ_Mutable(Array, *data);

	for (AZErgoManga *manga in fetched) {
		if (!manga.name) {
			DDLogWarn(@"! %@", manga.objectID);
			continue;
		}
		NSUInteger count = [AZDownload countOf:@"(forManga.name == %@) and ((totalSize == 0) or (downloaded < totalSize))", manga.name];
		if (count > 0)
			[data addObject:manga];
	}

	for (AZErgoManga *manga in data)
		if (!manga.order)
			manga.order = [data indexOfObjectIdenticalTo:manga] + 1;

	self.priorities.data = data;

	dispatch_async_at_main(^{
		[self.ovPriorities performWithSavedScroll:^{
			[self.ovPriorities reloadData];
			[self.ovPriorities expandItem:nil expandChildren:YES];
		}];
	});
}

@end
