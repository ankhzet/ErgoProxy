//
//  AZProxyServer.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZProxyServer.h"
#import "AZErgoDownloader.h"


@implementation AZProxyServer
@dynamic url;

+ (instancetype) serverWithURL:(NSString *)url {
	return [self unique:AZF_ALL_OF(@"url == %@", url) initWith:^(AZProxyServer *server) {
		server.url = url;
	}];
}



@end
