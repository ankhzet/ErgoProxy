//
//  AZErgoCustomDownloader.m
//  ErgoProxy
//
//  Created by Ankh on 15.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoCustomDownloader.h"

#import "AZDownload.h"
#import "AZStorage.h"
#import "AZErgoAPIRequest.h"

#import "AZProxifier.h"
#import "AZErgoAPIRequest.h"
#import "AZErgoDownloader.h"


@interface AZErgoCustomDownloader () {
@protected
	NSMutableDictionary *_downloads;
}

@end

@implementation AZErgoCustomDownloader
@synthesize downloads = _downloads;

- (AZDownload *) addDownload:(AZDownload *)download {
	@synchronized(_downloads) {
		if (!_downloads)
			_downloads = [NSMutableDictionary dictionary];

		AZDownload *old = _downloads[download.sourceURL];
		_downloads[download.sourceURL] = download;

		download.storage = self.storage;
		return old;
	}
}

- (void) removeDownload:(AZDownload *)download {
	@synchronized(_downloads) {
		[_downloads removeObjectForKey:download.sourceURL];
	}
}

- (AZDownload *) hasDownloadForURL:(NSString *)url {
	@synchronized(_downloads) {
		return _downloads[url];
	}
}

@end
