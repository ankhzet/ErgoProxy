//
//  AZErgoDownloadDetailsPresenter.h
//  ErgoProxy
//
//  Created by Ankh on 26.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AZErgoDownloadDetailsPopover;
@interface AZErgoEntityDetailsPresenter : NSObject
@property (nonatomic) id entity;
@property (nonatomic) AZErgoDownloadDetailsPopover *popover;

- (instancetype) presenterForEntity:(id)entity in:(AZErgoDownloadDetailsPopover *)popover;
- (void) presentEntity:(id)entity detailsIn:(AZErgoDownloadDetailsPopover *)popover;

- (void) presentAction:(void(^)(AZErgoEntityDetailsPresenter *presenter))block;

- (void) dropHash;
- (void) deleteEntity;
- (void) previewEntity;
- (void) browseEntityStorage;
- (void) browseEntity;
- (void) trashEntity;
- (void) lockEntity;

- (void) recursive:(id)sender block:(void(^)(id entity))block;

@end

@interface AZErgoDownloadDetailsPresenter : AZErgoEntityDetailsPresenter

@end

@interface AZErgoChapterDetailsPresenter : AZErgoDownloadDetailsPresenter

@end
