//
//  AZErgoProxifierAPI.m
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoProxifierAPI.h"
#import "AZErgoAPIRequest.h"
#import "AZDownload.h"
#import "AZProxifier.h"

@implementation AZErgoProxifierAPI

- (id) action:(NSString *)actionName {
	return [AZErgoAPIRequest actionWithName:actionName];
}

- (AZHTTPRequest *) proxifyDownload:(AZDownload *)download withCompletion:(p_block)block {
	AZErgoAPIRequest *proxifyRequest = [self action:@"aquire"];

	proxifyRequest.serverURL = download.proxifier.url;

	[proxifyRequest setParameters:[download fetchParams]];

	[[proxifyRequest success:^(AZHTTPRequest *request, id *data) {
		block(YES, *data, download);
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		block(NO, response, download);
		return YES;
	}];

	return [self queue:proxifyRequest withType:AZAPIRequestTypeDefault];
}

@end
