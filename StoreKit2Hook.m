#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static IMP original_dataTaskWithRequest;

static id hooked_dataTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, id completionHandler) {
    NSString *url = request.URL.absoluteString;
    
    if ([url containsString:@"buy.itunes.apple.com"] ||
        [url containsString:@"sandbox.itunes.apple.com"] ||
        [url containsString:@"apple.com/verifyReceipt"] ||
        [url containsString:@"apps.apple.com/account/subscriptions"]) {
        
        NSDictionary *fakeReceipt = @{
            @"status": @0,
            @"environment": @"Production",
            @"latest_receipt_info": @[@{
                @"product_id": @"com.xai.grok.supergrok.monthly",
                @"purchase_date_ms": @((long long)([[NSDate date] timeIntervalSince1970] * 1000)),
                @"expires_date_ms": @((long long)(([[NSDate date] timeIntervalSince1970] + 30*24*3600) * 1000)),
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
                    @"purchase_date_ms": @((long long)([[NSDate date] timeIntervalSince1970] * 1000)),
                    @"expires_date_ms": @((long long)(([[NSDate date] timeIntervalSince1970] + 30*24*3600) * 1000))
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            void (^handler)(NSData *, NSURLResponse *, NSError *) = completionHandler;
            if (handler) handler(fakeData, fakeResponse, nil);
        });
        
        return [[NSURLSession sharedSession] dataTaskWithURL:request.URL];
    }
    
    return ((id(*)(id,SEL,NSURLRequest*,id))original_dataTaskWithRequest)(self, _cmd, request, completionHandler);
}

__attribute__((constructor))
static void StoreKit2HookInit(void) {
    Class sessionClass = [NSURLSession class];
    SEL targetSEL = @selector(dataTaskWithRequest:completionHandler:);
    Method originalMethod = class_getInstanceMethod(sessionClass, targetSEL);
    if (originalMethod) {
        original_dataTaskWithRequest = method_getImplementation(originalMethod);
        method_setImplementation(originalMethod, (IMP)hooked_dataTaskWithRequest);
    }
}
