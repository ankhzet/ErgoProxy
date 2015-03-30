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

@interface AZErgoMangaTab () <AZErgoMangaViewItemDelegate> {
	BOOL skipWithoutUnread;
	BOOL skipNotTagged;
	BOOL skipSkipped;
	BOOL skipWithoutChapters;
}
@property (weak) IBOutlet NSCollectionView *cvManga;

@end

@implementation AZErgoMangaTab

- (id)init {
	if (!(self = [super init]))
		return self;

	skipWithoutUnread = 1;
	skipWithoutChapters = 1;
	skipNotTagged = 0;
	skipSkipped = 0;

	return self;
}

- (NSString *) tabIdentifier {
	return AZEPUIDMangaTab;
}

- (void) show {
	self.cvManga.delegate = (id)self;
	self.cvManga.minItemSize = NSMakeSize(300, 92);
	self.cvManga.maxItemSize = NSMakeSize(0, 92);

	[super show];
}

- (void) updateContents {
	[self delayed:@"fetch" withBlock:^{
		[self fetchManga];
	}];
}

- (NSArray *) fetchList {
	NSString *filter = skipNotTagged ? @"tags.@count > 0" : nil;
	NSArray *fetch = [AZErgoManga all:filter];

	if (skipSkipped) {
		NSArray *tags = [AZErgoMangaTag all:@"skip > 0"];
		if ([tags count]) {
			NSMutableArray *mfetch = [fetch mutableCopy];
			for (AZErgoMangaTag *tag in tags)
				[mfetch removeObjectsInArray:[tag.manga allObjects]];

			fetch = mfetch;
		}
	}

	return fetch;
}

#define AZE_GROUP_HAS_NEW @0
#define AZE_GROUP_NO_NEW  @1
#define AZE_GROUP_UNREAD  @2
#define AZE_GROUP_READED  @3


- (NSDictionary *) groupList:(NSArray *)list {
	NSMutableDictionary *result = [NSMutableDictionary new];

#define AZ_TAKE_OR_INIT(_from, _init) ({(_from) ?: ((_from) = (_init));})

	for (AZErgoManga *manga in list) {
    if (manga.isReaded)
			[AZ_TAKE_OR_INIT(result[AZE_GROUP_READED], [NSMutableArray new]) addObject:manga];
		else
			if (manga.progress.hasReadedAndUnreaded)
				[AZ_TAKE_OR_INIT(result[AZE_GROUP_HAS_NEW], [NSMutableArray new]) addObject:manga];
			else
				if (manga.progress.hasUnreaded)
					[AZ_TAKE_OR_INIT(result[AZE_GROUP_UNREAD], [NSMutableArray new]) addObject:manga];
				else
					[AZ_TAKE_OR_INIT(result[AZE_GROUP_NO_NEW], [NSMutableArray new]) addObject:manga];
	}

	return result;
}

- (NSArray *) filterUnread:(NSArray *)list {
	list = [list objectsAtIndexes:[list indexesOfObjectsPassingTest:^BOOL(AZErgoManga *manga, NSUInteger idx, BOOL *stop) {
		return !manga.progress.hasReaded;
	}]];
	return list;
}

- (void) fetchManga {
	// 1. Fetch
	// 2. Filter

	NSArray *list = [self fetchList];

	[self checkFS:list withCompletion:^(NSArray *list) {
		if (skipWithoutChapters || skipWithoutUnread)
			list = [list objectsAtIndexes:[list indexesOfObjectsPassingTest:^BOOL(AZErgoManga *manga, NSUInteger idx, BOOL *stop) {
				BOOL pass = YES;
				if (skipWithoutChapters)
					pass &= manga.progress.chapters > 0;

				if (pass && skipWithoutUnread)
					pass &= manga.progress.hasUnreaded;

				return pass;
			}]];


		// 3. Groupping
		NSMutableArray *result = [NSMutableArray arrayWithCapacity:[list count]];
		NSDictionary *groups = [self groupList:list];
		NSArray *groupsOrder = [[groups allKeys] sortedArrayUsingSelector:@selector(compare:)];
		NSArray *sorted = [groupsOrder sortValuesOf:groups];
		// 4. Groups ordering
		for (NSArray *group in sorted) {
			NSArray *unreaded = [self filterUnread:group];
			NSMutableSet *s = [NSMutableSet setWithArray:group];
			[s minusSet:[NSSet setWithArray:unreaded]];
			NSArray *readed = [s allObjects];

			//    1. Order by read history
			readed = [readed sortedArrayUsingComparator:^NSComparisonResult(AZErgoManga *m1, AZErgoManga *m2) {
				AZErgoMangaProgress *p1 = m1.progress;
				AZErgoMangaProgress *p2 = m2.progress;

				NSComparisonResult r = [p2.updated compare:p1.updated];

				//    2. Order equalities by name
				if (r == NSOrderedSame)
					r = [m1.mainTitle caseInsensitiveCompare:m2.mainTitle];

				return r;
			}];

			//    3. Order not readed by name and move to tail
			unreaded = [unreaded sortedArrayUsingComparator:^NSComparisonResult(AZErgoManga *m1, AZErgoManga *m2) {
				return [m1.mainTitle caseInsensitiveCompare:m2.mainTitle];
			}];

			[result addObjectsFromArray:readed];
			[result addObjectsFromArray:unreaded];
		}
		
		[self.cvManga performWithSavedScroll:^{
			if (AZ_KEYDOWN(Shift))
				self.cvManga.content = nil;

			self.cvManga.content = result;
		}];
	}];
}

- (void) checkFS:(NSArray *)fetch withCompletion:(void(^)(NSArray *fetch))block {
	AZ_Mutable(Array, *toCheck);
	for (AZErgoManga *manga in fetch)
    if (manga.hasToCheckFS)
			[toCheck addObject:manga];

	if (!![toCheck count]) {
		[self delayed:@"fetch" forTime:0 withBlock:^{
			dispatch_async_at_background(^{
				dispatch_queue_t queue = dispatch_queue_create("manga-list-chapters-fetch", DISPATCH_QUEUE_CONCURRENT);

				NSUInteger total = [toCheck count];
				NSUInteger slice = 5;
				NSUInteger batch = 0;
				do {
					batch = total / --slice;
				} while (batch < 1);

				NSUInteger left = total - batch * slice;

				void(^apply_to)(id) = ^(NSArray *subCheck) {
					for (AZErgoManga *manga in subCheck)
						[manga checkFSWithCompletion:nil];
				};

				dispatch_apply(slice + !!(left > 0), queue, ^(size_t index) {
					NSRange range = NSMakeRange(index * batch, batch);
					if (index >= slice)
						range.length = left;

					apply_to([toCheck subarrayWithRange:range]);
				});

				dispatch_at_main(^{
					block(fetch);
				});

			});
		}];
	} else
		block(fetch);
}

- (IBAction)actionShowTagBrowser:(id)sender {
	[self.tabs navigateTo:AZEPUIDTagBrowserTab withNavData:nil];
}

- (void) viewItem:(id)sender read:(AZErgoManga *)entity {
	[self.tabs navigateTo:AZEPUIDBrowserTab withNavData:entity];
}

- (void) viewItem:(id)sender showInfo:(AZErgoManga *)entity {
	[self.tabs navigateTo:AZEPUIDMangaInfoTab withNavData:@{@"manga": entity}];
}

@end
