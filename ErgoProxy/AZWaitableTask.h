//
//  AZWaitableTask.h
//  ErgoProxy
//
//  Created by Ankh on 07.06.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AZWaitableTask;

typedef void(^AZWaitableTaskProcessor)(AZWaitableTask *task);

@interface AZWaitableTask : NSObject

@property() BOOL isRunning;

+ (instancetype) executeTask:(AZWaitableTaskProcessor)block;
- (void) execute;
- (void) break;

@end
