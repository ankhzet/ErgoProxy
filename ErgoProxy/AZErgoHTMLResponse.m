//
//  AZErgoHTMLResponse.m
//  ErgoProxy
//
//  Created by Ankh on 31.12.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "AZErgoHTMLResponse.h"
#import "HTTPConnection.h"
#import "HTTPMessage.h"
#import "HTTPLogging.h"

#import "AZErgoTemplateProcessor.h"
#import "AZErgoSubstitutioner.h"

static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;

@interface AZErgoHTMLResponse () {
	AZErgoTemplateProcessor *processor;
	AZErgoSubstitutioner *substitutioner;
}

@end

@implementation AZErgoHTMLResponse

+ (instancetype) responseWithContent:(AZErgoSubstitutioner *)content andMarkup:(NSString *)filename forConnection:(HTTPConnection *)connection {
	return [[self alloc] initWithContent:content andMarkup:filename forConnection:connection];
}

- (id) initWithContent:(AZErgoSubstitutioner *)subst andMarkup:(NSString *)filename forConnection:(HTTPConnection *)aConnection {
	if (!(self = [self initWithFilePath:filename forConnection:aConnection]))
		return self;

	substitutioner = subst;
	processor = [AZErgoTemplateProcessor new];

	return self;
}


- (BOOL)isChunked {
	HTTPLogTrace();
	return YES;
}

- (UInt64)contentLength {
	HTTPLogTrace();
	return 0;
}

- (void)setOffset:(UInt64)offset {
	HTTPLogTrace();
}

- (BOOL)isDone {
	BOOL result = (readOffset == fileLength) && (readBufferOffset == 0);

	HTTPLogTrace2(@"%@[%p]: isDone - %@", THIS_FILE, self, (result ? @"YES" : @"NO"));
	return result;
}

- (void)processReadBuffer {
	HTTPLogTrace();


	NSUInteger available = [processor processData:&readBuffer
															withSubstitutions:substitutioner
																		 withLength:&readBufferOffset
																	withMaxLength:&readBufferSize];

	if (readOffset == fileLength) {
		data = [[NSData alloc] initWithBytes:readBuffer length:readBufferOffset];
		readBufferOffset = 0;
	} else {
		data = [[NSData alloc] initWithBytes:readBuffer length:available];
		
		NSUInteger remaining = readBufferOffset - available;
		
		memmove(readBuffer, readBuffer + available, remaining);
		readBufferOffset = remaining;
	}
	
	[connection responseHasAvailableData:self];
}

- (void)dealloc {
	HTTPLogTrace();
}
@end