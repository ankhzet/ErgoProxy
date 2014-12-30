//
//  AZErgoWatcherScheduler.m
//  ErgoProxy
//
//  Created by Ankh on 29.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoWatcherScheduler.h"

@implementation AZErgoWatcherScheduler {
	NSTimer *watchTimer;
	AZErgoWatcherSchedulerExecutionBlock block;
}
@synthesize timeInterval = _timeInterval;

+ (instancetype) schedulerWithBlock:(AZErgoWatcherSchedulerExecutionBlock)block {
	AZErgoWatcherScheduler *scheduler = [self new];
	scheduler->block = block;
	return scheduler;
}

- (void) invalidate {
	[watchTimer invalidate];
	watchTimer = nil;
}

- (void) revalidate {
	NSTimeInterval interval = PREF_INT(PREFS_WATCHER_AUTOCHECK_INTERVAL);
	NSTimeInterval delay = 0;
	if (watchTimer) {
		NSTimeInterval
		oldInterval = [watchTimer timeInterval],
		left = MAX(0, [[watchTimer fireDate] timeIntervalSinceNow]),
		last = oldInterval - left;

//		NSLog(@"Revalidate%@", ((interval - last) < 1) ? @", fired" : @"");

// if there left some time to next tick with new interval - delay
		if ((interval - last) >= 1)
			delay = MAX(0, interval - last);
		else {
			[watchTimer fire];
			[self invalidate];

			delay = 0;
		}

	}

	if (!interval) {
		[self invalidate];
		return;
	}

	if (delay > 1) {
//		NSLog(@"Delayed: %lf", delay);
// already fired previously n seconds ago, so after (newInterval - secondsAgo) try to revalidate timer
		^void(NSTimer *timer) {
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)((delay - 1) * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^{
				if (watchTimer != timer)
					return;

//				NSLog(@"Revalidating...");
				[self revalidate];
			});
		}(watchTimer);
	}

//	NSLog(@"Resetting timer...");
	[self invalidate];

	watchTimer = [NSTimer timerWithTimeInterval:interval
																			 target:self
																		 selector:@selector(watchTick:)
																		 userInfo:nil
																			repeats:YES];

	[[NSRunLoop mainRunLoop] addTimer:watchTimer forMode:NSDefaultRunLoopMode];
}

- (void) watchTick:(NSTimer *)timer {
	if (timer != watchTimer) {
		[timer invalidate];
		return;
	}

	BOOL stop = NO;
	block(self, &stop);
	if (stop)
		[self invalidate];
}

- (void) setTimeInterval:(NSTimeInterval)timeInterval {
	if (ABS(_timeInterval - timeInterval) < 0.01)
		return;

	_timeInterval = timeInterval;
	[self revalidate];
}

@end
