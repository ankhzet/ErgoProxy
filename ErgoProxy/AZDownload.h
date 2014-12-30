//
//  AZDownload.h
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZCoreDataEntity.h"

typedef NS_ENUM(NSUInteger, AZErgoDownloadState) {
	AZErgoDownloadStateNone        = 0 << 0, // newly created download
	AZErgoDownloadStateProcessing  = 1 << 1, // task in process
	AZErgoDownloadStateResolving   = 1 << 2, // resolving storage information (provided by proxy)
	AZErgoDownloadStateResolved    = 1 << 3, // storage info resolved (storage url and download parameters)
	AZErgoDownloadStateAquiring    = 1 << 4, // aquiring information from storage (stored url, filetype, size in bytes)
	AZErgoDownloadStateAquired     = 1 << 5, // data aquired (stored url and filesize now are known)
	AZErgoDownloadStateDownloading = 1 << 6, // downloading file from storage
	AZErgoDownloadStateDownloaded  = 1 << 7, // file downloaded (nnn of nnn real bytes downloaded)
	AZErgoDownloadStateFailed      = 1 << 8, // any of '___ing' states was failed (for ex., if Resolved and Aquired states are present, than 'Downloading' stage was failed)
};

@class AZDownload;
@protocol AZErgoDownloadStateListener <NSObject>

- (void) download:(AZDownload *)download stateChanged:(AZErgoDownloadState)state;
- (void) download:(AZDownload *)download progressChanged:(double)progress;

@end

@class AZDownloadParams, AZProxifier, AZStorage;
@interface AZDownload : AZCoreDataEntity

@property (nonatomic, retain) NSURL *sourceURL;

@property (nonatomic) NSString *manga;
@property (nonatomic) float chapter;
@property (nonatomic) NSInteger page;

@property (nonatomic) AZErgoDownloadState state;
@property (nonatomic) NSString *fileURL;
@property (nonatomic) NSUInteger totalSize;
@property (nonatomic) NSUInteger downloaded;
@property (nonatomic) BOOL supportsPartialDownload;
@property (nonatomic) NSTimeInterval lastDownloadIteration;

@property (nonatomic) NSUInteger httpError;

@property (nonatomic, retain) AZDownloadParams *downloadParameters;

@property (nonatomic, retain) AZProxifier *proxifier;
@property (nonatomic, retain) AZStorage *storage;

@property (nonatomic, retain) NSString *proxifierHash;
@property (nonatomic) NSUInteger scanID;

@property (nonatomic) id error;

@property (nonatomic, weak) id<AZErgoDownloadStateListener> stateListener;

- (BOOL) isBonusChapter;
- (NSUInteger) indexHash;

+ (NSArray *) fetchDownloads;
+ (NSArray *) manga:(NSString *)manga hasChapterDownloads:(float)chapter;

- (void) downloadError:(id)error;

- (void) setDownloadedAmount:(NSUInteger)_downloaded;

@end


@interface AZDownload (Instantiation)

+ (AZDownload *) downloadForURL:(NSURL *)url withParams:(AZDownloadParams *)params;

@end


@interface AZDownload (FileDownloadRelated)

- (NSString *) fileFullURL;

- (double) percentProgress;
- (NSString *) localFilePath;
- (NSUInteger) localFileSize;
- (NSOutputStream *) fileStream:(BOOL)seekToEnd;

- (void) notifyProgressChanged;

@end


@interface AZDownload (Proxifying)

- (NSDictionary *) fetchParams;

+ (NSURL *) storageToken:(id)jsonProxifierResponse;
+ (NSString *) hashToken:(id)jsonProxifierResponse;
+ (NSUInteger) scanToken:(id)jsonProxifierResponse;

@end


@interface AZDownload (Validity)

- (BOOL) isFileCorrupt;

@end