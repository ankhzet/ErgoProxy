//
//  AZStorage.m
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZStorage.h"
#import "AZProxifier.h"

@implementation AZStorage
@dynamic downloads, proxifier;

/*!
 @brief Returns new storage with specified url.
 Absolute URL must contain empty path component, eg.
 http://server.domen/
 http://subdomen.server.domen/
 Relative URL may specify scheme, different from parent proxifier instance, eg.
 storage-1
 a.storage
 https://storage-1
 https://a.storage
 which for parent proxy address http://server.domen/ will be autocompleted to
 http://storage-1.server.domen/
 http://a.storage.server.domen/
 https://storage-1.server.domen/
 https://a.storage.server.domen/

 @param url URL of server. Can be absolute or relative.
 */
+ (instancetype) serverWithURL:(NSURL *)url {
	return [super serverWithURL:url];
}


- (NSURL *) fullURL {
	NSURL *result = self.url;
	if (![result.path isEqualToString:@"/"]) {
		NSURL *source = [self.proxifier.url standardizedURL];

		NSString *scheme = [result.scheme length] ? result.scheme : source.scheme;
		NSString *subdomen = [result.path length] ? result.path : result.host;
		result = [[NSURL alloc] initWithScheme:scheme host:[NSString stringWithFormat:@"%@.%@", subdomen, source.host] path:@"/"];
	}
	return result;
}

@end
