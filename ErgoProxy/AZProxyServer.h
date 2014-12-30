//
//  AZProxyServer.h
//  ErgoProxy
//
//  Created by Ankh on 13.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZCoreDataEntity.h"

@interface AZProxyServer : AZCoreDataEntity

@property (nonatomic, retain) NSURL *url;

+ (instancetype) serverWithURL:(NSURL *)url;

@end
