//
//  AZWaitableTask.m
//  ErgoProxy
//
//  Created by Ankh on 07.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZWaitableTask.h"

@implementation AZWaitableTask {
	dispatch_semaphore_t sem;
	AZWaitableTaskProcessor block;
}

+ (instancetype) executeTask:(AZWaitableTaskProcessor)block {
	AZWaitableTask *task = [self new];
	task->block = block;
	[task execute];
	return task;
}

- (void) execute {
	self.isRunning = YES;
	@try {
		dispatch_sync_at_background(^{
			sem = dispatch_semaphore_create(0);
			block(self);

			double delayInSeconds = 0.05;
			while (self.isRunning)
				if (!dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC))))
					break;
		});
	}
	@finally {
		self.isRunning = NO;
	}
}

- (void) break {
	dispatch_semaphore_signal(sem);
}

@end
