//
//  AZErgoUpdateWatch.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesCommons.h"

@class AZErgoUpdateWatch, AZErgoManga;
@protocol AZErgoUpdateWatchDelegate <NSObject>

- (void) watch:(AZErgoUpdateWatch *)watch stateChanged:(BOOL)checking;

@end

@interface AZErgoUpdateWatch : AZCoreDataEntity

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *manga;
@property (nonatomic, retain) NSString *genData;
@property (nonatomic, retain) NSSet *updates;

@property (nonatomic, retain) AZErgoUpdatesSourceDescription *source;

@property (nonatomic) BOOL checking;

- (AZErgoUpdateChapterDownloads) chapterState:(AZErgoUpdateChapter *)chapter;
- (void) clearChapterState:(AZErgoUpdateChapter *)chapter;
- (void) clearChaptersState;

- (BOOL) requiresCheck;

- (AZErgoUpdateChapter *) chapterByIDX:(float)chapter;
- (AZErgoUpdateChapter *) lastChapter;
- (AZErgoUpdateChapter *) firstChapter;
- (AZErgoUpdateChapter *) chapterBefore:(AZErgoUpdateChapter *)next;
- (AZErgoUpdateChapter *) chapterAfter:(AZErgoUpdateChapter *)next;

- (AZErgoManga *) relatedManga;

+ (AZErgoUpdateWatch *) watchByManga:(NSString *)manga;

- (NSString *) mangaURL;

@end
