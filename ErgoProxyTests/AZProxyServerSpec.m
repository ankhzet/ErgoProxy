//
//  AZProxyServerSpec.m
//  ErgoProxy
//  Spec for AZProxyServer
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZProxyServer.h"
#import "AZDownloadParams.h"
#import "AZDownloader.h"
#import "AZDownload.h"

SPEC_BEGIN(AZProxyServerSpec)

describe(@"AZProxyServer", ^{
	it(@"should properly initialize", ^{
		AZProxyServer *instance = [AZProxyServer new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZProxyServer class]];
	});

//	it(@"should return downloader", ^{
//		NSURL *url = [NSURL URLWithString:@"http://server.domen/uri.extension"];
//
//		AZDownloadParams *params = [AZDownloadParams new];
//
//		AZProxyServer *server = [AZProxyServer new];
//
//		AZDownloader *downloader = [server downloaderForURL:url withParams:params];
//		[[downloader shouldNot] beNil];
//	});
});

SPEC_END
