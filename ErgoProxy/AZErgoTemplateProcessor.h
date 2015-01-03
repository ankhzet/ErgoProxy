//
//  AZErgoTemplateProcessor.h
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AZErgoSubstitutioner;
@interface AZErgoTemplateProcessor : NSObject

@property (nonatomic) NSString *openTag;
@property (nonatomic) NSString *closeTag;

- (id)initWithOpenTag:(NSString *)open andCloseTag:(NSString *)close;
- (NSUInteger) processData:(void **)_buffer withSubstitutions:(AZErgoSubstitutioner *)substitutions withLength:(NSUInteger *)length withMaxLength:(NSUInteger *)maxLength;

@end

@interface AZErgoTextTemplateProcessor : AZErgoTemplateProcessor

- (NSString *) processString:(NSString *)template withDataSubstitutioner:(AZErgoSubstitutioner *)substitutioner;

@end