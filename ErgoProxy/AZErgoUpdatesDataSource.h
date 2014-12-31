//
//  AZErgoUpdatesDataSource.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZGroupableDataSource.h"

@class AZErgoUpdatesDataSource, AZErgoUpdatesCellView;

@interface AZErgoUpdateActionIntent : NSObject

@property (nonatomic, readonly) NSString *action;

@property (nonatomic, readonly) id initiator;
@property (nonatomic, weak, readonly) AZErgoUpdatesDataSource *source;
@property (nonatomic, readonly) AZErgoUpdatesCellView *initiatorContainedBy;
@property (nonatomic, readonly) id initiatorRelatedEntity;

- (BOOL) is:(NSString *)actionIdentifier;

@end

@protocol AZErgoUpdatesDataSourceDelegate <NSObject>

- (void) delegatedAction:(AZErgoUpdateActionIntent *)action;

@end

@interface AZErgoUpdatesDataSource : AZGroupableDataSource

@property (nonatomic) IBOutlet id<AZErgoUpdatesDataSourceDelegate> delegate;

@property (nonatomic) BOOL expanded;

@end
