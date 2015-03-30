//
//  AZErgoReaderContentProvider.h
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AZErgoManga;
@interface AZErgoReaderContentProvider : NSObject

@property (readonly) AZErgoManga *manga;

@property (readonly) NSArray *content;
@property (readonly) BOOL hasContent;

@property (readonly) BOOL navigatedBackward;

@property float chapterID;

- (id)initWithManga:(AZErgoManga *)manga;

@end

@interface AZErgoReaderContentProvider (Commons)

- (void) flushCache;

- (NSString *) contentPath;
- (NSString *) contentID:(NSInteger)index;
- (NSUInteger) contentIDX:(id)uid;
- (id) contentOf:(id)uid;
- (id) contentOf:(id)uid withProcession:(id(^)(id uid, id content))process andCompletion:(void(^)(id uid))complete;

- (NSInteger) constraintIndex:(NSInteger)index;
- (void) viewingContentAtIndex:(NSInteger)index;

- (BOOL) seekNext:(BOOL)backward;

@end

