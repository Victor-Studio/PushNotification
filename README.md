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
- Using the most simple code in C#/iOS , a newcomer can be able to understood
- In order to test your iOS app when you're an iOS developer
- In order to write the code of server end when you're an ASP.NET/C# developer

For more details, linked to [here](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html#//apple_ref/doc/uid/TP40008194-CH8-SW1 "APNs").



## Introduction
Let me introduce the server end(C#) at first.
- Here is the simplest `payload` of a remote notification
```
{"aps":{"alert":"This is a message for testing APNs","badge":123,"sound":"default"}}
```

These header files should be referenced
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



<br/>
<br/>
<br/>
<br/>
<br/>
<br/>

# PushNotification
使用最简单的方式通过APNs发送通知, 本库使用C#写的服务器端代码，C/Objective-C客户端代码

## APNs 概述
Apple推送通知服务，是一个稳健性和高效率性的远程通知，具有中心化的特性。APNs可以传送通知消息到iOS,WatchOS, tvOS 和macOS的设备。 在应用初始化启动时，会创建一个受信任的和加密的IP链接到APNs服务器。APNs发送通知是使用一个持久连接的方式。如果一个通知到达了用户的设备，但是应用没有启动，那么设备暂存通知，直到在合适的时间里相应的应用去处理它。

另外，APNs和你的应用需要用通知来交互，所以你必须配置你自己的服务器(公司的服务器)作为原始发送的通知的服务器，叫做provider, 这个provider需要做到如下几条
* 接收设备的device token和发送相关的通知到APNs,APNs会把相应的通知发送给具体的设备的具体应用
* 何时发送远程通知到用户设备上
* 构建JSON字典，该字典就是通知的payload, 用来描述通知的具体显示
* 发送正确的payload和device token到APNs服务器
* 通过持久的和安全的通道发送请求到APNs，使用HTTP/2网络协议

![Alt](/remote_notif_simple_2x.png "Title")


## 这个库可以做什么
- 提供最简单的方式发送远程通知到用户的设备，并且是C#写的
- 使用最简单的C#/Objective-C代码去编写，即时是新手也能很容易理解
- 如果你是一名iOS开发者，那么这个库很方便与与你的iOS测试
- 如果你是一名ASP.NET/C#开发者，那么这个库很方便的让你编写APNs服务器端代码

更多详情，请看 [这里](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html#//apple_ref/doc/uid/TP40008194-CH8-SW1 "APNs").



## 简介
服务器端代码（C#）
- 以下是一个最简单的payload远程通知
```
{"aps":{"alert":"This is a message for testing APNs","badge":123,"sound":"default"}}
```

这些头文件需要被引用
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

- 读取p12文件，从[Apple Developer Website](https://developer.apple.com)下载的，变量certFilePath是p12证书的完整路径，变量certPwd是证书密码，以下是调用代码：
```
X509Certificate2 cert = new X509Certificate2(certFilePath, certPwd);
X509CertificateCollection certificate = new X509CertificateCollection();
certificate.Add(cert);
```

- 然后，传递主机地址和端口，创建一个SslStream实例，并且握手，代码如下：
```
//发布模式, 主机地址是 gateway.push.apple.com    
//开发模式, 主机地址是 gateway.sandbox.push.apple.com
TcpClient client = new TcpClient("gateway.push.apple.com", 2195);

SslStream sslStream = new SslStream(client.GetStream(), false, new RemoteCertificateValidationCallback(ServerCertificateValidationCallback), null);

//方法AuthenticateAsClient()可能会引起异常，我们需要try..catch..起来
try
{
    //SslStream参考 
    //https://msdn.microsoft.com/en-us/library/system.net.security.sslstream(v=vs.110).aspx?cs-save-lang=1&cs-lang=csharp#code-snippet-2

    sslStream.AuthenticateAsClient(_host, certificate, SslProtocols.Default, false);
}
catch (Exception e)
{
    Console.WriteLine("Exception Message: {0} ", e.Message);
    sslStream.Close();
}

//这是握手后的回调
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

- 构建payload字符串，发送远程通知
```
//PushNotificationPayload是一个结构体的定义 
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

//把值赋给payload
PushNotificationPayload payload = new PushNotificationPayload();
payload.deviceToken = "dc67b56c eb5dd9f9 782c37fd cfdcca87 3b7bc77c 3b090ac4 c538e007 a2f23a24";
payload.badge = 56789;
payload.sound = "default";
payload.message = "This message was pushed by C# platform.";

//然后调用Push()方法
public void Push(PushNotificationPayload payload)
{
    string payloadStr = payload.PushPayload();
    string deviceToken = payload.deviceToken;

    MemoryStream memoryStream = new MemoryStream();
    BinaryWriter writer = new BinaryWriter(memoryStream);

    writer.Write((byte)0); //The command
    writer.Write((byte)0); //deviceId长度的第一个字节，大头字节序第一个字节
    writer.Write((byte)32); //deviceId长度，大头字节序第二个字节

    //方法DataWithDeviceToken() , 具体看源码
    byte[] deviceTokenBytes = DataWithDeviceToken(deviceToken.ToUpper());
    writer.Write(deviceTokenBytes);

    writer.Write((byte)0); //payload的长度的第一个字节，大头字节序的第一个字节
    writer.Write((byte)payloadStr.Length); //payload的长度，大头字节序的第二个字节

    byte[] bytes = Encoding.UTF8.GetBytes(payloadStr);
    writer.Write(bytes);
    writer.Flush();

    _sslStream.Write(memoryStream.ToArray());
    _sslStream.Flush();

    Thread.Sleep(3000);

    //方法ReadMessage() , 具体看本库的源码
    string result = ReadMessage(_sslStream);
    Console.WriteLine("server said: " + result);

    _sslStream.Close();
}
```




























