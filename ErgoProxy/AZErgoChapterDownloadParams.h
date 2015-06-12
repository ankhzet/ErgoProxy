//
//  AZErgoChapterDownloadParams.h
//  ErgoProxy
//
//  Created by Ankh on 20.05.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AZErgoUpdateChapter, AZErgoManga, AZDownload, AZDownloadParams, AZProxifier;

@interface AZErgoChapterDownloadParams : NSObject

@property (nonatomic) AZErgoManga *manga;
@property (nonatomic) float chapterID;
@property (nonatomic) NSArray *scans;
@property (nonatomic) AZDownloadParams *scanDownloadParams;

- (void) registerDownloads:(AZProxifier *)proxifier;

@end
