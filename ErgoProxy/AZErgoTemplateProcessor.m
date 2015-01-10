//
//  AZErgoTemplateProcessor.m
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoTemplateProcessor.h"
#import "AZErgoSubstitutioner.h"

#define ZEROES_LEN 8

@interface AZErgoTemplateProcessor () {
	NSMutableData *_openTag, *_closeTag;
}

@end

@implementation AZErgoTemplateProcessor

- (id)initWithOpenTag:(NSString *)open andCloseTag:(NSString *)close {
	if (!(self = [self init]))
		return self;

	self.openTag = open;
	self.closeTag = close;
	return self;
}

- (id)init {
	if (!(self = [super init]))
		return self;

	self.openTag = @"{{";
	self.closeTag = @"}}";
	return self;
}

- (NSString *) openTag {
	return [[NSString alloc] initWithData:_openTag encoding:NSUTF8StringEncoding];
}

- (NSString *) closeTag {
	return [[NSString alloc] initWithData:_closeTag encoding:NSUTF8StringEncoding];
}

- (void) setOpenTag:(NSString *)openTag {
	_openTag = [[openTag dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];

	char zeroes[ZEROES_LEN] = {0, 0, 0, 0, 0, 0, 0, 0};
	[_openTag appendBytes:&zeroes length:8];
}

- (void) setCloseTag:(NSString *)closeTag {
	_closeTag = [[closeTag dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];

	char zeroes[ZEROES_LEN] = {0, 0, 0, 0, 0, 0, 0, 0};
	[_closeTag appendBytes:&zeroes length:8];
}


char* search(const char *where, const char *_pattern, NSUInteger count) {
	char *buff = (void *)where;

	while (*buff) {

		char *pattern = (void *)_pattern;
		while ((!!count) && (*buff != *pattern)) {
			buff++;
			count--;
		}

		if (*buff != *pattern)
			return NULL;

		char *mem = buff;
		while ((!!*pattern) && (*buff == *pattern)) {
			buff++;
			pattern++;
		}

		if (!!*pattern) {
			buff = mem;
			buff++;
			count--;
			continue;
		}

		return mem;
	}

	return NULL;
}

- (NSUInteger) processData:(void **)buffer withSubstitutions:(AZErgoSubstitutioner *)substitutions withLength:(NSUInteger *)length withMaxLength:(NSUInteger *)maxLength {

	NSUInteger openLen = [_openTag length] - ZEROES_LEN;
	NSUInteger closeLen = [_closeTag length] - ZEROES_LEN;
	NSUInteger tagLen = openLen + closeLen;

	NSUInteger offset = 0;
	NSUInteger stopOffset = (*length > openLen) ? *length - openLen + 1 : 0;

	BOOL found1 = NO;
	BOOL found2 = NO;
	BOOL hasSubstitutions = YES;
//	BOOL allSubstitutions = NO;

	NSUInteger s1 = 0;
	NSUInteger s2 = 0;

	const char *open = [_openTag bytes];
	const char *close = [_closeTag bytes];

	while (hasSubstitutions) {
		hasSubstitutions = NO;
		found1 = found2 = NO;
		s1 = s2 = 0;
		offset = 0;

		while (offset < stopOffset) {
			const char *subBuffer = *buffer + offset;

			char *seek = (void *)subBuffer;
			const char *openedAt = search(seek, open, stopOffset - offset);

			if ((found1 = !!openedAt)) {

				const char *closedAt = openedAt ? search(openedAt, close, stopOffset - offset) : NULL;
				if (!closedAt) {
//					offset += openedAt - seek;
					break;
				}

				while (!!openedAt) {
					const char *nextOpenedAt = search(openedAt + 1, open, stopOffset - offset);
					if ((!nextOpenedAt) || (nextOpenedAt > closedAt))
						break;
					else
						openedAt = nextOpenedAt;
				}

				s1 = offset + (openedAt - seek);

				if ((found2 = !!closedAt)) {
					s2 = offset + (closedAt - seek);

					NSRange fullRange, strRange;

					strRange.location = s1 + openLen;
					fullRange.location = s1;

					strRange.length = s2 - strRange.location;
					fullRange.length = strRange.length + tagLen;

					void *strBuf = *buffer + strRange.location;

					NSString *key = [[NSString alloc] initWithBytes:strBuf length:strRange.length encoding:NSUTF8StringEncoding];

					id value = [substitutions getSubstitution:key];
					if (value) {
						hasSubstitutions = YES;
//						allSubstitutions = YES;

						NSData *valueData = [[NSString stringWithFormat:@"%@",value] dataUsingEncoding:NSUTF8StringEncoding];
						NSUInteger valueLen = [valueData length];

						if (fullRange.length == valueLen)
							memcpy(*buffer + fullRange.location, [valueData bytes], valueLen);

						else { // (fullRange.length != vLength)
							NSInteger diff = (NSInteger)valueLen - (NSInteger)fullRange.length;

							if (diff > 0) {
								if (diff > (*maxLength - *length)) {
									NSUInteger inc = MAX(diff, 256);
									*maxLength += inc;
									*buffer = reallocf(*buffer, *maxLength);
								}
							}

							void *src = *buffer + fullRange.location + fullRange.length;
							void *dst = *buffer + fullRange.location + valueLen;

							NSUInteger remaining = *length - (fullRange.location + fullRange.length);

							memmove(dst, src, remaining);

							memcpy(*buffer + fullRange.location, [valueData bytes], valueLen);

							*length    += diff;
//							offset     += diff;
							stopOffset += diff;
							s2         += diff;
						} // if (fullRange.length !== valueLength)
					} // if (value)

					offset = s2 + closeLen;

					continue;
				} // if (found2)

				offset = s1 + 1;
			} // if (found1)
			else
				break;
		}
	}

	return found1 ? s1 : stopOffset;
}

@end

@implementation AZErgoTextTemplateProcessor

- (NSString *) processString:(NSString *)template withDataSubstitutioner:(AZErgoSubstitutioner *)substitutioner {
	NSString *result = nil;

	NSUInteger maxLen = [template maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	void *buffer = malloc(maxLen + 256);

	@try {
		[template getCString:buffer maxLength:maxLen encoding:NSUTF8StringEncoding];

		NSUInteger length = maxLen;
		[self processData:&buffer withSubstitutions:substitutioner withLength:&length withMaxLength:&maxLen];

		*((char*)((NSUInteger)buffer + maxLen)) = 0;
		result = [[NSString alloc] initWithCString:buffer encoding:NSUTF8StringEncoding];
	}
	@finally {
    free(buffer);
	}

	return result;
}

@end


