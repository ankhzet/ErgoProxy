//
//  AZDownloader.m
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZDownloader.h"
#import "AZDownload.h"

@interface AZDownloader () {
	NSMutableDictionary *_downloads;
}

@end

@implementation AZDownloader
@synthesize downloads = _downloads;

- (id)init {
	if (!(self = [super init]))
		return self;

	_concurentTasks = PREF_INT(PREFS_DOWNLOAD_PER_STORAGE);
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
	_concurentTasks = PREF_INT(PREFS_DOWNLOAD_PER_STORAGE);
}

- (AZDownload *) addDownload:(AZDownload *)download {
	@synchronized(_downloads) {
		if (!_downloads)
			_downloads = [NSMutableDictionary dictionary];

		AZDownload *old = _downloads[download.sourceURL];
		_downloads[download.sourceURL] = download;

		download.storage = self.storage;
		return old;
	}
}

- (void) removeDownload:(AZDownload *)download {
	@synchronized(_downloads) {
		[_downloads removeObjectForKey:download.sourceURL];
	}
}

- (AZDownload *) hasDownloadForURL:(NSURL *)url {
	@synchronized(_downloads) {
		return _downloads[url];
	}
}

+ (instancetype) downloaderForStorage:(AZStorage *)storage {
	AZDownloader *downloader = [AZDownloader new];
	downloader.storage = storage;
	return downloader;
}

@end

@implementation AZDownloader (Downloading)

- (void) pause {
	_paused = YES;
}

- (void) resume {
	_paused = NO;
}

- (void) stop {
	_running = NO;
	_paused = NO;
}

- (void) processDownloads {
	@synchronized(self) {
		if (_running)
			return;

		_running = YES;
		_paused = YES;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
			_paused = NO;
			@try {
				while (_running) {
					usleep(10000);

					if (_paused)
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

- (void) pickDownload {
	NSUInteger inProcess = 0;

	NSMutableArray *candidates = [NSMutableArray array];

	@synchronized(_downloads) {
		for (AZDownload *download in [_downloads allValues]) {
			BOOL processing = HAS_BIT(download.state, AZErgoDownloadStateProcessing);

			if (processing)
				inProcess++;
			else
				if (!HAS_BIT(download.state, AZErgoDownloadStateDownloaded))
					[candidates addObject:download];
		}
	}

	_inProcess = inProcess;

	NSUInteger available = MIN([candidates count], MAX(0, (int)self.concurentTasks - (int)inProcess));

	if (!available)
		return;

	if ([candidates count]) {
		NSMutableArray *candidates2 = [NSMutableArray array];

		NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
		for (AZDownload *download in candidates) {
			NSTimeInterval delay = self.consecutiveIterationsInterval * MIN(6, download.httpError);
			if (download.lastDownloadIteration < now - delay)
				[candidates2 addObject:download];
		}

		if ([candidates2 count]) {
			candidates = (id) ([candidates2 count] <= available
												 ? candidates2
												 : [candidates2 sortedArrayUsingComparator:^NSComparisonResult(AZDownload *d1, AZDownload *d2) {

				NSComparisonResult r = [d1.manga compare:d2.manga];
				if (r == NSOrderedSame)
					return [@([d1 indexHash]) compare:@([d2 indexHash])];
				else
					return r;
			}]);

//			candidates = (id) ([candidates count] <= available
//												 ? candidates
//												 : [candidates sortedArrayUsingComparator:^NSComparisonResult(AZDownload *d1, AZDownload *d2) {
//
//				return [@(d1.state) compare:@(d2.state)];
//			}]);

			for (AZDownload *download in candidates)
				if (inProcess++ >= self.concurentTasks)
					break;
				else
					[self detouchTask:download];
		}
	}
}

@end
