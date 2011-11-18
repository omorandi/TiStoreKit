/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "JpMasuidriveTiStorekitModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

#import "Payment.h"
#import "PaymentTransaction.h"
#import "Product.h"
#import "ASIHTTPRequest.h"
#import "SBJSON.h"

@implementation JpMasuidriveTiStorekitModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"b0c990ec-bb25-4627-9994-1f11f5076375";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"jp.masuidrive.ti.storekit";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	productRequestCallback = [NSMutableArray array];
	defaultPaymentQueue = [[PaymentQueue alloc] initWithModuleProxy:self];
    
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
	[defaultPaymentQueue release];
	[productRequestCallback release];
    [eventQueues dealloc];
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}



-(NSMutableDictionary*)eventQueues
{
    if (eventQueues == nil)
    {
        eventQueues = [[NSMutableDictionary alloc] init];
    }
    return eventQueues;
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
    //once a listener is added, if we have events in the queue we fire them immediately
    NSMutableArray *queue = [[self eventQueues] objectForKey:type];
    if (queue == nil)
        return;
    
    while ([queue count] > 0)
    {
        id obj = [queue objectAtIndex:0];
        [super fireEvent:type withObject:obj];
        [queue removeObjectAtIndex:0];
    }
}

-(void)queueEvent:(NSString *)type withObject:(id)obj
{
    NSMutableArray *queue = [[self eventQueues] objectForKey:type];
    if (queue == nil)
    {
        queue = [[[NSMutableArray alloc] init] autorelease];
        [[self eventQueues] setObject:queue forKey:type];
    }
    [queue addObject:obj];
}


-(void)fireEvent:(NSString *)type withObject:(id)obj
{
    if (![self _hasListeners:type])
    {
        [self queueEvent:type withObject:obj];
    }
    else
    {
        [super fireEvent:type withObject:obj];
    }
}


MAKE_SYSTEM_PROP(PURCHASING, SKPaymentTransactionStatePurchasing);
MAKE_SYSTEM_PROP(PURCHASED, SKPaymentTransactionStatePurchased);
MAKE_SYSTEM_PROP(FAILED, SKPaymentTransactionStateFailed);
MAKE_SYSTEM_PROP(RESTORED, SKPaymentTransactionStateRestored);


#pragma mark Delegates

- (void)productsRequest:(SKProductsRequest *)request
	 didReceiveResponse:(SKProductsResponse *)response
{
	KrollCallback* callback = nil;
	for(NSArray* line in productRequestCallback) {
		if([line objectAtIndex:0] == request) {
			callback = [[[line objectAtIndex:1] retain] autorelease];
			[productRequestCallback removeObject:line];
			break;
		}
	}
	if(callback) {	   
		NSMutableArray* products = [NSMutableArray array];
		for(SKProduct* product in response.products) {
			[products addObject:[[Product alloc] _initWithPageContext:[self pageContext] product:product]];
		}
        
        NSDictionary *evt = [NSDictionary dictionaryWithObjectsAndKeys:products, @"products", response.invalidProductIdentifiers, @"invalid", nil];
        [self _fireEventToListener:@"productRequestFinished"
						withObject:evt
                        listener:callback 
						thisObject:nil];
	}
}

#pragma Public APIs

-(id)canMakePayments
{
	return NUMBOOL([SKPaymentQueue canMakePayments]);
}


-(void)findProducts:(id)args
{
	ENSURE_ARG_COUNT(args, 2);
	id arg0 = [args objectAtIndex:0];
	NSSet* productIds = nil;
	if([arg0 isKindOfClass:[NSString class]]) {
		productIds = [NSSet setWithObject:arg0];
	}
	else if([arg0 isKindOfClass:[NSArray class]]) {
		productIds = [NSSet setWithArray:arg0];
	}
	else {
		[self throwException:TiExceptionInvalidType subreason:[NSString stringWithFormat:@"expected: Array or Stinrg, was: %@",[arg0 class]] location:CODELOCATION]; \
	}
	
	id callback = [args objectAtIndex:1];
	ENSURE_TYPE(callback, KrollCallback);
	SKProductsRequest *req = [[[SKProductsRequest alloc] initWithProductIdentifiers:productIds] autorelease];
	req.delegate = self;
	[req start];
	[productRequestCallback addObject:[NSArray arrayWithObjects: req, callback, nil]];
}

-(void)purchase:(id)args
{
    //args is the product id
    ENSURE_SINGLE_ARG(args, Product);
    Payment *payment = [[[Payment alloc] _initWithPageContext:[self executionContext]] autorelease];
    [payment setProduct:args];
    [defaultPaymentQueue addPayment:payment];
}

-(void)finalizeTransaction:(id)args
{
    ENSURE_SINGLE_ARG(args, PaymentTransaction);
    [defaultPaymentQueue finishTransaction:args];
}

-(void)restoreCompletedTransactions:(id)args
{
	[defaultPaymentQueue restoreCompletedTransactions];
}

-(void)verifyReceipt:(id)args
{
    /*
        receipt[blob]: A receipt returned from the transaction event callback as transaction.receipt.
        callback[function]: A function to be called when the verification request completes.
        sandbox[bool, defaults to false]: Whether or not to use Apple's Sandbox verification server.
        sharedSecret[string, optional]: The shared secret for your app that you creates in iTunesConnect; required for verifying auto-renewable subscriptions.
     */
    
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    id receipt = [args objectForKey:@"receipt"];
    ENSURE_TYPE(receipt, TiBlob);
    
    id callback = [args objectForKey:@"callback"];
    ENSURE_TYPE(callback, KrollCallback);
    
    BOOL sandbox = [TiUtils boolValue:[args objectForKey:@"sandbox"] def:NO];
    
    id sharedSecret = [TiUtils stringValue:[args objectForKey:@"sharedSecret"]];

    NSString *storeUrl = [NSString stringWithFormat:@"https://%@.itunes.apple.com/verifyReceipt", (sandbox?@"sandbox":@"buy")];
    
    NSURL *url = [NSURL URLWithString:storeUrl];
    
    NSString *encodedReceipt = [ASIHTTPRequest base64forData:[receipt data]];
    
    NSString *jsonData = @"{";
    jsonData = [jsonData stringByAppendingFormat:@"\"receipt-data\":\"%@\"", encodedReceipt];
    if (sharedSecret != nil) 
    {
        jsonData = [jsonData stringByAppendingFormat:@",\"password\":\"%@\"", sharedSecret];
    }
    jsonData = [jsonData stringByAppendingString:@"}"];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request appendPostData:[jsonData dataUsingEncoding:NSUTF8StringEncoding]];
    [request setRequestMethod:@"POST"];
    
    [request setCompletionBlock:^{
        // Use when fetching text data
        NSString *responseString = [request responseString];
        //NSLog(@"[INFO] Receipt verify received response: %@", responseString);
        NSDictionary *evt = nil;
        if ([request responseStatusCode] == 200) {
            SBJSON *json = [[[SBJSON alloc] init] autorelease];
            id jsonObject = [json fragmentWithString:responseString error:nil];        
            evt = [NSDictionary dictionaryWithObjectsAndKeys:jsonObject, @"result", [NSNumber numberWithInt:YES], @"success", nil];
        }
        else
        {
            evt = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NO], @"success", [request responseStatusMessage], @"error", nil];
        }
        [self _fireEventToListener:@"verificationComplete"
						withObject:evt
                          listener:callback 
						thisObject:nil];
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        //NSLog(@"[ERROR] Receipt verify error: %@", error);
        NSDictionary *evt = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NO], @"success", error, @"error", nil];
        [self _fireEventToListener:@"verificationComplete"
						withObject:evt
                          listener:callback 
						thisObject:nil];
        
    }];
    [request startAsynchronous];

}


@end
