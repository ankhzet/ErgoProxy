//
//  AZErgoDownloadDetailsPresenter.h
//  ErgoProxy
//
//  Created by Ankh on 26.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AZErgoDownloadDetailsPopover;
@protocol AZErgoDownloadDetailsPresenterProtocol <NSObject>

- (instancetype) presenterForEntity:(id)entity in:(AZErgoDownloadDetailsPopover *)popover;
- (void) presentEntity:(id)entity detailsIn:(AZErgoDownloadDetailsPopover *)popover;

@end


@interface AZErgoEntityDetailsPresenter : NSObject <AZErgoDownloadDetailsPresenterProtocol>
@property (nonatomic) id entity;
@property (nonatomic) AZErgoDownloadDetailsPopover *popover;

@end

@interface AZErgoDownloadDetailsPresenter : AZErgoEntityDetailsPresenter

@end

@interface AZErgoChapterDetailsPresenter : AZErgoDownloadDetailsPresenter

@end
