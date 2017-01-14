using System;
using System.IO;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading;

namespace PushNotification
{

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

    public enum PushNotificationType
    {
        Development,
        Distribution
    }

    public class PushNotification
    {
        const string kSandboxPushHost = "gateway.sandbox.push.apple.com";
        const string kPushHost = "gateway.push.apple.com";
        const int kPushPort = 2195;
        
        private SslStream _sslStream = null;
        
        public PushNotification(PushNotificationType notificationType, string certFilePath, string certPwd)
        {
            //Reference 
            //https://msdn.microsoft.com/en-us/library/system.net.security.sslstream(v=vs.110).aspx?cs-save-lang=1&cs-lang=csharp#code-snippet-2

            string _host = "";
            int _port = 0;
            if (notificationType == PushNotificationType.Development)
            {
                _host = kSandboxPushHost;
                _port = kPushPort;
            }
            else
            {
                _host = kPushHost;
                _port = kPushPort;
            }

            TcpClient client = new TcpClient(_host, _port);
            X509Certificate2 cert = new X509Certificate2(certFilePath, certPwd);
            X509CertificateCollection certificate = new X509CertificateCollection();
            certificate.Add(cert);

            _sslStream = new SslStream(client.GetStream(), false, new RemoteCertificateValidationCallback(ServerCertificateValidationCallback), null);
            try
            {
                /*
                 When the authentication process, also known as the SSL handshake, succeeds, 
                 the identity of the server (and optionally, the client) is established and the SslStream can be used by the client and server 
                 to exchange messages. Before sending or receiving information, the client and server should check the security services 
                 and levels provided by the SslStream to determine whether the protocol, algorithms, and strengths selected meet their 
                 requirements for integrity and confidentiality.
                 */
                _sslStream.AuthenticateAsClient(_host, certificate, SslProtocols.Default, false);

            }
            catch (Exception e)
            {
                Console.WriteLine("Exception Message: {0} ", e.Message);
                _sslStream.Close();
            }
        }

        public void Push(PushNotificationPayload payload)
        {
            string payloadStr = payload.PushPayload();
            string deviceToken = payload.deviceToken;

            MemoryStream memoryStream = new MemoryStream();
            BinaryWriter writer = new BinaryWriter(memoryStream);

            writer.Write((byte)0); //The command
            writer.Write((byte)0); //The first byte of deviceId length (Big-endian first byte)
            writer.Write((byte)32); //The deviceId length (Big-endian second type)

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

            string result = ReadMessage(_sslStream);
            Console.WriteLine("server said: " + result);

            _sslStream.Close();
        }

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

        string ReadMessage(SslStream sslStream)
        {

            byte[] buffer = new byte[2048];
            StringBuilder messages = new StringBuilder();
            int bytes = -1;
            do
            {
                bytes = sslStream.Read(buffer, 0, buffer.Length);

                Decoder decoder = Encoding.UTF8.GetDecoder();
                char[] chars = new char[decoder.GetCharCount(buffer, 0, bytes)];
                decoder.GetChars(buffer, 0, bytes, chars, 0);
                messages.Append(chars);

                if (messages.ToString().IndexOf("<EOF>") != -1)
                {
                    break;
                }
            } while (bytes != 0);

            return messages.ToString();
        }

        byte[] DataWithDeviceToken(string deviceToken)
        {
            string normal = FilterHex(deviceToken);
            string trunk = normal.Length >= 64 ? normal.Substring(0, 64) : "";

            UTF8Encoding utf8 = new UTF8Encoding();
            byte[] utf8bytes = utf8.GetBytes(trunk);
            char[] chars = utf8.GetString(utf8bytes).ToCharArray();

            byte[] bytes = new byte[chars.Length / 2];

            string buffer;
            for (int i = 0; i < chars.Length / 2; i++)
            {
                buffer = Convert.ToString(chars[i * 2]) + Convert.ToString(chars[i * 2 + 1]);
                long b = Convert.ToInt64(buffer.ToString(), 16);
                bytes[i] = Convert.ToByte(b);
            }
            return bytes;
        }

        string FilterHex(string originalStr)
        {
            char[] lowerStr = originalStr.ToLower().ToCharArray();
            StringBuilder result = new StringBuilder();
            for (int i = 0; i < lowerStr.Length; i++)
            {
                if ((lowerStr[i] >= 'a' && lowerStr[i] <= 'f') || (lowerStr[i] >= '0' && lowerStr[i] <= '9'))
                {
                    result.Append(lowerStr[i]);
                }
            }
            return result.ToString();
        }

    }
}
