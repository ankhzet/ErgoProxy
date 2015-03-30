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
	AZProxyServer *server = [self insertNew];
	server.url = url;
	return server;
}



@end
