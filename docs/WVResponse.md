# WVResponse
The response returned by a `WVRequest`.

## Properties
- `statusCode:Int?`: The status code, if the request succeeded.
- `data:Data?`:  The raw data received from the request.
- `success:Bool`: A shorthand of `statusCode == 200`.
- `string: String?`: The string value after parsing. Only exists on `WVStringResponse`.
- `json: any?`: The JSON after parsing. Only exists on `WVJSONResponse`. You can directly cast this to your expected JSON model. For example: 
```json
{
	"users":[
		{
			"id":"helloworld",
			"name":"Jackson Zamorano"
		}
	]
}
```
could be read as `response.json as! [String:[[String:String]]]`. This will be `nil` if nothing could be parsed.
