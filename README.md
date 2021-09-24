# Weave

## What is Weave?
Weave is an open-source networking layer built on top of `NSURLSession`. Because of this, it’s fast and compatible into the future. But unlike `NSURLSession`, it avoids complex and nasty configuration and overhead that takes forever and is prone to errors.

Make your first request with WVRequest.

## Features
### Simplicity
Creating network requests in Weave is so simple. Here’s how to make a simple GET request to GitHub’s main page: `WVRequest(url: URL(string:"https://github.com")!)`. And the great news is more complex request aren’t much more complex to write.
### Images
Weave can automatically fetch images and cache them for you. Check out `WVImage` documentation. Insert link here
## Get Started
It’s easy to get started. Add this project as a Swift module.
