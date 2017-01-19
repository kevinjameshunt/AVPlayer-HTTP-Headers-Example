//
//  AVPlayerProxy.h
//  AVPlayerHTTPHeaders
//
//  Created by Kevin Hunt on 2017-01-16.
//  Copyright © 2017 Prophet Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * The local host name and port for the player proxy
 */
OBJC_EXTERN NSString * __nonnull const AVPlayerProxyLocalHost;

OBJC_EXTERN NSString * __nonnull const AVPlayerReverseProxyDidReceiveHeadersNotification;            /**< Notification sent when the proxy captures HTTP headers from a server response */

OBJC_EXTERN NSString * __nonnull const AVPlayerReverseProxyNotificationRequestURLKey;                 /**< NSString representing the URL of the request that was made */
OBJC_EXTERN NSString * __nonnull const AVPlayerReverseProxyNotificationHeadersKey;                   /**< NSDictionary containing all key/value pairs from the HTTP headers of the response */

/**
 * A wrapper for the GCD webserver used to inject and insepect HTTP headers AVPlayer requests and responses
 * By running playback through a local proxy, we can add and modify headers in requests for manifests/chunks, as well as extract headers from the responses and pass them to the client for reporting and diagnostic purposes
 *
 * The daemon is started with a local port, 8080, as well a reverse proxy host to forward to.
 * If a request is sent to http://localhost:8080, the proxy will intercept the request, add any additional HTTP headers, then complete the request via the reverse proxy host on port 80, and finally return the response to the original request from the player.
 * Any HTTP headers received in the response are passed along to its listeners.
 */
@interface AVPlayerReverseProxy : NSObject

/**
 * Starts the AVPlayer proxy server listening to localhost.
 * Any requests sent to "http://localhost:8080" will be passed to "http://<reverseProxyHost>:80"
 *
 * @param reverseProxyHost The remote host for the reverse proxy
 */
- (void)startPlayerProxyWithReverseProxyHost:(nonnull NSString *)reverseProxyHost;

/**
 Stops the AVPlayer proxy
 */
- (void)stopPlayerProxy;

/**
 * Will add additional HTTP Headers to the manifest/chunk requests if supported.
 * @param httpHeaders The HTTP Headers to add
 */
- (void)addHttpHeaders:(nonnull NSDictionary *)httpHeaders;

/**
 * Will remove additional HTTP Headers to the manifest/chunk requests if supported.
 * @param httpHeaders The HTTP Headers to remove
 */
- (void)removeHttpHeaders:(nonnull NSDictionary *)httpHeaders;

@end
