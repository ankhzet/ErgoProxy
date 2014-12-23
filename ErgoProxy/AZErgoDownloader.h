//
//  AZErgoDownloader.h
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AZErgoDownloaderState) {
	AZErgoDownloaderStateIddle = 0,
};

@class AZDownload, AZErgoDownloader;

@protocol AZErgoDownloaderDelegate <NSObject>

- (void) downloader:(AZErgoDownloader *)downloader stateSchanged:(AZErgoDownloaderState)state;
- (void) downloader:(AZErgoDownloader *)downloader readyForNextStage:(AZDownload *)download;

@end

@interface AZErgoDownloader : NSObject

@property (nonatomic, weak) id<AZErgoDownloaderDelegate> delegate;

- (void) detouchTask:(AZDownload *)download;

@end
