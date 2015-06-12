//
//  AZErgoReader.h
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AZErgoReaderDelegateProtocol <NSObject>

- (NSView *) superview;

- (BOOL) isKey;
- (void) contentCached:(id)uid;
- (void) willRecache;

- (void) contentShow:(id)uid;

- (void) noContents:(float)chapter navigatedBackward:(BOOL)navigatedBackward;

@end


@class AZErgoReaderContentProvider;
@interface AZErgoReader : NSObject

@property (nonatomic, readonly) NSView *contentView;
@property (nonatomic) AZErgoReaderContentProvider *contentProvider;
@property (nonatomic) NSInteger currentContentIndex;

@property (nonatomic)	id <AZErgoReaderDelegateProtocol> delegate;

+ (instancetype) readerWithContentProvider:(AZErgoReaderContentProvider *)contentProvider;

- (NSString *) readedTitle;

- (void) attachToView:(NSView *)superview;

- (void) unsetKeyMonitor;
- (void) configureKeyMonitor;

- (void) buildViewTree:(NSArray *)content;

- (NSImageView *) holderOfContent:(id)uid;
- (NSImageView *) holderOfContentWithIDX:(NSUInteger)index;

- (void) show;
- (void) notifyEnd:(BOOL)backward;

- (void) loadContents:(BOOL)flushCaches;
- (void) cacheContents;
- (void) flushCaches;

- (void) showContents:(BOOL)flushCaches;
- (void) showContent:(NSInteger)index;

- (int) scanCount;

- (void) updateScanView:(id)uid;
- (void) scanCached:(id)uid;

- (CGSize) contentSize;

@end
