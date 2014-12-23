//
//  AZErgoProxifierAPI.h
//  ErgoProxy
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZJSONAPI.h"

@class AZDownload;

typedef void (^p_block)(BOOL isOk, id json, AZDownload *download);

@interface AZErgoProxifierAPI : AZJSONAPI

- (AZHTTPRequest *) proxifyDownload:(AZDownload *)download withCompletion:(p_block)block;

@end
