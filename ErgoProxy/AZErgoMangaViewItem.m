//
//  AZErgoMangaViewItem.m
//  ErgoProxy
//
//  Created by Ankh on 03.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoMangaViewItem.h"
#import "AZErgoMangaCommons.h"
#import "AZCollapsingView.h"
#import "AZErgoDownloadsDataSource.h"

@interface AZErgoMangaViewItem () {
	NSView *__view;
}
@property (weak) IBOutlet NSImageView *ivMangaPreview;
@property (weak) IBOutlet NSTextField *tfMangaTitle;
@property (weak) IBOutlet NSTextField *tfAdditionalTitle;
@property (weak) IBOutlet NSTextField *tfMangaStatus;
@property (weak) IBOutlet NSTextField *tfMangaTags;
@property (weak) IBOutlet NSImageView *ivComplete;
@property (weak) IBOutlet NSImageView *ivReaded;

@end

@implementation AZErgoMangaViewItem
@synthesize representedObject;

- (void) setSelected:(BOOL)selected {
	[super setSelected:selected];

}

- (NSString *) nibName {
	return @"MangaCellView";
}

- (void) setRepresentedObject:(id)_representedObject {
	representedObject = _representedObject;
	
	[self view];

	if (!representedObject)
		return;
	
	self.tfMangaTitle.stringValue = [representedObject mainTitle];
	self.textField.stringValue = [representedObject mainTitle];

	NSString *additional = [[representedObject additionalTitles] firstObject];
	self.tfAdditionalTitle.stringValue = additional ?: @"";
	[self.tfAdditionalTitle setCollapsed:![additional length]];

	NSString *current = [AZErgoDownloadsDataSource formattedChapterIDX:5];
	NSString *last = [AZErgoDownloadsDataSource formattedChapterIDX:6.5 prefix:NO];
	self.tfMangaStatus.stringValue = [NSString stringWithFormat:@"Progress: %@/%@", current, last];

	BOOL isComplete = NO;
	BOOL isReaded = NO;
	for (AZErgoMangaTag *tag in representedObject.tags)
		switch ([tag.guid unsignedIntegerValue]) {
			case AZErgoTagGroupComplete:
				isComplete = YES;
				break;
			case AZErgoTagGroupReaded:
				isReaded = YES;
				break;

			default:
				break;
		}

	[self.ivComplete setImage:isComplete ? [NSImage imageNamed:NSImageNameActionTemplate] : nil];
	[self.ivReaded setImage:isReaded ? [NSImage imageNamed:NSImageNameAddTemplate] : nil];

	[self.view setNeedsDisplay:YES];
}

- (IBAction)actionRead:(id)sender {
	[self delegated:@selector(viewItem:read:)];
}

- (IBAction)actionShowInfo:(id)sender {
	[self delegated:@selector(viewItem:showInfo:)];
}

- (void) delegated:(SEL)selector {
	if ([self.collectionView.delegate conformsToProtocol:@protocol(AZErgoMangaViewItemDelegate)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self.collectionView.delegate performSelector:selector withObject:self withObject:self.representedObject];
#pragma clang diagnostic pop
	}
}

@end
