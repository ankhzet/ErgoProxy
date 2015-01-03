//
//  AZErgoHTMLResponse.h
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPAsyncFileResponse.h"

@class HTTPConnection, AZErgoSubstitutioner;
@interface AZErgoHTMLResponse : HTTPAsyncFileResponse

+ (instancetype) responseWithContent:(AZErgoSubstitutioner *)content andMarkup:(NSString *)filename forConnection:(HTTPConnection *)connection;
- (id) initWithContent:(AZErgoSubstitutioner *)content andMarkup:(NSString *)filename forConnection:(HTTPConnection *)connection;

@end
