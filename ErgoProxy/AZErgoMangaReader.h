//
//  AZErgoMangaReader.h
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoReader.h"

@class AZErgoManga, AZScanCleanFilter;
@interface AZErgoMangaReader : AZErgoReader

@property (nonatomic) BOOL mipmapImages;
@property (nonatomic) AZScanCleanFilter *scanCleanFilter;

+ (instancetype) readerForManga:(AZErgoManga *)manga andChapter:(float)chapter;

- (void) scanCached:(id)uid;
- (void) updateScanView:(id)uid;

@end
