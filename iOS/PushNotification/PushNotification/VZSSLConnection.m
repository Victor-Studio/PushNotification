//
//  VZSSLConnection.m
//  PushNotification
//
//  Created by VictorZhang on 03/01/2017.
//  Copyright © 2017 Victor Studio. All rights reserved.
//

#import "VZSSLConnection.h"
#import "VZCertsTool.h"
#include <Security/SecureTransport.h>
#include <unistd.h>
#include <netdb.h>
#include <fcntl.h>

#define NWSSL_HANDSHAKE_TRY_COUNT 1 << 26


bool connectSocket();
bool connectSSLWithCertificate(NSString * certificateFilePath, NSString * certificatePasswords);
bool handshakeSSL();
void disconnect();

OSStatus VZSSLRead(SSLConnectionRef connection, void *data, size_t *length);
OSStatus VZSSLWrite(SSLConnectionRef connection, const void *data, size_t *length);


const char * _host;
int _port;
int _socket;
SSLContextRef _context;



void SSLConnection(const char * host, int port)
{
    _host = host;
    _port = port;
    _socket = -1;
}

int connectWithCertificate(NSString * certificateFilePath, NSString * certificatePasswords)
{
    disconnect();
    
    bool socket = connectSocket();
    if (!socket) {
        disconnect();
        return socket;
    }
    
    bool ssl = connectSSLWithCertificate(certificateFilePath, certificatePasswords);
    if (!ssl) {
        disconnect();
        return ssl;
    }
    
    bool handshake = handshakeSSL();
    if (!handshake) {
        disconnect();
        return handshake;
    }
    
    return true;
}

bool connectSocket()
{
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        printf("Socket creation failed!");
        return false;
    }
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(struct sockaddr_in));
    struct hostent *entr = gethostbyname(_host);
    if (!entr) {
        printf("Got socket host failed! \n");
        return false;
    }
    struct in_addr host;
    memcpy(&host, entr->h_addr, sizeof(struct in_addr));
    addr.sin_addr = host;
    addr.sin_port = htons((u_short)_port);
    addr.sin_family = AF_INET;
    int conn = connect(sock, (struct sockaddr *)&addr, sizeof(struct sockaddr_in));
    if (conn < 0) {
        printf("Connected to APNs failed! \n");
        return false;
    }
    int cntl = fcntl(sock, F_SETFL, O_NONBLOCK);
    if (cntl < 0) {
        printf("fcntl() function creation failed! \n");
        return false;
    }
    int set = 1, sopt = setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
    if (sopt < 0) {
        printf("setsockopt() function set failed! \n");
        return false;
    }
    _socket = sock;
    return true;
}

bool connectSSLWithCertificate(NSString * certificateFilePath, NSString * certificatePasswords)
{
    SSLContextRef context = SSLCreateContext(NULL, kSSLClientSide, kSSLStreamType);
    if (!context) {
        printf("SSLContextRef creation failed! \n");
        return false;
    }
    OSStatus setio = SSLSetIOFuncs(context, VZSSLRead, VZSSLWrite);
    if (setio != errSecSuccess) {
        printf("OSStatus set failed! \n");
        return false;
    }
    OSStatus setconn = SSLSetConnection(context, (SSLConnectionRef)(unsigned long)_socket);
    if (setconn != errSecSuccess) {
        printf("SSLSetConnection() function failed! \n");
        return false;
    }
    OSStatus setpeer = SSLSetPeerDomainName(context, _host, strlen(_host));
    if (setpeer != errSecSuccess) {
        printf("SSLSetPeerDomainName() function failed! \n");
        return false;
    }
    
    id certificate = importPKCS12Data(certificateFilePath, certificatePasswords);
    OSStatus setcert = SSLSetCertificate(context, (__bridge CFArrayRef)@[certificate]);
    if (setcert != errSecSuccess) {
        printf("SSLSetCertificate() function failed! \n");
        return false;
    }
    _context = context;
    return true;
}

bool handshakeSSL()
{
    OSStatus status = errSSLWouldBlock;
    for (int i = 0; i < NWSSL_HANDSHAKE_TRY_COUNT && status == errSSLWouldBlock; i++) {
        status = SSLHandshake(_context);
    }
    
    bool result = false;
    switch (status) {
        case errSecSuccess: {
            printf("SSLHandshake() success! \n");
            result = true;
        }
            break;
        case errSSLWouldBlock:
        case errSecIO:
        case errSecAuthFailed:
        case errSSLUnknownRootCert:
        case errSSLNoRootCert:
        case errSSLCertExpired:
        case errSSLXCertChainInvalid:
        case errSSLClientCertRequested:
        case errSSLServerAuthCompleted:
        case errSSLPeerCertExpired:
        case errSSLPeerCertRevoked:
        case errSSLPeerCertUnknown:
        case errSecInDarkWake:
        case errSSLClosedAbort: {
            printf("SSLHandshake failed! Failure code = %d \n", status);
            result = false;
        }
            break;
    }
    return result;
}

OSStatus VZSSLRead(SSLConnectionRef connection, void *data, size_t *length) {
    size_t leng = *length;
    *length = 0;
    size_t read = 0;
    ssize_t rcvd = 0;
    
    for(; read < leng; read += rcvd) {
        rcvd = recv((int)connection, (char *)data + read, leng - read, 0);
        if (rcvd <= 0) break;
    }
    *length = read;
    if (rcvd > 0 || !leng) {
        return errSecSuccess;
    }
    if (!rcvd) {
        return errSSLClosedGraceful;
    }
    switch (errno) {
        case EAGAIN: return errSSLWouldBlock;
        case ECONNRESET: return errSSLClosedAbort;
    }
    return errSecIO;
}

OSStatus VZSSLWrite(SSLConnectionRef connection, const void *data, size_t *length) {
    size_t leng = *length;
    *length = 0;
    size_t sent = 0;
    ssize_t wrtn = 0;
    for (; sent < leng; sent += wrtn) {
        wrtn = write((int)connection, (char *)data + sent, leng - sent);
        if (wrtn <= 0) break;
    }
    *length = sent;
    if (wrtn > 0 || !leng) {
        return errSecSuccess;
    }
    switch (errno) {
        case EAGAIN: return errSSLWouldBlock;
        case EPIPE: return errSSLClosedAbort;
    }
    return errSecIO;
}

int readPushData(NSMutableData *data, NSUInteger *length, NSString **completionMessage)
{
    *length = 0;
    size_t processed = 0;
    OSStatus status = SSLRead(_context, data.mutableBytes, data.length, &processed);
    *length = processed;
    *completionMessage = securityErrorMessageString(status);
    NSLog(@"%@", *completionMessage);
    return status;
}


int writePushData(NSData *data, NSUInteger *length)
{
    *length = 0;
    size_t processed = 0;
    OSStatus status = SSLWrite(_context, data.bytes, data.length, &processed);
    *length = processed;
    if (status == errSecSuccess) {
        NSLog(@"%@", securityErrorMessageString(status));
        return errSecSuccess;
    }
    return status;
}

void disconnect()
{
    if (_context) SSLClose(_context);
    if (_socket >= 0) close(_socket); _socket = -1;
    if (_context) CFRelease(_context); _context = NULL;
}

