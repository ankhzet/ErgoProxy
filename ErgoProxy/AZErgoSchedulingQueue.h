//
//  AZErgoSchedulingQueue.h
//  ErgoProxy
//
//  Created by Ankh on 19.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZRequeuableTaskOperationQueue.h"

@class AZErgoUpdateChapter, AZErgoUpdateWatch;
@interface AZErgoSchedulingQueue : AZRequeuableTaskOperationQueue

@property (nonatomic) BOOL hasNewChapters;

+ (instancetype) sharedQueue;

- (void) queueChapterDownloadTask:(AZErgoUpdateChapter *)chapter;
- (void) checkWatch:(AZErgoUpdateWatch *)watch;

@end
