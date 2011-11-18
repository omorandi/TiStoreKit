/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import <StoreKit/StoreKit.h>
#import <TiProxy.h>
#import "Payment.h"
#import "PaymentTransaction.h"

@interface PaymentQueue : NSObject<SKPaymentTransactionObserver> {
	SKPaymentQueue* queue;
    TiProxy *moduleProxy;
}

-(id)initWithModuleProxy:(TiProxy*)module;


-(void)addPayment:(Payment*)payment;
-(void)finishTransaction:(PaymentTransaction*)pt;
-(void)restoreCompletedTransactions;

@end
