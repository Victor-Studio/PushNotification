//
//  VZPushNotification.m
//  PushNotification
//
//  Created by VictorZhang on 03/01/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "VZPushNotification.h"
#import "VZSSLConnection.h"

#define kSandboxPushHost "gateway.sandbox.push.apple.com"
#define kPushHost "gateway.push.apple.com"
#define kPushPort 2195



BOOL _addExpiration;

char * generatePayLoad(VZPushNotificationEntity entity);

NSData *dataWithType(NSData * _deviceToken, NSData * _payloadData, NSUInteger _identifier, NSUInteger _expirationStamp, NSUInteger _priority);

void appendTo(NSMutableData *buffer, NSUInteger identifier, const void *bytes, NSUInteger length);

NSData * dataWithDeviceToken(const char * _deviceToken);

NSString *filterHex(NSString *hex);

NSData *dataFromHex(NSString *hex);



int connectToAPNs(PushNotificationType pushType, NSString * certificateFilePath, NSString * certificatePasswords)
{
    if (pushType == PushTypeDevelopment) {
        SSLConnection(kSandboxPushHost, kPushPort);
    } else {
        SSLConnection(kPushHost, kPushPort);
    }
    return connectWithCertificate(certificateFilePath, certificatePasswords);
}

void push(VZPushNotificationEntity entity)
{
    NSData *_deviceToken = dataWithDeviceToken(entity.deviceToken);
    
    char * payloadStr = generatePayLoad(entity);
    NSData *_payLoad = [[NSString stringWithCString:payloadStr encoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    free(payloadStr);
    
    NSData *data = dataWithType(_deviceToken, _payLoad, 1, 0, 0);
    
    NSLog(@"len:%ld  \n %@", data.length, data);
    
    NSUInteger length = 0;
    writePushData(data, &length);

    sleep(3);
    
    NSMutableData *m_data = [NSMutableData dataWithLength:sizeof(uint8_t) * 2 + sizeof(uint32_t)];
    NSUInteger m_length = 0;
    NSString *completionMessage = @"";
    
    readPushData(m_data, &m_length, &completionMessage);
    NSLog(@"Your Push Notification have been pushed.");
    
}

char * generatePayLoad(VZPushNotificationEntity entity)
{
    char * payload = malloc(strlen(entity.message) + sizeof(entity.badge) + strlen(entity.sound));
    sprintf(payload, "{\"aps\":{\"alert\":\"%s\",\"badge\":%d,\"sound\":\"%s\"}}", entity.message, entity.badge, entity.sound);
    return payload;
}

NSData *dataWithType(NSData * _deviceToken, NSData * _payloadData, NSUInteger _identifier, NSUInteger _expirationStamp, NSUInteger _priority)
{
    NSMutableData *result = [[NSMutableData alloc] initWithLength:5];
    
    if (_deviceToken)
        appendTo(result, 1, _deviceToken.bytes, _deviceToken.length);
    if (_payloadData)
        appendTo(result, 2, _payloadData.bytes, _payloadData.length);
    
    uint32_t identifier = htonl(_identifier);
    uint32_t expires = htonl(_expirationStamp);
    uint8_t priority = _priority;
    if (_identifier)
        appendTo(result, 3, &identifier, 4);
    if (_addExpiration)
        appendTo(result, 4, &expires, 4);
    if (priority)
        appendTo(result, 5 , &priority, 1);
    
    uint8_t command = 2;
    [result replaceBytesInRange:NSMakeRange(0, 1) withBytes:&command];
    uint32_t length = htonl(result.length - 5);
    [result replaceBytesInRange:NSMakeRange(1, 4) withBytes:&length];
    
    return result;
}

void appendTo(NSMutableData *buffer, NSUInteger identifier, const void *bytes, NSUInteger length)
{
    uint8_t i = identifier;
    uint16_t l = htons(length);      //相当于那length * 256
    [buffer appendBytes:&i length:1];
    [buffer appendBytes:&l length:2];
    [buffer appendBytes:bytes length:length];
}

NSData * dataWithDeviceToken(const char * _deviceToken)
{
    NSString *dtoken = [NSString stringWithCString:_deviceToken encoding:NSUTF8StringEncoding];
    NSString *normal = filterHex(dtoken);
    NSString *trunk = normal.length >= 64 ? [normal substringToIndex:64] : nil;
    return dataFromHex(trunk);
}

NSString *filterHex(NSString *hex)
{
    hex = hex.lowercaseString;
    NSMutableString *result = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < hex.length; i++) {
        unichar c = [hex characterAtIndex:i];
        if ((c >= 'a' && c <= 'f') || (c >= '0' && c <= '9')) {
            [result appendString:[NSString stringWithCharacters:&c length:1]];
        }
    }
    return result;
}

NSData *dataFromHex(NSString *hex)
{
    NSMutableData *result = [[NSMutableData alloc] init];
    char buffer[3] = {'\0','\0','\0'};
    for (NSUInteger i = 0; i < hex.length / 2; i++) {
        buffer[0] = [hex characterAtIndex:i * 2];
        buffer[1] = [hex characterAtIndex:i * 2 + 1];
        unsigned char b = strtol(buffer, NULL, 16);
        [result appendBytes:&b length:1];
    }
    return result;
}


