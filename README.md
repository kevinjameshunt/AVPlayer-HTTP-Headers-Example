AVPlayerHTTPHeaders Example
===========================

A working example of how to augment and retrieve HTTP headers on requests made by the iOS AVPlayer using a reverse proxy server on the device. 

Overview
========

This sample application demonstrates how an application can inject additional HTTP headers into playlist and chunk requests made by the iOS AVPlayer while also retrieving the headers of the responses. This is particularly useful when debugging server issues, as adding additional headers can trigger the server to return additional diagnostic information in the requests. 

Unfortunately, there are currently no APIs available in iOS to get and set this header information for requests made by the AVPlayer. For normal requests, we can simply use NSMutableURLRequest and NSHTTPURLResponse, but there is no OFFICIAL way to do this according to Apple. 

There is a way to add additional headers using the undocumented options key, ```AVURLAssetHTTPHeaderFieldsKey``` when creating an AVURLAsset object, as shown below. However, It has been strongly warned online that Apple may reject applications that use this key, and I could find no official word on the Apple Developer forums on whether or not this would be accepted: 
```
AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:customUrl] options:@{@"AVURLAssetHTTPHeaderFieldsKey" : httpHeaders}];
```

The only alternative is to run a reverse proxy server on the device, allowing AVPlayer to pass requests through it, which are then intercepted, modified, sent to their original destination, and then examined when a response is returned. 

When a new playback session is started, the client instantiates and starts a local HTTP server on the device, running at http://localhost:8080. Any requests sent to this will allow the proxy to intercept the request, add any additional HTTP headers, then complete the request via the reverse proxy host on port 80, and finally return the response to the original request from the player. Any HTTP headers received in the response are passed along to the client for reporting/diagnostic purposes.

The flow is as follows:
* Client receives request to play content at http://someurl.com/some_manifest.m3u8
* Client starts the local HTTP server at http://localhost:8080 and passes it "someurl.com" as the reverse proxy host name
* Client creates the AVPlayer, passing it http://localhost:8080/some_manifest.m3u8 
* AVPlayer tries to start playback by making a network request to http://localhost:8080/some_manifest.m3u8, which is intercepted by the proxy
* Proxy reconstructs what should have been the original request using the reverse proxy host it was passed
* Proxy makes the external request to the server at http://someurl.com/some_manifest.m3u8 with the additional headers
* Proxy extracts the headers from the response and sends them to its listeners
* Proxy returns the data and headers from the request to http://someurl.com/some_manifest.m3u8 as the response to http://localhost:8080/some_manifest.m3u8
* AVPlayer uses this data to start playback

This process is repeated for any variant playlists and chunk URLs that are returned in the manifest. AVPlayer makes calls to http://localhost:8080/chunk_01.ts, and the proxy gets the actual data for it from http://someurl.com/chunk_01.ts, modifying and extracting the headers as it does so. 

Getting Started
===============
1. Download or checkout the latest release to your machine. 
2. In the root directory, run the following to download and install GCDWebServer:
```
$ pod install
```
3. Open AVPlayerHTTPHeaders.xcworkspace and run the target. 
4. Tap the Play button to start playback of the URL. The header information for each request made by the AVPlayer will be logged below the video. 

The GCDWebServer
================
I used the [GCDWebServer](https://github.com/swisspol/GCDWebServer) as the base for my reverse proxy because it was incredibly easy to set up and did precisely what I needed it to do. It is also apparently possible to use Mongoose, as has been done [here](https://github.com/masterjk/ios-avplayer-http-capture)
