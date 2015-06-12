//
//  AZErgoDownloadsDataSource.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZGroupableDataSource.h"

typedef struct {NSUInteger total, downloaded;} AZErgoDownloadedAmount;

@class AZDownload;

@class AZErgoUpdateWatch, AZErgoUpdateChapter;
@interface AZErgoDownloadsDataSource : AZGroupableDataSource

- (AZErgoDownloadedAmount) downloaded:(id)node;
- (BOOL) unfinished:(id)node;

- (void) expandUnfinishedInOutlineView:(NSOutlineView *)outlineView;

@end

@interface AZErgoDownloadsDataSource (DataFormatting)

+ (AZErgoUpdateWatch *) relatedManga:(id)node;
+ (AZErgoUpdateChapter *) relatedChapter:(id)node;
+ (NSString *) formattedChapterIDX:(float)chapter prefix:(BOOL)prefix;
+ (NSString *) formattedChapterIDX:(float)chapter;
+ (NSString *) formattedChapterPageIDX:(NSUInteger)page prefix:(BOOL)prefix;
+ (NSString *) formattedChapterPageIDX:(NSUInteger)page;

@end
