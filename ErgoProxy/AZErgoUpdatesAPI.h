//
//  AZErgoUpdatesAPI.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZClientAPI.h"

typedef void (^p_block)(BOOL isOk, id data);

@interface AZErgoUpdateMangaInfo : NSObject {
@public
	NSString *genData;
	NSArray *titles;
	NSArray *tags;
	NSString *annotation;
	NSString *preview;
	NSArray *chapters;
	BOOL isComplete;
}

@end

@class AZErgoUpdatesSource, AZErgoUpdateWatch, AZErgoUpdateChapter;
@interface AZErgoUpdatesAPI : AZClientAPI

- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source watch:(AZErgoUpdateWatch *)watch infoWithCompletion:(p_block)block;
- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source chapter:(AZErgoUpdateChapter *)chapter scansWithCompletion:(p_block)block;
- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source matchingEntities:(NSString *)query withCompletion:(p_block)block;

@end
