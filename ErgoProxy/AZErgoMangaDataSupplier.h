//
//  AZErgoMangaDataSupplier.h
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZErgoDictionaryDataSupplier.h"

@interface AZErgoMangaDataSupplier : AZErgoDictionaryDataSupplier

+ (instancetype) dataWithDirectoryIndex:(NSString *)path;
+ (instancetype) dataWithReader:(NSString *)path;

+ (instancetype) dataWithProgress:(NSString *)path;

+ (NSArray *) componentsFromAbsolutePath:(NSString *)path;

@end
