#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Stub đơn giản — không dùng StoreKit framework
// Chỉ giữ constructor để không crash khi inject
__attribute__((constructor))
static void FakeSKPaymentInit(void) {
    // StoreKit 1 fallback disabled — handled by StoreKit2Hook
    // Placeholder để ESign inject không lỗi
}
