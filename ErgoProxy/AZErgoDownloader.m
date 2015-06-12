//
//  AZErgoDownloader.m
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloader.h"
#import "AZDownload.h"
#import "AZErgoProxifierAPI.h"

#import "AZDataProxy.h"

MULTIDELEGATED_INJECT_MULTIDELEGATED(AZErgoDownloader)

@implementation AZErgoDownloader

- (id)init {
	if (!(self = [super init]))
		return self;

	_concurentTasks = PREF_STR(PREFS_DOWNLOAD_PER_STORAGE);
	_consecutiveIterationsInterval = 10.;//30.;
	_paused = NO;
	_running = NO;

	[NSUserDefaults notify:self onDefaultsChange:@selector(defaultsChanged:)];

	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) defaultsChanged:(NSNotification *)notification {
	_concurentTasks = PREF_STR(PREFS_DOWNLOAD_PER_STORAGE);
}

+ (instancetype) downloaderForStorage:(AZStorage *)storage {
	AZErgoDownloader *downloader = [AZErgoDownloader new];
	downloader.storage = storage;
	return downloader;
}

- (void) setPaused:(BOOL)paused {
	if (_paused == paused)
		return;

	_paused = paused;
	[self.md_delegate downloader:self stateSchanged:paused ? AZErgoDownloaderStateWorking : AZErgoDownloaderStateIddle];
}

@end

@implementation AZErgoDownloader (Downloading)

- (void) pause {
	self.paused = YES;
}

- (void) resume {
	self.paused = NO;
}

- (void) stop {
	_running = NO;
	self.paused = NO;
}

- (void) processDownloads {
	@synchronized(self) {
		if (self.running)
			return;

		_running = YES;
		[self pause];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			[self resume];
			@try {
				while (self.running) {
					msleep(0.5);

					if (self.paused)
						continue;

					@autoreleasepool {
						[self pickDownload];
					}
				}
			}
			@finally {
				_running = NO;
			}
		});
	}
}

- (NSDictionary *) workingTasks {
	NSMutableDictionary *typesInProcess = [NSMutableDictionary new];
	NSMutableArray *all = typesInProcess[@0] = [NSMutableArray new];

	@synchronized(self.downloads) {
		for (AZDownload *download in [self.downloads allValues]) {
			BOOL processing = HAS_BIT(download.state, AZErgoDownloadStateProcessing);

			if (processing) {
				AZErgoDownloadState state = [self nextToAquire:download.state];

				NSMutableArray *tasks = typesInProcess[@(state)] ?: (typesInProcess[@(state)] = [NSMutableArray new]);
				[tasks addObject:download];
				[all addObject:download];
			}
		}
	}

	return typesInProcess;
}

- (NSArray *) doneTasks {
	BOOL resolver = !self.storage;

	@synchronized(self.downloads) {
		NSMutableArray *all = [NSMutableArray arrayWithCapacity:[self.downloads count]];

		for (AZDownload *download in [self.downloads allValues]) {
			AZErgoDownloadState state = download.state;

			if (HAS_BIT(state, AZErgoDownloadStateDownloaded) || download.isDeleted || (resolver && HAS_BIT(state, AZErgoDownloadStateResolved)))
				[all addObject:download];
		}

		return all;
	}
}

- (NSUInteger) concurentTasks:(NSUInteger)type {
	NSArray *c = [self.concurentTasks componentsSeparatedByString:@","];
	while ([c count] < MAX(3, type + 1))
		c = [@[@"1"] arrayByAddingObjectsFromArray:c];

	return [[c[type] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] integerValue];
}

- (AZErgoDownloadState) nextToAquire:(AZErgoDownloadState)state {
	if (!HAS_BIT(state, AZErgoDownloadStateResolved))
		return AZErgoDownloadStateResolved;
	else
		if (!HAS_BIT(state, AZErgoDownloadStateAquired))
			return AZErgoDownloadStateAquired;
		else
			return AZErgoDownloadStateDownloaded;
}

- (NSUInteger) stateToTypeIDX:(AZErgoDownloadState)state {
	switch (state) {
		case AZErgoDownloadStateDownloaded:
			return 2;

		case AZErgoDownloadStateAquired:
			return 1;

		case AZErgoDownloadStateResolved:
		default:
			return 0;
	}
}

- (void) pickDownload {
	@synchronized([[AZDataProxy sharedProxy] managedObjectContext]) {

		NSArray *candidates;

		@synchronized(self.downloads) {
			candidates = [[self.downloads allValues] mutableCopy];
		}

		AZ_Mutable(Dictionary, *typesInProcess);
		@synchronized(self) {
			[(NSMutableArray *)candidates removeObjectsInArray:[self doneTasks]];

			NSDictionary *working = [self workingTasks];
			for (NSNumber *state in working)
				if ([state unsignedIntegerValue] == 0) {
					NSArray *all = working[state];
					[(NSMutableArray *)candidates removeObjectsInArray:all];
					_inProcess = [all count];
				} else
					typesInProcess[state] = @([working[state] count]);
		}

		NSUInteger cCount = [candidates count];

		if (!cCount)
			return;

		NSInteger maxTasks = 0;
		for (NSNumber *limit in @[@(AZErgoDownloadStateResolved), @(AZErgoDownloadStateDownloaded), @(AZErgoDownloadStateAquired)])
			maxTasks += [self concurentTasks:[self stateToTypeIDX:[limit unsignedIntegerValue]]];

		NSInteger available = MIN(cCount, MAX(0, maxTasks - _inProcess));

		if (!available)
			return;

		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		NSTimeInterval interval = self.consecutiveIterationsInterval;
		NSIndexSet *notDelayed = [candidates indexesOfObjectsPassingTest:^BOOL(AZDownload *download, NSUInteger idx, BOOL *stop) {
			NSTimeInterval delay = interval * MIN(6, download.httpError);
			return download.lastDownloadIteration < now - delay;
		}];

		if (![notDelayed count])
			return;

		candidates = [candidates objectsAtIndexes:notDelayed];

		candidates = [candidates sortedArrayUsingSelector:@selector(compare:)];

		AZ_Mutable(Dictionary, *limits);
		AZ_Mutable(Dictionary, *selected);

		for (AZDownload *download in candidates) {
			AZErgoDownloadState state = [self nextToAquire:download.state];

			NSInteger left = 0;

			if (!limits[@(state)]) {
				NSUInteger inProcess = [typesInProcess[@(state)] ?: @0 unsignedIntegerValue];
				left = [self concurentTasks:[self stateToTypeIDX:state]] - inProcess;
				limits[@(state)] = @(left);
			} else
				left = [limits[@(state)] integerValue];

			if (left > 0) {
				NSMutableArray *array = selected[@(state)] ?: (selected[@(state)] = [NSMutableArray new]);
				[array addObject:download];
				limits[@(state)] = @(--left);
				available--;
			}

			if (available <= 0)
				break;
		}

		BOOL fullResolve = PREF_BOOL(PREFS_DOWNLOAD_FULL_RESOLVE);
		NSArray *sortedStates = fullResolve
		/**/? [[selected allKeys] sortedArrayUsingSelector:@selector(compare:)]
		/**/: [selected allKeys];

		for (NSNumber *state in sortedStates) {
			NSArray *batch = selected[state];
			for (AZDownload *download in batch)
				[self detouchTask:download];

			if (fullResolve)
				break;
		}

	}
}

- (void) detouchTask:(AZDownload *)download {
	@synchronized(self.downloads) {
		if ([download isDeleted])
			return;

		download.state |= AZErgoDownloadStateProcessing;
	}

	dispatch_queue_t queue = dispatch_queue_create("org.ankhzet.download-task-worker", DISPATCH_QUEUE_SERIAL);
	dispatch_async(queue, ^{
		@try {
			download.lastDownloadIteration = [NSDate timeIntervalSinceReferenceDate];

#define __smart_task(__state, __selector)\
({[self download:download block:^(AZErgoCustomDownloader *downloader, AZDownload *download) {\
[AZ_API(ErgoProxifier) __selector:download];\
} stateWrap:(__state)];\
})

			if (!HAS_BIT(download.state, AZErgoDownloadStateResolved))
				__smart_task(AZErgoDownloadStateResolving, resolveStorage);
			else
				if (!HAS_BIT(download.state, AZErgoDownloadStateAquired))
					__smart_task(AZErgoDownloadStateAquiring, aquireScanData);
				else
					__smart_task(AZErgoDownloadStateDownloading, downloadScan);
		}
		@finally {
			@synchronized(self.downloads) {
				UNSET_BIT(download.state, AZErgoDownloadStateProcessing);
			}
		}
	});
}

typedef void(^AZErgoSmartTaskBlock)(AZErgoCustomDownloader *downloader, AZDownload *download);

- (void) download:(AZDownload *)download block:(AZErgoSmartTaskBlock)block stateWrap:(AZErgoDownloadState)state {
	download.state |= state;
	@try {
    block(self, download);
	}
	@finally {
		UNSET_BIT(download.state, state);
		[self notifyStageChange:download];
	}
}

- (void) notifyStageChange:(AZDownload *)download {
	[self.md_delegate downloader:self readyForNextStage:download];
}

@end
