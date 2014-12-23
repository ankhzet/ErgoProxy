//
//  AZErgoDownloadsDataSource.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZErgoGroupCellView.h"
#import "AZErgoDownloadCellView.h"

typedef struct {NSUInteger total, downloaded;} AZErgoDownloadedAmount;

@class AZDownload;
@protocol AZErgoDownloadsDataSourceDelegate <NSObject>

- (void) showDownload:(AZDownload *)download detailsFromSender:(id)sender;

@end

@interface AZErgoDownloadsDataSource : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic) NSArray *data;
@property (nonatomic) BOOL groupped;

@property (nonatomic) IBOutlet id<AZErgoDownloadsDataSourceDelegate> delegate;


- (AZErgoDownloadedAmount) downloaded:(id)node;
- (void) expandUnfinishedInOutlineView:(NSOutlineView *)outlineView;

@end
