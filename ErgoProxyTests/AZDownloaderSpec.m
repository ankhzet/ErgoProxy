//
//  AZDownloaderSpec.m
//  ErgoProxy
//  Spec for AZDownloader
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZDownloader.h"
#import "AZDownload.h"
#import "AZDownloadParams.h"
#import "AZStorage.h"

SPEC_BEGIN(AZDownloaderSpec)

describe(@"AZDownloader", ^{
	it(@"should properly initialize", ^{
		AZDownloader *instance = [AZDownloader new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZDownloader class]];
	});

	it(@"should produce download for url", ^{
//		NSURL *url = [NSURL URLWithString:@"http://server.domen/uri.ext"];
//		AZDownloadParams *params = [AZDownloadParams new];


		id storage = [NSObject new];
		AZDownloader *downloader = [AZDownloader downloaderForStorage:storage];
		[[downloader.storage should] equal:storage];

//		AZDownload *download = [downloader downloadForURL:url withParams:params];
//
//		[[download shouldNot] beNil];
//
//		[[download.sourceURL should] equal:url];
//		[[download.downloadParams should] equal:params];
	});
});

SPEC_END
