//
//  AVPlayerProxy.m
//  AVPlayerHTTPHeaders
//
//  Created by Kevin Hunt on 2017-01-16.
//  Copyright © 2017 Prophet Studios. All rights reserved.
//

#import "AVPlayerReverseProxy.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

NSString * __nonnull const AVPlayerProxyLocalHost = @"localhost:8080";

NSString *const AVPlayerReverseProxyDidReceiveHeadersNotification         = @"AVPlayerReverseProxyDidReceiveHeadersNotification";

NSString *const AVPlayerReverseProxyNotificationRequestURLKey             = @"AVPlayerReverseProxyNotificationRequestURLKey";
NSString *const AVPlayerReverseProxyNotificationHeadersKey                = @"AVPlayerReverseProxyNotificationHeadersKey";

@implementation AVPlayerReverseProxy {
    NSDictionary *_httpHeaders;
    GCDWebServer *_webServer;
}

- (instancetype)init {
    if (self = [super init]) {
        _httpHeaders = [[NSDictionary alloc] init];
    }
    return self;
}

- (void)startPlayerProxyWithReverseProxyHost:(nonnull NSString *)reverseProxyHost {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _webServer = [[GCDWebServer alloc] init];
        
        __weak NSDictionary *weakHeaders = _httpHeaders;
        __weak typeof(self) weakSelf = self;
        // Add a handler to respond to GET requests on any local URL
        [_webServer addDefaultHandlerForMethod:@"GET"
                                  requestClass:[GCDWebServerRequest class]
                                  processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                      
                                      // Process the request by sending it using the reverse proxy URL
                                      GCDWebServerResponse *response = [weakSelf sendRequest:request toHost:reverseProxyHost withHeaders:weakHeaders];
                                      return response;
                                  }];
        
        // Start server on port 8080
        [_webServer startWithPort:8080 bonjourName:nil];
    });
}
- (void)stopPlayerProxy {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webServer stop];
    });
}

- (void)addHttpHeaders:(NSDictionary*)httpHeaders {
    if (httpHeaders && [httpHeaders count] > 0) {
        NSMutableDictionary *mergeDict = [NSMutableDictionary dictionaryWithDictionary:_httpHeaders];
        [mergeDict addEntriesFromDictionary:httpHeaders];
        _httpHeaders = [NSDictionary dictionaryWithDictionary:mergeDict];
    }
}

- (void)removeHttpHeaders:(NSDictionary*)httpHeaders {
    if (httpHeaders && [httpHeaders count] > 0) {
        NSMutableDictionary *removeDict = [NSMutableDictionary dictionaryWithDictionary:_httpHeaders];
        [removeDict removeObjectsForKeys:[httpHeaders allKeys]];
        _httpHeaders = [NSDictionary dictionaryWithDictionary:removeDict];
    }
}

- (GCDWebServerResponse *)sendRequest:(GCDWebServerRequest *)request toHost:(NSString *)reverseProxyHost withHeaders:(NSDictionary *)headers {
    NSError *error = nil;
    NSHTTPURLResponse *urlResponse = nil;
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // Replace the local url with the reverse host to recreate the original url
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    NSString *customUrl = [request.URL.absoluteString stringByReplacingOccurrencesOfString:AVPlayerProxyLocalHost withString:reverseProxyHost];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:customUrl]];
    
    // Set the additional HTTP headers in the new request
    for (NSString *key in [headers allKeys]) {
        NSString *value = [headers valueForKey:key];
        [urlRequest setValue:value forHTTPHeaderField:key];
    }
    
    // Synchronously make the request
    NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&urlResponse error:&error];
    
    // Capture the header info
    NSDictionary *responseHeaders = urlResponse.allHeaderFields;
    NSString *contentType = [responseHeaders valueForKey:@"Content-Type"];
    
    // Post notification containing headers an corresponding URL
    NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  customUrl, AVPlayerReverseProxyNotificationRequestURLKey,
                                  responseHeaders,  AVPlayerReverseProxyNotificationHeadersKey,
                                  nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerReverseProxyDidReceiveHeadersNotification
                                                        object:nil
                                                      userInfo:userInfoDict];
    
    // Create the response to return back to the player
    GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithData:responseData contentType:contentType];
    
    return response;
}

@end
