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

#import "AZErgoProxifierAPI.h"
#import "AZErgoUpdateWatch.h"

#import "AZDataProxy.h"

@interface AZErgoMangaViewItem ()

@property (weak) IBOutlet NSImageView *ivMangaPreview;
@property (weak) IBOutlet NSTextField *tfMangaTitle;
@property (weak) IBOutlet NSTextField *tfAdditionalTitle;
@property (weak) IBOutlet NSTextField *tfMangaStatus;
@property (weak) IBOutlet NSImageView *ivComplete;
@property (weak) IBOutlet NSImageView *ivReaded;

@property (weak) IBOutlet NSButton *bShowInfo;
@property (weak) IBOutlet NSButton *bResumeReading;

@end

@implementation AZErgoMangaViewItem
@synthesize representedObject;

- (void) setSelected:(BOOL)selected {
	[super setSelected:selected];

}

- (NSString *) nibName {
	return @"MangaCellView";
}

+ (dispatch_queue_t) queue:(NSString *)label {
	static NSMutableDictionary *queues;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queues = [NSMutableDictionary new];
	});

	@synchronized(queues) {
		dispatch_queue_t q = queues[label];

		if (!q)
			q = queues[label] = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);

		return q;
	}
}

- (void) dispatchAtPreviewLoader:(dispatch_block_t)block {
	dispatch_queue_t queue = [[self class] queue:@"manga-list-item.preview-loader"];

	dispatch_async(queue, block);
}

- (void) setRepresentedObject:(id)_representedObject {
	representedObject = _representedObject;

	if (!representedObject)
		return;

	NSView *view = [self view];
	[view addTrackingArea:[[NSTrackingArea alloc] initWithRect:view.visibleRect
																										 options:NSTrackingMouseEnteredAndExited|NSTrackingInVisibleRect|NSTrackingActiveInKeyWindow
																											 owner:self
																										userInfo:nil]];

	[self.ivMangaPreview setAlphaValue:0.3f];
	self.tfMangaStatus.stringValue = @"";

	[self.ivComplete setImage:nil];
	[self.ivReaded setImage:nil];

	NSString *additional = [[representedObject additionalTitles] firstObject];
	self.tfMangaTitle.stringValue = [representedObject mainTitle] ?: @"<no title!>";
	self.tfAdditionalTitle.stringValue = additional ?: @"";
	[self.tfAdditionalTitle setCollapsed:![additional length]];

	BOOL isComplete = NO;
	BOOL isReaded = NO;
	for (AZErgoMangaTag *tag in [representedObject.tags allObjects])
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

	self.ivComplete.image = isComplete ? [NSImage imageNamed:NSImageNameStatusPartiallyAvailable] : nil;
	self.ivReaded.image = isReaded ? [NSImage imageNamed:NSImageNameStatusAvailable] : nil;

	dispatch_block_t block = ^{
		AZErgoMangaProgress *p = representedObject.progress;

		float lastChapter = p.chapters;
		float currentChapter = 0.f;

		NSString *progress;
		if (lastChapter > 0) {
			BOOL readedEarlier = NO;
			BOOL hasProgress = [p has:lastChapter readed:&readedEarlier chapters:&currentChapter];

			progress = [AZErgoDownloadsDataSource formattedChapterIDX:lastChapter prefix:!readedEarlier];

			if (hasProgress) {
				NSString *current = [AZErgoDownloadsDataSource formattedChapterIDX:MIN(currentChapter, lastChapter)];
				progress = LOC_FORMAT(@"Progress: %@/%@", current, progress);
			} else
				progress = LOC_FORMAT(@"Chapters: %@", progress);

		} else
			progress = LOC_FORMAT(@"No chapters");

		BOOL hasNewChapters = currentChapter < lastChapter;

		self.tfMangaStatus.stringValue = progress;
		[self.tfMangaStatus setTextColor:hasNewChapters ? [NSColor blueColor] : [NSColor textColor]];
		[self.view setNeedsDisplay:YES];
	};

	if (representedObject.hasToCheckFS)
		[representedObject checkFSWithCompletion:^(AZErgoManga *manga) {
			[self dispatchAtPreviewLoader:block];
		}];
	else
		block();

	[self setupPreview];
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

- (void) setupPreview {
	NSString *previewFile = [self.representedObject previewFile];

	if (!previewFile)
		return;

	if (!![NSFileManager fileSize:previewFile])
		dispatch_async_at_background(^{
			NSImage *image = [[NSImage alloc] initWithContentsOfFile:previewFile];
			dispatch_async_at_main(^{
				self.ivMangaPreview.animates = NO;
				[self.ivMangaPreview setImage:image];
				[self.ivMangaPreview setAlphaValue:1.f];
			});
		});
	else
		[self downloadPreview];
}

- (void) downloadPreview {
	[self dispatchAtPreviewLoader:^{
		NSString *name = self.representedObject.name;

		__block AZErgoUpdatesSourceDescription *d;
		dispatch_sync_at_main(^{
			AZErgoUpdateWatch *watch = [AZErgoUpdateWatch any:@"manga ==[c] %@", name];

			d = watch.source;
		});
		if (!!d.serverURL) {
			NSString *waiter = [[NSBundle mainBundle] pathForResource:@"waiter" ofType:@"gif" inDirectory:@"web/theme/img"];

			dispatch_sync_at_main(^{
				self.ivMangaPreview.image = [[NSImage alloc] initByReferencingFile:waiter];
				self.ivMangaPreview.animates = YES;
			});

			if ([AZ_API(ErgoProxifier) downloadPreview:self.representedObject
																				atOrigin:[NSString stringWithFormat:@"http://%@",d.serverURL]]) {
				[self setupPreview];
			}
			else
				dispatch_async_at_main(^{
					self.ivMangaPreview.image = [NSImage imageNamed:NSImageNameApplicationIcon];
				});
		}
	}];
}

- (void) mouseEntered:(NSEvent *)theEvent {
	[self.bShowInfo setHidden:NO];
	[self.bResumeReading setHidden:NO];
}

- (void) mouseExited:(NSEvent *)theEvent {
	[self.bShowInfo setHidden:YES];
	[self.bResumeReading setHidden:YES];
}

@end
