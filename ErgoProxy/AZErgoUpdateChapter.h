//
//  AZErgoUpdateChapter.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesCommons.h"
#import "AZErgoChapterProtocol.h"

@class AZErgoUpdateChapter, AZErgoManga, AZDownload, AZDownloadParams;
@protocol AZErgoUpdateChapterProtocol <NSObject>

- (void) update:(AZErgoUpdateChapter *)update stateChanged:(AZErgoUpdateChapterDownloads)state;

@end

@interface AZErgoUpdateChapter : AZCoreDataEntity <AZErgoChapterProtocol>

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *genData;
@property (nonatomic) NSInteger volume;
@property (nonatomic) float idx;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSSet *downloads;

@property (nonatomic) NSString *mangaName;

@property (nonatomic, retain) AZErgoUpdateWatch *watch;

@property (nonatomic) AZErgoUpdateChapterDownloads state;

- (BOOL) isDummy;

+ (instancetype) updateChapterForManga:(AZErgoManga *)manga chapter:(float)chapterID;

@property (nonatomic) float persistentIdx;
@property (nonatomic) AZErgoUpdateChapterDownloads persistentState;


@end

@interface AZErgoUpdateChapter (Formatting)

- (NSString *) formattedString;
- (NSString *) fullTitle;

@end

@interface AZErgoUpdateChapter (CoreDataAccessors)

- (void)addDownloadsObject:(AZDownload *)value;
- (void)removeDownloadsObject:(AZDownload *)value;

@end