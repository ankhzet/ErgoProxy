//
//  AZErgoBrowserTab.m
//  ErgoProxy
//
//  Created by Ankh on 26.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoBrowserTab.h"
#import "AZErgoTabsComons.h"
#import <WebKit/WebKit.h>

#import "HTTPServer.h"
#import "AZErgoHTTPConnection.h"

@interface AZErgoBrowserTab () {
	HTTPServer *httpServer;
}
@property (weak) IBOutlet WebView *wvWebView;
@property (weak) IBOutlet NSTextField *tfAddressField;

@end

@implementation AZErgoBrowserTab

- (NSString *) tabIdentifier {
	return AZEPUIDBrowserTab;
}

- (void) show {
	[self.wvWebView setFrameLoadDelegate:self];

	NSString *navPath = self.navData ? [NSString stringWithFormat:@"/reader/%@",self.navData] : @"/manga";
	NSURL *url = self.navData ? nil : [NSURL URLWithString:self.tfAddressField.stringValue];

	if (!httpServer) {
		url = nil;

		httpServer = [[HTTPServer alloc] init];
		[httpServer setConnectionClass:[AZErgoHTTPConnection class]];
		[httpServer setType:@"_http._tcp."];

		NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"web"];

		[httpServer setDocumentRoot:webPath];
		[httpServer setPort:2012];

		NSError *error;
		if([httpServer start:&error]) {
		} else {
			DDLogError(@"Error starting HTTP Server: %@", error);
		}

	}

	if ([httpServer isRunning]) {
		NSString *host = [NSString stringWithFormat:@"localhost:%hu", httpServer.listeningPort];

		if (!url)
			url = [[NSURL alloc] initWithScheme:@"http" host:host path:navPath];

		navPath = [url absoluteString] ?: [NSString stringWithFormat:@"http://%@", host];

		self.tfAddressField.stringValue = [navPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

		[[self.wvWebView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
	}

	[super show];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	self.tfAddressField.stringValue = [sender.mainFrameURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ?: @"oO";
}

@end
