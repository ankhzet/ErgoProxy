//
//  AZErgoUpdatesAPI.m
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoUpdatesAPI.h"
#import "AZHTMLRequest.h"
#import "AZErgoUpdatesSource.h"
#import "AZErgoUpdateWatch.h"
#import "AZErgoUpdateChapter.h"

@implementation AZErgoUpdateMangaInfo

@end

@implementation AZErgoUpdatesAPI

- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source watch:(AZErgoUpdateWatch *)watch infoWithCompletion:(p_block)block {
	AZHTMLRequest *request = [source infoAction:watch];

	[[request success:^(AZHTTPRequest *request, TFHpple **document) {
		AZErgoUpdateMangaInfo *info = [AZErgoUpdateMangaInfo new];
		info->genData = watch.genData;
		info->titles = [source titlesFromDocument:*document];
		info->tags = [source tagsFromDocument:*document];
		info->annotation = [source annotationFromDocument:*document];
		info->preview = [source previewFromDocument:*document];
		info->chapters = [source chaptersFromDocument:*document];
		info->isComplete = [source isCompleteFromDocument:*document];

		block(YES, info);
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		block(NO, nil);
		action.showErrors = NO;
		return YES;
	} firstly:YES];

	return [self queue:request withType:AZAPIRequestTypeDefault];
}

- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source chapter:(AZErgoUpdateChapter *)chapter scansWithCompletion:(p_block)block {
	AZHTMLRequest *request = [source scansAction:chapter];

	[[request success:^(AZHTTPRequest *request, TFHpple **document) {
		block(YES, [source scansFromDocument:*document]);
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		block(NO, nil);
		action.showErrors = NO;
		return YES;
	} firstly:YES];

	return [self queue:request withType:AZAPIRequestTypeDefault];
}

- (AZHTTPRequest *) updates:(AZErgoUpdatesSource *)source matchingEntities:(NSString *)query withCompletion:(p_block)block {
	AZHTMLRequest *request = [source searchAction:query];

	[[request success:^(AZHTTPRequest *request, TFHpple **document) {
		NSDictionary *entities = [source entitiesFromDocument:*document];

		AZ_MutableI(Array, *result, arrayWithCapacity:[entities count]);
		for (NSString *genData in [entities allKeys]) {
			AZErgoUpdateMangaInfo *info = [AZErgoUpdateMangaInfo new];

			info->genData = genData;
			info->titles = [[source parseTitles:entities[genData]] allObjects];

			[result addObject:info];
		}

		block(YES, result);
		return YES;
	}] error:^BOOL(AZHTTPRequest *action, NSString *response) {
		block(NO, nil);
		action.showErrors = NO;
		return YES;
	} firstly:YES];

	return [self queue:request withType:AZAPIRequestTypeDefault];
}

@end
