#import <Foundation/Foundation.h>
#import <Security/Security.h>

// Hook vào app launch, wipe toàn bộ Keychain entries của Grok
__attribute__((constructor))
static void KeychainWipeOnLoad(void) {
    NSArray *secClasses = @[
        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecClassCertificate,
        (__bridge id)kSecClassKey,
        (__bridge id)kSecClassIdentity
    ];
    
    for (id secClass in secClasses) {
        NSDictionary *query = @{(__bridge id)kSecClass: secClass};
        SecItemDelete((__bridge CFDictionaryRef)query);
    }
    
    // Wipe NSUserDefaults cũng luôn
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
