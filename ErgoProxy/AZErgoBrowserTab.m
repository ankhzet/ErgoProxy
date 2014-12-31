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

@interface AZErgoBrowserTab () {
	HTTPServer *httpServer;
}
@property (weak) IBOutlet WebView *wvWebView;

@end

@implementation AZErgoBrowserTab

- (NSString *) tabIdentifier {
	return AZEPUIDBrowserTab;
}

- (void) show {
	if (!httpServer) {

	httpServer = [[HTTPServer alloc] init];

	// Tell server to use our custom MyHTTPConnection class.
	[httpServer setConnectionClass:[MyHTTPConnection class]];

	// Tell the server to broadcast its presence via Bonjour.
	// This allows browsers such as Safari to automatically discover our service.
	[httpServer setType:@"_http._tcp."];

	// Normally there's no need to run our server on any specific port.
	// Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
	// However, for easy testing you may want force a certain port so you can just hit the refresh button.
	//	[httpServer setPort:12345];

	// Serve files from our embedded Web folder
	NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
	DDLogVerbose(@"Setting document root: %@", webPath);

	[httpServer setDocumentRoot:webPath];

	// Start the server (and check for problems)

	NSError *error;
	BOOL success = [httpServer start:&error];

	if(!success)
	{
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
	}

	[super show];
}

- (void) navigateTo:(id)data {
	
}

@end
