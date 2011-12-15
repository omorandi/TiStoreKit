/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "PaymentTransaction.h"
#import "Payment.h"

#import "TiBlob.h"
#import "TiUtils.h"
#import "ASIHTTPRequest.h"


@implementation PaymentTransaction
@synthesize transaction;

-(id)_initWithPageContext:(id<TiEvaluator>)context
			  transaction:(SKPaymentTransaction*)transaction_
{
    self = [super _initWithPageContext:context];
	if (self != nil) {
		transaction = [transaction_ retain];
	}
	return self;
}

-(void)dealloc
{
	RELEASE_TO_NIL(transaction);
	[super dealloc];
}

-(id)toString:(id)args
{
    NSString *receipt = @"unavailable";
    if ([transaction transactionReceipt]) 
    {
        receipt = [[NSString alloc] initWithData:[transaction transactionReceipt] encoding:NSUTF8StringEncoding];
        [receipt autorelease];
    }
    
    NSString *str = @"Transaction: {\n";
    str = [str stringByAppendingFormat:@"id: %@,\n", [transaction transactionIdentifier]];
    str = [str stringByAppendingFormat:@"state: %d,\n", [transaction transactionState]];
    str = [str stringByAppendingFormat:@"receipt: %@,\n", receipt];
    str = [str stringByAppendingFormat:@"date: %@,\n", [[transaction transactionDate] description]];
    if ([transaction error]) 
    {
        str = [str stringByAppendingFormat:@"error: %@\n", [[transaction error] localizedDescription]];
    }
    str = [str stringByAppendingString:@"}"];
    return str;
}



- (id)state
{
    return [NSNumber numberWithInt:transaction.transactionState];
}

#define SETOBJ(dict, obj, key) if(obj){[dict setObject:obj forKey:key];};

- (id)error
{
	if(transaction.error) {
		NSError* e = transaction.error;
		NSMutableDictionary* ret = [NSMutableDictionary dictionaryWithObjectsAndKeys:NUMINT(e.code), @"code",nil];
		SETOBJ(ret, e.domain, @"domain");
		SETOBJ(ret, e.helpAnchor, @"helpAnchor");
		SETOBJ(ret, e.localizedDescription, @"message");
		SETOBJ(ret, e.localizedDescription, @"localizedDescription");
		SETOBJ(ret, e.localizedFailureReason, @"localizedFailureReason");
		SETOBJ(ret, e.localizedRecoveryOptions, @"localizedRecoveryOptions");
		SETOBJ(ret, e.localizedRecoverySuggestion, @"localizedRecoverySuggestion");
		return ret;
	}
	else {
		return nil;
	}
}


-(id)originalTransaction
{
	PaymentTransaction *original = [[[PaymentTransaction alloc] _initWithPageContext:[self pageContext] transaction:transaction.originalTransaction] autorelease];
    return original;
}

-(id)payment
{
	return [[[Payment alloc] _initWithPageContext:[self pageContext] payment:transaction.payment] autorelease];
}

-(id)receipt
{
	return [[[TiBlob alloc] initWithData:[transaction transactionReceipt] mimetype:@"application/octet-stream"] autorelease];
}

-(NSString*)receiptBase64
{
    return [ASIHTTPRequest base64forData:[transaction transactionReceipt]];
}


-(id)date
{
	return [transaction transactionDate];
}

-(id)id
{
	return [transaction transactionIdentifier];
}


@end
