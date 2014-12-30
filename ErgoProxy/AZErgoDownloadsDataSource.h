//
//  AZErgoDownloadsDataSource.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZGroupableDataSource.h"

typedef struct {NSUInteger total, downloaded;} AZErgoDownloadedAmount;

@class AZDownload;
@protocol AZErgoDownloadsDataSourceDelegate <NSObject>

- (void) showDownload:(AZDownload *)download detailsFromSender:(id)sender;

@end

@class AZErgoUpdateWatch, AZErgoUpdateChapter;
@interface AZErgoDownloadsDataSource : AZGroupableDataSource

@property (nonatomic) IBOutlet id<AZErgoDownloadsDataSourceDelegate> delegate;


- (AZErgoDownloadedAmount) downloaded:(id)node;
- (void) expandUnfinishedInOutlineView:(NSOutlineView *)outlineView;

@end
