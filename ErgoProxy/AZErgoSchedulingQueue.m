//
//  AZErgoSchedulingQueue.m
//  ErgoProxy
//
//  Created by Ankh on 19.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoSchedulingQueue.h"

@interface AZErgoSchedulingQueueTask : NSOperation {
@public
	id associatedObject;
	AZScheduledTaskProcessBlock process;
	__weak AZErgoSchedulingQueue *queue;
}

+ (instancetype) task:(AZScheduledTaskProcessBlock)process withAssociatedObject:(id)associated;

@end

@implementation AZErgoSchedulingQueueTask

+ (instancetype) task:(AZScheduledTaskProcessBlock)process withAssociatedObject:(id)associated {
	AZErgoSchedulingQueueTask *task = [self new];
	task->process = process;
	task->associatedObject = associated;
	return task;
}

- (NSString *) description {
	return [associatedObject description];
}

- (void) main {
	BOOL requeue = NO;
	process(&requeue, associatedObject);
	if (requeue)
		[queue enqueue:process withAssociatedObject:associatedObject];
}

@end

@implementation AZErgoSchedulingQueue

+ (instancetype) new {
	AZErgoSchedulingQueue *queue = [super new];
	[queue setMaxConcurrentOperationCount:1];

	return queue;
}

- (void) enqueue:(AZScheduledTaskProcessBlock)process withAssociatedObject:(id)associated {
	AZErgoSchedulingQueueTask *task = [AZErgoSchedulingQueueTask task:process withAssociatedObject:associated];
	task->queue = self;
	[self addOperation:task];
}

@end

@implementation AZErgoWaitBreakTask {
	dispatch_semaphore_t sem;
	AZErgoWaitBreakTaskProcessor block;
}

+ (AZErgoWaitBreakTask *) executeTask:(AZErgoWaitBreakTaskProcessor)block {
	AZErgoWaitBreakTask *task = [self new];
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

			double delayInSeconds = 0.2;
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
