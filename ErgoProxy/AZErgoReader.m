//
//  AZErgoReader.m
//  ErgoProxy
//
//  Created by Ankh on 27.02.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZErgoReader.h"
#import "AZErgoReaderContentProvider.h"

#import "AZErgoMangaCommons.h"
#import "AZErgoUpdatesCommons.h"

@implementation AZErgoReader {
	id keyMonitor;
}
@synthesize contentView = _contentView, currentContentIndex = _currentContentIndex;

+ (instancetype) readerWithContentProvider:(AZErgoReaderContentProvider *)contentProvider {
	AZErgoReader *reader = [self new];
	reader.contentProvider = contentProvider;
	return reader;
}

- (id)init {
	if (!(self = [super init]))
		return self;

	[self configureKeyMonitor];
	return self;
}

- (void)dealloc {
	[self unsetKeyMonitor];

	[self flushCaches];
}

- (NSString *) readedTitle {
	AZErgoManga *manga = self.contentProvider.manga;

	NSString *title = [manga description];

	float chapterID = self.contentProvider.chapterID;
	title = [NSString stringWithFormat:@"%@ ⟩ ch. %@/%@", title, @(chapterID), @([AZErgoMangaChapter lastChapter:manga.name])];

	AZErgoUpdateChapter *chapter = [AZErgoUpdateChapter any:@"abs(persistentIdx - %f) < 0.01 and watch.manga ==[c] %@", chapterID, manga.name];

	if (chapter)
		title = [NSString stringWithFormat:@"%@ %@", title, chapter.title];

	return title;
}

- (NSView *) contentView {
	NSAssert(_contentView, @"Attach to superview first");
	return _contentView;
}

- (NSImageView *) holderOfContent:(id)uid {
	NSUInteger idx = [self.contentProvider contentIDX:uid];
	return [self holderOfContentWithIDX:idx];
}

- (NSImageView *) holderOfContentWithIDX:(NSUInteger)index {
	return [self.contentView viewWithTag:index + 1];
}

- (void) setCurrentContentIndex:(NSInteger)currentContentIndex {
	_currentContentIndex = [self.contentProvider constraintIndex:currentContentIndex];

	[self.contentProvider viewingContentAtIndex:_currentContentIndex];

	if (self.contentProvider.hasContent)
		[self showContent:_currentContentIndex];
}

#pragma mark - Util

- (void) show {
	[self attachToView:[self.delegate superview]];
	[self showContents:YES];
}

- (void) showContent:(NSInteger)index {
	[self.delegate contentShow:[self.contentProvider contentID:index]];
}

- (void) notifyEnd:(BOOL)backward {
	[self.delegate noContents:self.contentProvider.chapterID navigatedBackward:backward];
}

- (void) unsetKeyMonitor {
	if (keyMonitor)
		[NSEvent removeMonitor:keyMonitor];
}

- (void) configureKeyMonitor {
	@synchronized(self) {
		[self unsetKeyMonitor];

		AZErgoReader *reader = self;
		keyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *event) {
//			AZErgoReader *reader = _reader;
//			if (!reader)
//				return event;

			BOOL validEvent = !!([event modifierFlags] & NSNumericPadKeyMask);

			if (!([reader isKey] && validEvent))
				return event;

			NSString *charachters = [event charactersIgnoringModifiers];

			BOOL isBackward = AZCH_STR(charachters, NSLeftArrowFunctionKey);
			BOOL isForward = AZCH_STR(charachters, NSRightArrowFunctionKey);
			if (isBackward || isForward) {
				NSInteger next = reader.currentContentIndex + (isBackward ? -1 : +1);

				NSInteger clamp= [reader.contentProvider constraintIndex:next];
				BOOL outOfRange = next != clamp;
				if (outOfRange || AZ_KEYDOWN(Command))
					[reader navigate:isBackward];
				else
					reader.currentContentIndex = next;

				return nil;
			}

			return event;
		}];
	}
}

- (BOOL) isKey {
	return self.delegate ? [self.delegate isKey] : YES;
}

- (void) navigate:(BOOL)back {
	if ([self.contentProvider seekNext:back])
		[[AZDelayableAction shared:@"reader-nav"] delayed:0.3 execute:^{
			[self showContents:YES];
		}];
	else
		[self notifyEnd:back];
}

- (void) showContents:(BOOL)flushCaches {
	[self loadContents:flushCaches];

	BOOL backward = self.contentProvider.navigatedBackward;

	if (!self.contentProvider.hasContent)
		[self notifyEnd:backward];

	[self buildViewTree:self.contentProvider.content];

	self.currentContentIndex = backward ? INT_MAX : 0;
}

- (CGSize) contentSize {
	return self.contentView.frame.size;
}

- (void) updateScanView:(id)uid {

}

- (void) scanCached:(id)uid {

}

#pragma mark - Content loading

- (void) flushCaches {
	[self.contentProvider flushCache];
}

- (void) cacheContents {

}

- (void) loadContents:(BOOL)flushCaches {
	[self.delegate willRecache];

	if (flushCaches)
		[self flushCaches];

	[self cacheContents];
}

- (int) scanCount {
	return (int)[self.contentProvider.content count];
}


#pragma mark - View tree building

- (void) attachToView:(NSView *)superview {
	[_contentView setSubviews:@[]];
	[_contentView removeFromSuperview];

	_contentView = [[NSView alloc] initWithFrame:superview.frame];
//	[_contentView setAutoresizesSubviews:YES];
	[_contentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

	[superview addSubview:_contentView];

	[superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_contentView]|"
																																		options:0
																																		metrics:@{}
																																			views:NSDictionaryOfVariableBindings(_contentView)]];

	[superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_contentView]|"
																																		options:0
																																		metrics:@{}
																																			views:NSDictionaryOfVariableBindings(_contentView)]];
	[superview updateConstraintsForSubtreeIfNeeded];
}

- (void) buildViewTree:(NSArray *)content {
	NSMutableArray *contentNodes = [NSMutableArray new];
	for (id contentNode in content)
		[contentNodes addObject:[self addContentNode:contentNode
																			 withIndex:[content indexOfObject:contentNode]
																			 toTree:self.contentView
																		withNodes:contentNodes]];

	[self alignViewTree:self.contentView withContents:content withNodes:contentNodes];
}

- (void) alignViewTree:(NSView *)contentTree withContents:(NSArray *)content withNodes:(NSArray *)contentNodes {
	[contentTree setSubviews:@[]];

	for (NSView *node in contentNodes) {
    [contentTree addSubview:node];

		[contentTree addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[node]|"
																																				options:0 metrics:0
																																					views:NSDictionaryOfVariableBindings(node)]];

		[contentTree addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[node]|"
																																				options:0 metrics:0
																																					views:NSDictionaryOfVariableBindings(node)]];
		[node setHidden:YES];
	}
}

- (NSView *) addContentNode:(id)contentNode withIndex:(NSUInteger)index toTree:(NSView *)contentTree withNodes:(NSMutableArray *)contentNodes {
	NSImageView *holder = [[NSImageView alloc] initWithFrame:contentTree.frame];
	[holder setAutoresizesSubviews:YES];
	[holder setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

	holder.image = [NSImage imageNamed:NSImageNameApplicationIcon];
	holder.imageFrameStyle = NSImageFrameNone;
	holder.imageAlignment = NSImageAlignCenter;
	holder.imageScaling = NSImageScaleProportionallyDown;
	holder.tag = index + 1;

	return holder;
}

@end
