//
//  AZErgoAPI.h
//  ErgoProxy
//
//  Created by Ankh on 12.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZJSONAPI.h"

typedef void (^p_block)(BOOL isOk, id data);

@interface AZErgoAPI : AZJSONAPI

- (AZHTTPRequest *) aquireMangaDataFromIP:(NSString *)ip withCompletion:(p_block)completionBlock;

@end
