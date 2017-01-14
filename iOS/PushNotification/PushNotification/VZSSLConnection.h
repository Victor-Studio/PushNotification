//
//  VZSSLConnection.h
//  PushNotification
//
//  Created by VictorZhang on 03/01/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

void SSLConnection(const char * host, int port);
int connectWithCertificate(NSString * certificateFilePath, NSString * certificatePasswords);

int readPushData(NSMutableData *data, NSUInteger *length, NSString **completionMessage);
int writePushData(NSData *data, NSUInteger *length);
