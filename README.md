# PushNotification
A simplest way to push notification on your own server in C# and C/Objective-C.


## APNs Overview
Apple Push Notification service (APNs) is the centerpiece of the remote notifications feature. It is a robust and highly efficient service for propagating information to iOS (and, indirectly, WatchOS), tvOS, and macOS devices. On initial launch, your app establishes an accredited and encrypted IP connection with APNs from the user's device. Over time, APNs delivers notifications using this persistent connection. If a notification arrives when your app is not running. the device receives the notification and handles its delivery to your app at an appropriate time.


In addition to APNs and your app, another piece is required for the delivery of remote notifications. You must configure your own server to originate those notifications. Your server, known as the provider, has the following responsibilities:
* It receives device tokens and relevant data from your app.
* It determines when remote notifications need to be sent to a device.
* It communicates the notification data to APNs, which then handles the delivery of the notifications to that device.

For each remote notification, your provider:
* Constructs a JSON dictionary with the notification’s payload; described in the Remote Notification Payload.
* Attaches the payload and an appropriate device token to an HTTP/2 request.
* Sends the request to APNs over a persistent and secure channel that uses the HTTP/2 network protocol.


![Alt](/remote_notif_simple_2x.png "Title")


## What can this repository do?
- Provide the simplest way to send remote notification to user's device in C#
- Using the most simple code in C#/iOS that a newcomer be able to understood
- In order to test your iOS app when you're an iOS developer

For more details, linked [here](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html#//apple_ref/doc/uid/TP40008194-CH8-SW1 "APNs").









