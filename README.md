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

For more details, linked to [here](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html#//apple_ref/doc/uid/TP40008194-CH8-SW1 "APNs").



## Introduction
Let me introduce the server end at first.
- Here is the simplest `payload` of a remote notification
```
{"aps":{"alert":"This is a message for testing APNs","badge":123,"sound":"default"}}
```

These lib should be referenced
```
using System;
using System.IO;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading;
```

- Reading the p12 file which is downloaded from [Apple Developer Website](https://developer.apple.com), the varieble certFilePath is your p12 certificate whole path and the varieble certPwd is the passphrase of certificate, code snippet below
```
X509Certificate2 cert = new X509Certificate2(certFilePath, certPwd);
X509CertificateCollection certificate = new X509CertificateCollection();
certificate.Add(cert);
```

- Then, create an instance of SslStream and handshake before passing host address and port, code snippet below
```
//For distribution mode, the host is gateway.push.apple.com    
//For development mode, the host is gateway.sandbox.push.apple.com
TcpClient client = new TcpClient("gateway.push.apple.com", 2195);

SslStream sslStream = new SslStream(client.GetStream(), false, new RemoteCertificateValidationCallback(ServerCertificateValidationCallback), null);

//The method AuthenticateAsClient() may cause an exception, so we need to try..catch.. it
try
{
    //Reference of SslStream 
    //https://msdn.microsoft.com/en-us/library/system.net.security.sslstream(v=vs.110).aspx?cs-save-lang=1&cs-lang=csharp#code-snippet-2

    sslStream.AuthenticateAsClient(_host, certificate, SslProtocols.Default, false);
}
catch (Exception e)
{
    Console.WriteLine("Exception Message: {0} ", e.Message);
    sslStream.Close();
}

//Obviously , this is a method of callback when handshaking
bool ServerCertificateValidationCallback(object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors)
{
    if (sslPolicyErrors == SslPolicyErrors.None)
    {
        Console.WriteLine("Specified Certificate is accepted.");
        return true;
    }
    Console.WriteLine("Certificate error : {0} ", sslPolicyErrors);
    return false;
}
```

- Push a remote notification before consisting of the Payload string
```
//This is definition of PushNotificationPayload of struct 
public struct PushNotificationPayload
{
    public string deviceToken;
    public string message;
    public string sound;
    public int badge;

    public string PushPayload()
    {
        return "{\"aps\":{\"alert\":\"" + message + "\",\"badge\":" + badge + ",\"sound\":\"" + sound + "\"}}";
    }
}

//We gave values to it to consisting of the payload content
PushNotificationPayload payload = new PushNotificationPayload();
payload.deviceToken = "dc67b56c eb5dd9f9 782c37fd cfdcca87 3b7bc77c 3b090ac4 c538e007 a2f23a24";
payload.badge = 56789;
payload.sound = "default";
payload.message = "This message was pushed by C# platform.";

//And then, calling Push() method to invoke it
public void Push(PushNotificationPayload payload)
{
    string payloadStr = payload.PushPayload();
    string deviceToken = payload.deviceToken;

    MemoryStream memoryStream = new MemoryStream();
    BinaryWriter writer = new BinaryWriter(memoryStream);

    writer.Write((byte)0); //The command
    writer.Write((byte)0); //The first byte of deviceId length (Big-endian first byte)
    writer.Write((byte)32); //The deviceId length (Big-endian second type)

    //Method of DataWithDeviceToken() , see source code in this repo.
    byte[] deviceTokenBytes = DataWithDeviceToken(deviceToken.ToUpper());
    writer.Write(deviceTokenBytes);

    writer.Write((byte)0); //The first byte of payload length (Big-endian first byte)
    writer.Write((byte)payloadStr.Length); //payload length (Big-endian second byte)

    byte[] bytes = Encoding.UTF8.GetBytes(payloadStr);
    writer.Write(bytes);
    writer.Flush();

    _sslStream.Write(memoryStream.ToArray());
    _sslStream.Flush();

    Thread.Sleep(3000);

    //Method of ReadMessage() , see source code in this repo.
    string result = ReadMessage(_sslStream);
    Console.WriteLine("server said: " + result);

    _sslStream.Close();
}
```


















