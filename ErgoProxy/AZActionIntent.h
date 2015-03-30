//
//  AZActionIntent.h
//  ErgoProxy
//
//  Created by Ankh on 20.03.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AZGroupableDataSource, AZConfigurableTableCellView;

@interface AZActionIntent : NSObject

@property (nonatomic, readonly) NSString *action;
@property (nonatomic, readonly) NSUInteger modifiers;

@property (nonatomic, readonly) id initiator;
@property (nonatomic, weak, readonly) AZGroupableDataSource *source;
@property (nonatomic, readonly) AZConfigurableTableCellView *initiatorContainedBy;
@property (nonatomic, readonly) id initiatorRelatedEntity;

+ (instancetype) action:(NSString *)action intentFrom:(AZGroupableDataSource *)source withSender:(id)sender;

- (BOOL) is:(NSString *)actionIdentifier;
- (BOOL) key:(NSUInteger)mask;

@end

