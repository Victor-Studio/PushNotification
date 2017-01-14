//
//  VZPushNotification.h
//  PushNotification
//
//  Created by VictorZhang on 03/01/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//
/*

 Introduction
 https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html#//apple_ref/doc/uid/TP40008194-CH8-SW1
 
 Creating Remote Notification Payload
 https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html#//apple_ref/doc/uid/TP40008194-CH10-SW1
 
 
 Note That:
 1.For regular remote notifications, the maximum size is 4KB (4096 bytes)
 2.For Voice over Internet Protocol (VoIP) notifications, the maximum size is 5KB (5120 bytes)
 
 */


#import <Foundation/Foundation.h>

typedef enum {
    PushTypeDevelopment,
    PushTypeDistribution,
} PushNotificationType;


//{"aps":{"alert":"Testing message","badge":1,"sound":"default"}}
typedef struct  {
    const char * deviceToken;
    const char * message;
    const char * sound;
    int badge;
    
    int content_available;
} VZPushNotificationEntity;


int connectToAPNs(PushNotificationType pushType, NSString * certificateFilePath, NSString * certificatePasswords);

void push(VZPushNotificationEntity entity);

