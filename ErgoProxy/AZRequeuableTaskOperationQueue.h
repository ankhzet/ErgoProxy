//
//  AZRequeuableTaskOperationQueue.h
//  ErgoProxy
//
//  Created by Ankh on 07.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^AZQueuedTaskProcessBlock)(BOOL *requeue, id associatedObject);

@interface AZRequeuableTaskOperationQueue : NSOperationQueue

- (void) enqueue:(AZQueuedTaskProcessBlock)process withAssociatedObject:(id)associated;

@end
