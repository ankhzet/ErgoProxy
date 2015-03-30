//
//  AZErgoAPI.m
//  ErgoProxy
//
//  Created by Ankh on 12.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoAPI.h"
#import "AZErgoAPIRequest.h"

@implementation AZErgoAPI

- (id) action:(NSString *)actionName atIP:(NSString *)ip {
	AZErgoAPIRequest *action = [AZErgoAPIRequest actionWithName:actionName];
	action.showErrors = NO;

	action.url = [NSString stringWithFormat:@"%%@/%@", actionName];

	NSString *port = @":2012";
	NSRange portR = [ip rangeOfString:@":"];
	if (portR.length > 0) {
		port = [ip substringFromIndex:portR.location];
		ip = [ip substringToIndex:portR.location];
	}

	action.serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", ip, port]];
	return action;
}

- (AZHTTPRequest *) aquireMangaDataFromIP:(NSString *)ip withCompletion:(p_block)completionBlock {
	AZJSONRequest *request = [self action:@"manga/info" atIP:ip];

	[[request success:^(AZHTTPRequest *request, id *data) {
		completionBlock(YES, *data);
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		completionBlock(NO, response);
		return YES;
	} firstly:YES];

	return [self queue:request withType:AZAPIRequestTypeDefault];
}

@end
