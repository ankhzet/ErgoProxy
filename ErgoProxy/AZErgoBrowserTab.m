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

	if (!httpServer) {

		httpServer = [[HTTPServer alloc] init];
		[httpServer setConnectionClass:[AZErgoHTTPConnection class]];
		[httpServer setType:@"_http._tcp."];

		NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"web"];

		[httpServer setDocumentRoot:webPath];

		NSError *error;
		if([httpServer start:&error]) {
//			[WebView registerURLSchemeAsLocal:@"ergo"];

			NSString *host = [NSString stringWithFormat:@"localhost:%hu", httpServer.listeningPort];
			NSURL *url = [[NSURL alloc] initWithScheme:@"http" host:host path:@"/manga"];

			self.tfAddressField.stringValue = [url absoluteString] ?: [NSString stringWithFormat:@"http://%@", host];
		} else {
			DDLogError(@"Error starting HTTP Server: %@", error);
		}

	}

	if ([httpServer isRunning]) {
		NSString *host = [NSString stringWithFormat:@"localhost:%hu", httpServer.listeningPort];

		NSURL *url = [NSURL URLWithString:self.tfAddressField.stringValue];
		if (!url) {
			url = [[NSURL alloc] initWithScheme:@"http" host:host path:@"/manga"];
		}

		self.tfAddressField.stringValue = [url absoluteString] ?: [NSString stringWithFormat:@"http://%@", host];

		[[self.wvWebView mainFrame] loadRequest:[NSURLRequest requestWithURL: url]];
	}

	[super show];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	self.tfAddressField.stringValue = sender.mainFrameURL ?: @"oO";
}

@end
