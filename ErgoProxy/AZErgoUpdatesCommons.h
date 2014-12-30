//
//  AZErgoUpdatesCommons.h
//  ErgoProxy
//
//  Created by Ankh on 28.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

typedef NS_ENUM(NSUInteger, AZErgoUpdateChapterDownloads) {
	AZErgoUpdateChapterDownloadsUnknown    = 0,
	AZErgoUpdateChapterDownloadsNone       = 1,
	AZErgoUpdateChapterDownloadsPartial    = 2,
	AZErgoUpdateChapterDownloadsDownloaded = 3,
	AZErgoUpdateChapterDownloadsFailed     = 4,
};


#ifndef ErgoProxy_AZErgoUpdatesCommons_h
#define ErgoProxy_AZErgoUpdatesCommons_h

@class AZErgoUpdateChapter, AZErgoUpdateWatch, AZErgoUpdatesSource, AZErgoUpdatesSourceDescription;

#import "AZCoreDataEntity.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdateChapter.h"
#import "AZErgoUpdatesSource.h"
#import "AZErgoUpdatesSourceDescription.h"


#endif
