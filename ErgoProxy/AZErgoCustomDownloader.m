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
	@synchronized(self) {
		if (!_downloads)
			_downloads = [NSMutableDictionary dictionary];
	}

	@synchronized(_downloads) {
		AZDownload *old = _downloads[download.sourceURL];
		_downloads[download.sourceURL] = download;

		download.storage = self.storage;
		return old;
	}
}

- (void) removeDownload:(AZDownload *)download {
	if (!_downloads)
		return;

	@synchronized(_downloads) {
		[_downloads removeObjectForKey:download.sourceURL];
	}
}

- (AZDownload *) hasDownloadForURL:(NSString *)url {
	if (!_downloads)
		return nil;

	@synchronized(_downloads) {
		return _downloads[url];
	}
}

- (NSDictionary *) downloads {
	@synchronized(self) {
		return _downloads;
	}
}

@end
