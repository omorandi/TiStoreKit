/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "Product.h"

#import "TiUtils.h"

@implementation Product

-(id)_initWithPageContext:(id<TiEvaluator>)context
			  product:(SKProduct*)product_
{	
    self = [super _initWithPageContext:context];
	if (self != nil) {
		product = [product_ retain];
	}
	return self;
}

-(void)dealloc
{
	[product release];
	[super dealloc];
}

-(id)id
{
	return [[[product productIdentifier] retain] autorelease];
}

-(id)description
{
	return [[[product localizedDescription] retain] autorelease];
}

-(id)price
{
	return [[[product price] retain] autorelease];
}

-(id)title
{
	return [[[product localizedTitle] retain] autorelease];
}

-(id)priceLocale
{
	return [[[[product priceLocale] localeIdentifier] retain] autorelease];
}


@end
