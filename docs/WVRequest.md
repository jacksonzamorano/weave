# WVRequest
WVRequest is the class which you use to make HTTP requests.

## Constructor
Call `init` to create a new request object.
### Parameters
- `url: URL`: The URL to make the request to.
- `requestType: WVRequestType = .get`: The HTTP verb to use. The default is `.get`, but you can specify `.post, .patch, .put, or .delete`. If you need more, just make an extension to `WVRequestType`.
- `outputType:WVOutputType = .string`: The output format. Your options are `.raw`, which returns a `Data` blob, `.string`, which returns a `String`, or `.json`, which returns anything. See more on the Sending the Request section below.
- `timeoutInterval:TimeInterval = 10`: The time to wait before returning an error for a network request. Don’t change this unless it matters for your specific use case.
- `parameters:[String:Encodable] = [:]`: Body parameters to be sent in requests that support bodies.
- `headers:[String:String] = [:]`: Headers to be sent with the request.
- `username: String? = nil`: Used in conjunction with `password` to create Authorization.
- `password: String? = nil`: Both this and `username` must not be `nil` in order to send. This will override any Authorization value set in the `headers` parameter.
### Sending the Request
To send a request, call `start` on the request object you just created. There is only one argument, a completion handler: `(WVResponse)->Void`. To get the actual parsed data out of the response, first make sure the request itself succeeded by checking `response.success`. If successful, cast the response to a `WVJSONResponse` or `WVStringResponse`. This will only work if you’ve specified `.json` or `.string` for the `outputType` in the constructor. For more information, check out `WVResponse` Insert Link