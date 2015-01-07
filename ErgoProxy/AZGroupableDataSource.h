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
#import "AZErgoConfigurableTableCellView.h"

@class RootDictionary;

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

- (void) reload;

- (id) findOutlineItem:(id)item recursive:(id)holder;
- (id) cellViewFromSender:(id)sender;

@end

@interface AZGroupableDataSource (AccessorsBehaviour)

- (IBAction) actionDelegatedClick:(id)sender;

- (NSArray *) sort:(CustomDictionary *)group keys:(NSArray *)keys;

- (NSString *) outlineView:(NSOutlineView *)outlineView cellTypeForItem:(id)item;

- (CGFloat) groupCellHeight:(id)item;
- (CGFloat) cellHeight:(id)item;

- (NSString *) rootIdentifierFromItem:(id)item;
- (NSString *) groupIdentifierFromItem:(id)item;
- (NSString *) itemIdentifierFromItem:(id)item;
- (id) rootNodeOf:(id)item;
- (id) groupNodeOf:(id)item;
- (id<NSCopying>) orderedUID:(id)item;

@end
