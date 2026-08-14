#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>

@interface FakeSKObserver : NSObject <SKPaymentTransactionObserver>
@end

@implementation FakeSKObserver

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *tx in transactions) {
        if (tx.transactionState == SKPaymentTransactionStatePurchasing ||
            tx.transactionState == SKPaymentTransactionStateFailed) {
            Ivar stateVar = class_getInstanceVariable([tx class], "_transactionState");
            if (stateVar) {
                object_setIvar(tx, stateVar,
                    (id)(NSUInteger)SKPaymentTransactionStatePurchased);
            }
            [queue finishTransaction:tx];
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue
removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {}

- (void)paymentQueue:(SKPaymentQueue *)queue
restoreCompletedTransactionsFailedWithError:(NSError *)error {}

@end

static FakeSKObserver *_observer;

__attribute__((constructor))
static void FakeSKInit(void) {
    _observer = [[FakeSKObserver alloc] init];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:_observer];
}
