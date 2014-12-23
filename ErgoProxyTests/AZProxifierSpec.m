//
//  AZProxifierSpec.m
//  ErgoProxy
//  Spec for AZProxifier
//
//  Created by Ankh on 14.10.14.
//  Copyright (c) 2014 Ankh. All rights reserved.
//

#import "Kiwi.h"
#import "AZProxifier.h"
#import "AZStorage.h"

SPEC_BEGIN(AZProxifierSpec)

describe(@"AZProxifier", ^{
	it(@"should properly initialize", ^{
		AZProxifier *instance = [AZProxifier new];
		[[instance shouldNot] beNil];
		[[instance should] beKindOfClass:[AZProxifier class]];
	});

	it(@"should register storages", ^{
		AZProxifier *proxifier = [AZProxifier new];

		AZStorage *storage1 = [AZStorage new];
		AZStorage *storage2 = [AZStorage new];
		AZStorage *storage3 = [AZStorage new];

		[proxifier registerStorage:storage1];
		[proxifier registerStorage:storage3];
		[proxifier registerStorage:storage2];

		[[proxifier.storages should] haveCountOf:3];

		[[storage1.proxifier shouldNot] beNil];
		[[storage2.proxifier shouldNot] beNil];
		[[storage3.proxifier shouldNot] beNil];
		[[storage1.proxifier should] equal:proxifier];
		[[storage2.proxifier should] equal:proxifier];
		[[storage3.proxifier should] equal:proxifier];
	});

	it(@"should properly form urls for storages", ^{
		NSURL *url1 = [NSURL URLWithString:@"proxy1"];
		NSURL *url11= [NSURL URLWithString:@"http://proxy1.serv.er/"];

		NSURL *url6 = [NSURL URLWithString:@"proxy3-a.b"];
		NSURL *url61= [NSURL URLWithString:@"http://proxy3-a.b.serv.er/"];

		NSURL *url2 = [NSURL URLWithString:@"http://subdomen1.ser.ver/"];

		NSURL *url3 = [NSURL URLWithString:@"http://subdomen2.ser.ver/"];

		NSURL *url4 = [NSURL URLWithString:@"https://proxy2"];
		NSURL *url41= [NSURL URLWithString:@"https://proxy2.serv.er/"];

		NSURL *url5 = [NSURL URLWithString:@"https://proxy3-a.b"];
		NSURL *url51= [NSURL URLWithString:@"https://proxy3-a.b.serv.er/"];

		AZProxifier *proxifier = [AZProxifier serverWithURL:[NSURL URLWithString:@"http://serv.er/"]];

		AZStorage *storage1 = [AZStorage serverWithURL:url1];
		AZStorage *storage2 = [AZStorage serverWithURL:url2];
		AZStorage *storage3 = [AZStorage serverWithURL:url3];
		AZStorage *storage4 = [AZStorage serverWithURL:url4];
		AZStorage *storage5 = [AZStorage serverWithURL:url5];

		[proxifier registerStorage:storage1];
		[proxifier registerStorage:storage3];
		[proxifier registerStorage:storage2];
		[proxifier registerStorage:storage4];
		[proxifier registerStorage:storage5];

		[[[storage1 fullURL] shouldNot] beNil];
		[[[storage2 fullURL] shouldNot] beNil];
		[[[storage3 fullURL] shouldNot] beNil];
		[[[storage4 fullURL] shouldNot] beNil];
		[[[storage5 fullURL] shouldNot] beNil];

		[[[storage1 fullURL] should] equal:url11];
		[[[storage2 fullURL] should] equal:storage2.url];
		[[[storage3 fullURL] should] equal:storage3.url];
		[[[storage4 fullURL] should] equal:url41];
		[[[storage5 fullURL] should] equal:url51];

		[[[proxifier storageWithURL:url1] should] equal:storage1];
		[[[proxifier storageWithURL:url11] should] equal:storage1];
		[[[proxifier storageWithURL:url2] should] equal:storage2];
		[[[proxifier storageWithURL:url3] should] equal:storage3];
		[[[proxifier storageWithURL:url4] should] equal:storage4];
		[[[proxifier storageWithURL:url41] should] equal:storage4];
		[[[proxifier storageWithURL:url5] should] equal:storage5];
		[[[proxifier storageWithURL:url51] should] equal:storage5];

		AZStorage *storage6 = [proxifier storageWithURL:url6];
		[[[proxifier storageWithURL:url61] should] equal:storage6];

		[[@([@[storage1, storage2, storage3, storage4, storage5] containsObject:storage6]) should] beNo];

	});
});

SPEC_END
