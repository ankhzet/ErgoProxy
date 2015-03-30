//
//  AZErgoUpdateWatch.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesCommons.h"

@class AZErgoUpdateWatch;
@protocol AZErgoUpdateWatchDelegate <NSObject>

- (void) watch:(AZErgoUpdateWatch *)watch stateChanged:(BOOL)checking;

@end

@class AZErgoUpdatesSourceDescription, AZErgoUpdateChapter;
@interface AZErgoUpdateWatch : AZCoreDataEntity

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *manga;
@property (nonatomic, retain) NSString *genData;
@property (nonatomic, retain) NSSet *updates;

@property (nonatomic, retain) AZErgoUpdatesSourceDescription *source;

@property (nonatomic) BOOL checking;
@property (nonatomic, weak) id<AZErgoUpdateWatchDelegate> delegate;

- (AZErgoUpdateChapterDownloads) chapterState:(AZErgoUpdateChapter *)chapter;
- (void) clearChapterState:(AZErgoUpdateChapter *)chapter;

- (BOOL) requiresCheck;

- (AZErgoUpdateChapter *) chapterByIDX:(float)chapter;
- (AZErgoUpdateChapter *) lastChapter;
- (AZErgoUpdateChapter *) firstChapter;

+ (AZErgoUpdateWatch *) watchByManga:(NSString *)manga;

@end
