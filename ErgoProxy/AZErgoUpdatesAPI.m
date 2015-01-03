//
//  AZErgoUpdatesAPI.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesAPI.h"
#import "AZHTMLRequest.h"
#import "AZErgoUpdatesSource.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdateChapter.h"

@implementation AZErgoUpdatesAPI

- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source watch:(AZErgoUpdateWatch *)watch chaptersWithCompletion:(p_block)block {
	AZHTMLRequest *request = [source chaptersAction:watch];

	[[request success:^(AZHTTPRequest *request, TFHpple **document) {
		block(YES, [source chaptersFromDocument:*document]);
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		block(NO, nil);
		action.showErrors = NO;
		return YES;
	} firstly:YES];

	return [self queue:request withType:AZAPIRequestTypeDefault];
}

- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source chapter:(AZErgoUpdateChapter *)chapter scansWithCompletion:(p_block)block {
	AZHTMLRequest *request = [source scansAction:chapter];

	[[request success:^(AZHTTPRequest *request, TFHpple **document) {
		block(YES, [source scansFromDocument:*document]);
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		block(NO, nil);
		action.showErrors = NO;
		return NO;
	} firstly:YES];

	return [self queue:request withType:AZAPIRequestTypeDefault];
}

@end
