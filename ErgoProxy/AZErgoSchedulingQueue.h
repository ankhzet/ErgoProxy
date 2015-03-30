//
//  AZErgoSchedulingQueue.h
//  ErgoProxy
//
//  Created by Ankh on 19.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AZScheduledTaskProcessBlock)(BOOL *requeue, id associatedObject);

@class AZErgoSchedulingQueueTask;

@interface AZErgoSchedulingQueue : NSOperationQueue

- (void) enqueue:(AZScheduledTaskProcessBlock)process withAssociatedObject:(id)associated;

@end

@interface AZErgoWaitBreakTask : NSObject
@property() BOOL isRunning;

typedef void(^AZErgoWaitBreakTaskProcessor)(AZErgoWaitBreakTask *task);
+ (AZErgoWaitBreakTask *) executeTask:(AZErgoWaitBreakTaskProcessor)block;
- (void) execute;
- (void) break;
@end

