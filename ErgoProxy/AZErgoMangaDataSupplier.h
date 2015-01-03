//
//  AZErgoMangaDataSupplier.h
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AZErgoSubstitutioner.h"

@interface AZErgoMangaDataSupplier : NSObject  <AZErgoSubtitutionerDataSupplier> {
	NSDictionary *data;
}

- (id)initWithDictionary:(NSDictionary *)dictionary;
+ (instancetype) dataWithDirectoryIndex:(NSString *)path;
+ (instancetype) dataWithReader:(NSString *)path;

+ (NSString *)mangaStorage;

+ (NSArray *) componentsFromAbsolutePath:(NSString *)path;
+ (NSArray *) fetchChapters:(NSString *)manga;

@end
