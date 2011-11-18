/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiProxy.h"
#import <StoreKit/StoreKit.h>

@interface Payment : TiProxy {
	
@private
	SKMutablePayment* payment;
}
@property (nonatomic, retain) SKMutablePayment* payment;

-(id)_initWithPageContext:(id<TiEvaluator>)context payment:(SKPayment*)payment_;

- (id)product;
- (void)setProduct:(id)arg;
- (id)quantity;
- (void)setQuantity:(id)arg;


@end
