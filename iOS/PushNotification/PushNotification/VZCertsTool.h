//
//  VZCertsTool.h
//  PushNotification
//
//  Created by VictorZhang on 03/01/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

id importPKCS12Data(NSString *filepath ,NSString *password);

NSString *securityErrorMessageString(OSStatus status);
