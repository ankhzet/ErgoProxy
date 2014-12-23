//
//  AZErgoAPIRequest.m
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoAPIRequest.h"
//#import "AZDownloadParams.h"

@implementation AZErgoAPIRequest

- (void) setServerURL:(NSURL *)serverURL {
	if (_serverURL == serverURL)
		return;

	_serverURL = serverURL;
	self.referrer = [NSString stringWithFormat:@"%@://%@", [serverURL scheme], [serverURL host]];
}

- (NSString *) url {
	NSString *server = [self.serverURL absoluteString];

	if ([server hasSuffix:@"/"])
		server = [server substringToIndex:[server length]-1];

	NSString *url = [NSString stringWithFormat:[super url], server];
	return url;
}

/*- (void) setParameters:(NSDictionary *)parameters {
 if (parameters[kDownloadParamServer]) {
 self.serverURL = parameters[kDownloadParamServer];
 parameters = [parameters mutableCopy];
 [(NSMutableDictionary *)parameters removeObjectForKey:kDownloadParamServer];
 }
 [super setParameters:parameters];
 }*/

@end
