//
//  main.m
//  PushNotification
//
//  Created by VictorZhang on 03/01/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VZPushNotification.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSString *pwd = @"your certificate passwords";
        NSString *filepath = @"/Users/VictorZhang/Desktop/AppPushCertificates.p12";
        int result = connectToAPNs(PushTypeDistribution, filepath, pwd);
        
        if (result > 0) {
            VZPushNotificationEntity entity;
            entity.badge = 123;
            entity.message = "This message was sent by Mac OS X platform!";
            entity.sound = "default";
            entity.deviceToken = "dc67b56c eb5dd9f9 782c37fd cfdcca87 3b7bc77c 3b090ac4 c538e007 a2f23a24";
            push(entity);
        }
        
        
        
    }
    return 0;
}
