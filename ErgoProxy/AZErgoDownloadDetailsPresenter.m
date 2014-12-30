//
//  AZErgoDownloadDetailsPresenter.m
//  ErgoProxy
//
//  Created by Ankh on 26.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoDownloadDetailsPresenter.h"
#import "AZErgoDownloadDetailsPopover.h"
@implementation AZErgoEntityDetailsPresenter {
@public
	id _entity;
}
@synthesize entity = _entity, popover = _popover;

- (instancetype) presenterForEntity:(id)entity in:(AZErgoDownloadDetailsPopover *)popover {
	self.entity = entity;
	self.popover = popover;
	self.popover.tfTitle.stringValue = [self detailsTitle];
	return self;
}

- (void) presentEntity:(id)entity detailsIn:(AZErgoDownloadDetailsPopover *)popover {
	[self presenterForEntity:entity in:popover];
}

- (NSString *) detailsTitle {
	return nil;
}

@end

@implementation AZErgoDownloadDetailsPresenter {
	AZDownload *download;
}
@synthesize entity = download;

// TODO: refactor uggly direct param access

- (NSString *) plainTitle {
	if ([CustomDictionary isDictionary:self.entity]) {
		KeyedHolder *holder = ((CustomDictionary *)self.entity)->owner;
		return holder->holdedObject;
	}

	return [self.entity description];
}

- (NSString *) detailsTitle {
	return [self plainTitle];
}

- (void) presentEntity:(id)entity detailsIn:(AZErgoDownloadDetailsPopover *)popover {
	[self presenterForEntity:entity in:popover];
}

@end


@implementation AZErgoChapterDetailsPresenter  {
	CustomDictionary *group;
}
@synthesize entity = group;

@end
