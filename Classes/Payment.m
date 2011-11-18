/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "Payment.h"
#import "Product.h"
#import "TiUtils.h"

@implementation Payment

@synthesize payment;


-(id)_initWithPageContext:(id<TiEvaluator>)context payment:(SKPayment*)payment_
{
    self = [super _initWithPageContext:context];
	if (self != nil) {
		self.payment.productIdentifier = payment_.productIdentifier;
		self.payment.quantity = 1;
	}
	return self;
}

- (SKPayment*)payment
{
	if(payment==nil) {
		self.payment = [[[SKMutablePayment alloc] init] autorelease];
	}
	return [[payment retain] autorelease];
}

- (id)product
{
	return [[self.payment.productIdentifier retain] autorelease];
}

- (void)setProduct:(id)arg
{
	if ([arg isKindOfClass:[Product class]]) {
		self.payment.productIdentifier = [(Product*)arg id];
	}
	else {
		self.payment.productIdentifier = arg;
	}
}

- (id)quantity
{
	return NUMINT(self.payment.quantity);
}

- (void)setQuantity:(id)arg
{
	ENSURE_SINGLE_ARG(arg, NSNumber);
	self.payment.quantity = [TiUtils intValue:arg];
}


@end
