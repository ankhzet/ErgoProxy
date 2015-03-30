//
//  AZErgoCustomDownloader.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AZErgoDownloaderState) {
	AZErgoDownloaderStateIddle = 0,
	AZErgoDownloaderStateWorking = 1,
};

@class AZDownload, AZErgoCustomDownloader, AZStorage;

@protocol AZErgoDownloaderDelegate <NSObject>

- (void) downloader:(AZErgoCustomDownloader *)downloader stateSchanged:(AZErgoDownloaderState)state;
- (void) downloader:(AZErgoCustomDownloader *)downloader readyForNextStage:(AZDownload *)download;

@end

@interface AZErgoCustomDownloader : NSObject

@property (nonatomic, weak) AZStorage *storage;
@property (nonatomic) NSDictionary *downloads;

- (AZDownload *) addDownload:(AZDownload *)download;
- (AZDownload *) hasDownloadForURL:(NSString *)url;
- (void) removeDownload:(AZDownload *)download;

@end
