# Weave
Simple Swift networking.
## What is Weave?
Weave is a open-source networking framework build on top of `NSURLSession`. Personally, I find `URLSession` to be clunky, so I wrote Weave. It's lightweight yet still has useful features. When designing Weave, I had three main goals:
1. Provide powerful features that weren't in any other framework/were way more complicated in other frameworks.
2. Provide simplicity in implementation and API.
3. Make it easy for developers to integrate and use in their own projects.
## Main Features
### Simple Syntax.
Creating a request is as simple as `WVRequest(url: URL(string:"https://github.com")!)`
### Parsing
Parsing is built-in to Weave. String, Data, and JSON is currently supported. Simply set `outputType: .json` in the constructor to recieve parsed results.
### Image Support
Let Weave auto~~matically~~magically manage images for you. Check out `WVImage` for an easy way to download and cache images locally.
### Extensible
It's easy to add custom functionality to Weave. Need a new parser? Simply subclass `WVResponse` and add parsing code in `WVRequest.start`.
### Fast
The reason Weave isn't very much code is because it's build right on top of the APIs native to Apple platforms - `URLSession`.
## Documentation
Documentation is available [here](https://hobbsome.github.io/weave/).
## Get Started & Installation
There are two main different ways to use Weave:
1. Build & maintain from source
2. Download framework
### Build and Integrate
1. To build, clone the entire project. 
2. Make sure you're working in a Xcode Workspace. 
3. Then, simply drag the .xcodeproj onto the File Browser in Xcode. 
4. Add `Weave` to the "Embedded Frameworks" section of your project's .xcodeproj.
5. Have fun!
### Download
1. Download the latest release.
2. Drag it into your .xcodeproj.
3. Add it to your "Embedded Frameworks" section in your project's .xcodeproj.
4. Have fun!
