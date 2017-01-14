namespace PushNotification
{
    class Program
    {
        static void Main(string[] args)
        {
            string filepath = "C://AppPushCertificates.p12";
            string pwd = "your certificate passwords";
            PushNotification pushNotification = new PushNotification(PushNotificationType.Distribution, filepath, pwd);
            PushNotificationPayload payload = new PushNotificationPayload();
            payload.deviceToken = "dc67b56c eb5dd9f9 782c37fd cfdcca87 3b7bc77c 3b090ac4 c538e007 a2f23a24";
            payload.badge = 56789;
            payload.sound = "default";
            payload.message = "This message was pushed by C# platform.";
            pushNotification.Push(payload);

        }
    }
}
