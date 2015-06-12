//
//  AZRequeuableTaskOperationQueue.m
//  ErgoProxy
//
//  Created by Ankh on 07.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZRequeuableTaskOperationQueue.h"

@interface AZQueuedTask : NSOperation {
@public
	id associatedObject;
	AZQueuedTaskProcessBlock process;
	__weak AZRequeuableTaskOperationQueue *queue;
}

+ (instancetype) queueTask:(AZQueuedTaskProcessBlock)process withAssociatedObject:(id)associated;

@end

@implementation AZQueuedTask

+ (instancetype) queueTask:(AZQueuedTaskProcessBlock)process withAssociatedObject:(id)associated {
	AZQueuedTask *task = [self new];
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

@implementation AZRequeuableTaskOperationQueue

+ (instancetype) new {
	AZRequeuableTaskOperationQueue *queue = [super new];
	[queue setMaxConcurrentOperationCount:1];

	return queue;
}

- (void) enqueue:(AZQueuedTaskProcessBlock)process withAssociatedObject:(id)associated {
	AZQueuedTask *task = [AZQueuedTask queueTask:process withAssociatedObject:associated];
	task->queue = self;
	[self addOperation:task];
}


@end
