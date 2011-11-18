/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "PaymentQueue.h"
#import "PaymentTransaction.h"
#import "Payment.h"
#import "TiUtils.h"

#import <StoreKit/StoreKit.h>


@implementation PaymentQueue

-(id)initWithModuleProxy:(TiProxy*)module
{
    self = [super init];
	if (self != nil) {
		queue = [SKPaymentQueue defaultQueue];
		[queue addTransactionObserver:self];
        moduleProxy = module;
	}
	return self;
}

-(void)dealloc
{
	[queue removeTransactionObserver:self];
	[queue release];
	[super dealloc];
}


- (void)paymentQueue:(SKPaymentQueue *)q updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions) {
		PaymentTransaction* t = [[[PaymentTransaction alloc] _initWithPageContext:[moduleProxy pageContext] transaction:transaction] autorelease];
		NSDictionary* evt = [NSDictionary dictionaryWithObjectsAndKeys:t, @"transaction", [t state], @"state", nil];
		
        [moduleProxy fireEvent:@"transaction" withObject:evt];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue
 removedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions) {
		PaymentTransaction* t = [[[PaymentTransaction alloc] _initWithPageContext:[moduleProxy pageContext] transaction:transaction] autorelease];
		[moduleProxy fireEvent:@"removed" withObject:[NSDictionary dictionaryWithObject:t forKey:@"transaction"]];
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	[moduleProxy fireEvent:@"restoreFinished" withObject:nil];
}

#define SETOBJ(dict, obj, key) if(obj){[dict setObject:obj forKey:key];};

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	NSMutableDictionary* ret = [NSMutableDictionary dictionaryWithObjectsAndKeys:NUMINT(error.code), @"code",nil];
	SETOBJ(ret, error.domain, @"domain");
	SETOBJ(ret, error.helpAnchor, @"helpAnchor");
	SETOBJ(ret, error.localizedDescription, @"message");
	SETOBJ(ret, error.localizedDescription, @"localizedDescription");
	SETOBJ(ret, error.localizedFailureReason, @"localizedFailureReason");
	SETOBJ(ret, error.localizedRecoveryOptions, @"localizedRecoveryOptions");
	SETOBJ(ret, error.localizedRecoverySuggestion, @"localizedRecoverySuggestion");
	
	[moduleProxy fireEvent:@"restoreFailed" withObject:[NSDictionary dictionaryWithObjectsAndKeys:ret, @"error", nil]];
}


#pragma Public API

-(void)addPayment:(Payment*)payment
{
	[queue addPayment:payment.payment];
}

-(void)finishTransaction:(PaymentTransaction*) pt
{
	[queue finishTransaction:pt.transaction];
}

-(void)restoreCompletedTransactions
{
	[queue restoreCompletedTransactions];
}

@end
