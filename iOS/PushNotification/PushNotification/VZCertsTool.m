//
//  VZCertsTool.m
//  PushNotification
//
//  Created by VictorZhang on 03/01/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "VZCertsTool.h"

//id certificateWithIdentity(id identity)
//{
//    SecCertificateRef cert = NULL;
//    OSStatus status = identity ? SecIdentityCopyCertificate((__bridge SecIdentityRef)identity, &cert) : errSecParam;
//    id certificate = CFBridgingRelease(cert);
//    if (status != errSecSuccess || !cert) {
//        NSLog(@"%@", securityErrorMessageString(status));
//    }
//    return certificate;
//}

id importPKCS12Data(NSString *filepath ,NSString *password)
{
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    NSDictionary *options = @{(__bridge id)kSecImportExportPassphrase: password};
    CFArrayRef items = NULL;
    OSStatus status = data ? SecPKCS12Import((__bridge CFDataRef)data, (__bridge CFDictionaryRef)options, &items) : errSecParam;
    NSArray *dicts = CFBridgingRelease(items);
    if (status != errSecSuccess || !items) {
        NSLog(@"%@", securityErrorMessageString(status));
    }
    
    id identity = nil;
    for (NSDictionary *dict in dicts) {
        identity = dict[(__bridge id)kSecImportItemIdentity];
        break;
    }
    return identity;
}

NSString *securityErrorMessageString(OSStatus status)
{
    return (__bridge_transfer NSString *)SecCopyErrorMessageString(status, NULL);
};


