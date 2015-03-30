//
//  AZGroupableDataSource.h
//  ErgoProxy
//
//  Created by Ankh on 24.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomDictionary.h"
#import "KeyedHolder.h"
#import "AZConfigurableTableCellView.h"

#import "AZMultipleTargetDelegate.h"

#import "AZActionIntent.h"

@protocol AZErgoUpdatesDataSourceDelegate <NSObject>

- (void) delegatedAction:(AZActionIntent *)action;

@end

@interface AZGroupableDataSource : NSObject<NSCollectionViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate> {
@protected
	NSMutableDictionary *_fetch;
	NSMutableDictionary *keysMapping;
	CustomDictionary *groups;
	CustomDictionary *rootNodes;
}

@property (nonatomic) NSArray *data;
@property (nonatomic) BOOL groupped;
@property (nonatomic) BOOL filter;
@property (nonatomic) NSMutableDictionary *userInfo;

@property (nonatomic) id target;

- (instancetype) setTo:(id)target;

- (void) reload;
- (void) diff:(NSArray *)newData;

- (id) findOutlineItem:(id)item recursive:(id)holder;
- (id) cellViewFromSender:(id)sender;

- (void) setUserInfo:(id)object forKey:(id<NSCopying>)key;
- (id) userInfoForKey:(id<NSCopying>)key;

- (void) expandFirstLevelIn:(NSOutlineView *)outlineView;

@end

@interface AZGroupableDataSource (Sorting)

- (void) sort;
- (NSArray *) sort:(CustomDictionary *)group keys:(NSArray *)keys;

- (NSArray *) orderedItemsInGroup:(id)group;
- (id) orderedItemAtIndex:(NSInteger)index inGroup:(id)group;
- (NSUInteger) itemIndex:(id)item inGroup:(id)group;

@end


@interface AZGroupableDataSource (AccessorsBehaviour) <AZMultipleTargetDelegateProtocol>

- (IBAction) actionDelegatedClick:(id)sender;

- (NSString *) outlineView:(NSOutlineView *)outlineView cellTypeForItem:(id)item;

- (CGFloat) groupCellHeight:(id)item;
- (CGFloat) cellHeight:(id)item;

@end

@interface AZGroupableDataSource (Groupping)

- (NSString *) rootIdentifierFromItem:(id)item;
- (NSString *) groupIdentifierFromItem:(id)item;
- (NSString *) itemIdentifierFromItem:(id)item;
- (id) rootNodeOf:(id)item;
- (id) groupNodeOf:(id)item;
- (id<NSCopying>) orderedUID:(id)item;

@end
