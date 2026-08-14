#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// Hook NSURLSession để intercept StoreKit 2 receipt verification
// Trả về fake receipt Apple-format cho bất kỳ StoreKit 2 request nào

static IMP original_dataTaskWithRequest;

static id hooked_dataTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, id completionHandler) {
    NSString *url = request.URL.absoluteString;
    
    // Intercept Apple receipt verification endpoint
    if ([url containsString:@"buy.itunes.apple.com"] ||
        [url containsString:@"sandbox.itunes.apple.com"] ||
        [url containsString:@"apple.com/verifyReceipt"] ||
        [url containsString:@"apps.apple.com/account/subscriptions"]) {
        
        // Fake response — subscription active
        NSDictionary *fakeReceipt = @{
            @"status": @0,
            @"environment": @"Production",
            @"latest_receipt_info": @[@{
                @"product_id": @"com.xai.grok.supergrok.monthly",
                @"purchase_date_ms": @([[NSDate date] timeIntervalSince1970] * 1000),
                @"expires_date_ms": @(([[NSDate date] timeIntervalSince1970] + 30*24*3600) * 1000),
                @"in_app_ownership_type": @"PURCHASED",
                @"transaction_id": @"2000000000000001",
                @"original_transaction_id": @"2000000000000001",
                @"is_trial_period": @"false",
                @"subscription_group_identifier": @"12345678"
            }],
            @"receipt": @{
                @"bundle_id": @"com.xai.grok",
                @"in_app": @[@{
                    @"product_id": @"com.xai.grok.supergrok.monthly",
                    @"transaction_id": @"2000000000000001",
                    @"purchase_date_ms": @([[NSDate date] timeIntervalSince1970] * 1000),
                    @"expires_date_ms": @(([[NSDate date] timeIntervalSince1970] + 30*24*3600) * 1000)
                }]
            }
        };
        
        NSData *fakeData = [NSJSONSerialization dataWithJSONObject:fakeReceipt
                                                           options:0
                                                             error:nil];
        NSHTTPURLResponse *fakeResponse = [[NSHTTPURLResponse alloc]
            initWithURL:request.URL
             statusCode:200
            HTTPVersion:@"HTTP/1.1"
           headerFields:@{@"Content-Type": @"application/json"}];
        
        // Return fake data via completion handler
        dispatch_async(dispatch_get_main_queue(), ^{
            void (^handler)(NSData *, NSURLResponse *, NSError *) = completionHandler;
            if (handler) handler(fakeData, fakeResponse, nil);
        });
        
        // Return dummy task
        return [[NSURLSession sharedSession] dataTaskWithURL:request.URL];
    }
    
    // Pass through tất cả request khác
    return ((id(*)(id,SEL,NSURLRequest*,id))original_dataTaskWithRequest)(self, _cmd, request, completionHandler);
}

// Hook SKPaymentQueue cho StoreKit 1 fallback
@interface FallbackObserver : NSObject <SKPaymentTransactionObserver>
@end

#import <StoreKit/StoreKit.h>

@implementation FallbackObserver
- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *tx in transactions) {
        [queue finishTransaction:tx];
    }
}
@end

static FallbackObserver *_fallback;

__attribute__((constructor))
static void StoreKit2HookInit(void) {
    // Hook NSURLSession dataTaskWithRequest:completionHandler:
    Class sessionClass = [NSURLSession class];
    SEL targetSEL = @selector(dataTaskWithRequest:completionHandler:);
    
    Method originalMethod = class_getInstanceMethod(sessionClass, targetSEL);
    if (originalMethod) {
        original_dataTaskWithRequest = method_getImplementation(originalMethod);
        method_setImplementation(originalMethod, (IMP)hooked_dataTaskWithRequest);
    }
    
    // StoreKit 1 fallback
    _fallback = [[FallbackObserver alloc] init];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:_fallback];
}
