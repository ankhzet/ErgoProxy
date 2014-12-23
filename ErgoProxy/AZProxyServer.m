//
//  AZProxyServer.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZProxyServer.h"
#import "AZDownloader.h"


@implementation AZProxyServer
//@dynamic url;

+ (instancetype) serverWithURL:(NSURL *)url {
	AZProxyServer *server = [self new];
	server.url = url;
	return server;
}



@end
