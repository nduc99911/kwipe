#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>

// Wipe toàn bộ Keychain ngay khi app launch
__attribute__((constructor))
static void NukeKeychain(void) {
    NSArray *classes = @[
        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecClassCertificate,
        (__bridge id)kSecClassKey,
        (__bridge id)kSecClassIdentity
    ];
    for (id c in classes) {
        SecItemDelete((__bridge CFDictionaryRef)@{(__bridge id)kSecClass: c});
    }
    // Wipe UserDefaults của tất cả app (shared)
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Thoát ngay sau khi wipe xong
    exit(0);
}

int main(int argc, char *argv[]) {
    return 0;
}
