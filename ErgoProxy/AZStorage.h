//
//  AZStorage.h
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZProxyServer.h"

@class AZProxifier;
@interface AZStorage : AZProxyServer

@property (nonatomic, retain) AZProxifier *proxifier;
@property (nonatomic, retain) NSSet *downloads;

+ (instancetype) serverWithURL:(NSString *)url;

- (NSString *) fullURL;

@end
