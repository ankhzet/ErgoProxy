//
//  AZDownloadSpeedWatcher.m
//  ErgoProxy
//
//  Created by Ankh on 12.01.15.
//  Copyright (c) 2015 Ankh. All rights reserved.
//

#import "AZDownloadSpeedWatcher.h"

#define PURGE_DELAY 30
#define PURGE_MARGIN 200

@interface AZDownloadPack : NSObject {
@public
	NSUInteger bytes;
	NSTimeInterval timestamp;
}
+ (instancetype) pack:(NSUInteger)bytes at:(NSTimeInterval)timestamp;
@end
@implementation AZDownloadPack

+ (instancetype) pack:(NSUInteger)bytes at:(NSTimeInterval)timestamp {
	AZDownloadPack *pack = [self new];
	pack->bytes = bytes;
	pack->timestamp = timestamp;
	return pack;
}

- (NSComparisonResult) compareTimestamps:(AZDownloadPack *)another {
	return (!another) ? NSOrderedDescending : SIGN(timestamp - another->timestamp);
}

- (NSComparisonResult) compareAmount:(AZDownloadPack *)another {
	return (!another) ? NSOrderedDescending : SIGN(bytes - another->bytes);
}

- (NSString *) description {
	return [NSString stringWithFormat:@"[%.1f -> %lu bytes]", timestamp, bytes];
}

@end

MULTIDELEGATED_INJECT_MULTIDELEGATED(AZDownloadSpeedWatcher)

@implementation AZDownloadSpeedWatcher {
	NSMutableArray *downloadedPacks;
	NSTimeInterval lastPurge;
	dispatch_queue_t bgQueue;
}

+ (instancetype) sharedSpeedWatcher {
	static AZDownloadSpeedWatcher *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    instance = [self new];
	});
	return instance;
}

- (id)init {
	if (!(self = [super init]))
		return self;

	downloadedPacks = [NSMutableArray new];
	lastPurge = 0;
	bgQueue = dispatch_queue_create("org.ankhzet.speed-watcher", DISPATCH_QUEUE_SERIAL);

	return self;
}

- (void) downloaded:(NSUInteger)bytes {
	dispatch_async(bgQueue, ^{
		[downloadedPacks addObject:[AZDownloadPack pack:bytes at:[NSDate timeIntervalSinceReferenceDate]]];
		[self purge];

		dispatch_async_at_main(^{
//			MD_DELEGATED(self, watcherUpdated:self);
			[self.md_delegate watcherUpdated:self];
		});
	});
}

- (NSUInteger) totalDownloaded {
	__block NSUInteger total = 0;
	dispatch_sync(bgQueue, ^{
		for (AZDownloadPack *pack in [downloadedPacks copy])
			total += pack->bytes;
	});

	return total;
}

- (float) averageSpeed {
	return [self averageSpeedSince:0];
}

- (float) averageSpeedSince:(NSTimeInterval)date {
	__block float result = 0.f;

	dispatch_sync(bgQueue, ^{
		NSArray *probe = [downloadedPacks copy];

		if (date > 0) {
			NSMutableArray *interval = [NSMutableArray arrayWithCapacity:[probe count]];
			for (AZDownloadPack *pack in probe)
				if (pack->timestamp >= date)
					[interval addObject:pack];

			probe = interval;
		}

		NSUInteger total = 0;
		NSTimeInterval first = [[NSDate distantFuture] timeIntervalSinceReferenceDate], last = 0;
		for (AZDownloadPack *pack in probe) {
			total += pack->bytes;
			if (first > pack->timestamp) first = pack->timestamp;
			if (last  < pack->timestamp) last = pack->timestamp;
		}

		NSTimeInterval delta = ABS(last - first);
		if ((delta < 0.0001) && (ABS(date) > 0.0001)) {
			NSTimeInterval now = [AZDownloadSpeedWatcher timeWithTimeIntervalSinceNow:0];
			delta = ABS(now - date);
		}

		result = delta ? total / delta : total;
	});

	return result;
}

- (void) purge {
	if ([NSDate timeIntervalSinceReferenceDate] - lastPurge < PURGE_DELAY)
		return;

	NSUInteger count = [downloadedPacks count];
	NSUInteger purgeFreq = (int) (count / PURGE_MARGIN);

	if (purgeFreq < 2)
		return;

	NSArray *data = [downloadedPacks sortedArrayUsingSelector:@selector(compareTimestamps:)];

	NSMutableArray *all = [NSMutableArray arrayWithCapacity:PURGE_MARGIN + 1];
	NSUInteger batchLen = 0;
	NSMutableArray *batch = nil;
	for (AZDownloadPack *pack in data) {
		if (!(batchLen--)) {
			if (!!batch)
				[all addObject:batch];

			batch = [NSMutableArray arrayWithCapacity:purgeFreq];
			batchLen = purgeFreq - 1;
		}
		[batch addObject:pack];
	}

	if (!!batch)
		[all addObject:batch];

	downloadedPacks = [NSMutableArray arrayWithCapacity:PURGE_MARGIN + 1];
	for (NSArray *batch in all) {
		NSUInteger total = 0;
		for (AZDownloadPack *pack in batch)
			total += pack->bytes;

		AZDownloadPack *first = [batch firstObject];
		[downloadedPacks addObject:[AZDownloadPack pack:total at:first->timestamp]];
	}

	lastPurge = [NSDate timeIntervalSinceReferenceDate];
}

+ (NSTimeInterval) timeWithTimeIntervalSinceNow:(NSTimeInterval)delta {
	if (ABS(delta) > 0.001)
		return [[NSDate dateWithTimeIntervalSinceNow:delta] timeIntervalSinceReferenceDate];
	else
		return [NSDate timeIntervalSinceReferenceDate];
}

@end
