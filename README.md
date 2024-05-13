![alt [version]](https://img.shields.io/github/v/release/neothXT/Snowdrop) ![alt spm available](https://img.shields.io/badge/SPM-available-green) ![alt cocoapods available](https://img.shields.io/badge/CocoaPods-unavailable-red) ![alt carthage unavailable](https://img.shields.io/badge/Carthage-unavailable-red)

# Snowdrop

Meet Snowdrop - type-safe, easy to use framework powered by Swift Macros created to let you build and maintain complex network requests with ease.

## Navigation

- [Installation](#installation)
- [Key Functionalities](#key-functionalities)
- [Basic Usage](#basic-usage)
    - [Service Declaration](#service-declaration)
    - [Request Execution](#request-execution)
- [Advanced Usage](#advanced-usage)
    - [Configuration](#configuration)
        - [Default JSON Decoder](#default-json-decoder)
        - [SSL/Certificate Pinning](#sslcertificate-pinning)
    - [Body Argument](#body-argument)
    - [File Upload](#file-upload)
    - [Query Parameters](#query-parameters)
    - [Arguments' Default Values](#arguments-default-values)
    - [Interceptors](#interceptors)
    - [Mockable](#mockable)
- [Acknowledgements](#acknowledgements)

## Installation

Snowdrop is available via SPM. It works with iOS Deployment Target has to be 14.0 or newer. If you code for macOS, your Deployment Target has to be 11 or newer.

## Key Functionalities

- Type-safe service creation with `@Service` macro
- Support for various request method types such as
    - `@GET`
    - `@POST`
    - `@PUT`
    - `@DELETE`
    - `@PATCH`
    - `@CONNECT`
    - `@HEAD`
    - `@OPTIONS`
    - `@QUERY`
    - `@TRACE`
- SSL/Certificate pinning
- Interceptors
- Mockable

## Basic Usage

### Service Declaration

Creating network services with Snowdrop is really easy. Just declare a protocol along with its functions. 

```Swift
@Service
protocol MyEndpoint {

    @GET(url: "/posts")
    @Headers(["X-DeviceID": "testSim001"])
    func getAllPosts() async throws -> [Post]
}
```

If your request includes some dynamic values, such as `id`, you can add it to your path wrapping it with `{}`. Snowdrop will automatically bind your function declaration's arguments with those you include in request's path.

```Swift
@GET(url: "/posts/{id}")
func getPost(id: Int) async throws -> Post
```

### Request Execution

Upon expanding macros, Snowdrop creates a class `MyEndpointService` which implements `MyEndpoint` protocol and generates all the functions you declared.

```Swift
class MyEndpointService: MyEndpoint {
    func getAllPosts() async throws -> [Post] {
        // auto-generated body
    }
    
    func getPost(id: Int) async throws -> Post {
        // auto-generated body
    }
}
```

To send requests, just initialize `MyEndpointService` instance and call function corresponding to the request you want to execute.

```Swift
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!)
let post = try await getPost(id: 7)
```

## Advanced Usage

### Configuration

Snowdrop's config allows you to set/change framework's global settings.

### Default JSON Decoder

If you need to change default json decoder, you can set your own decoder to `Snowdrop.Config.defaultJSONDecoder`.

#### SSL/Certificate Pinning

To enable SSL/Certificate Pinning all you need to do is to include your certificate in the project.
Then, if you want to exclude some URLs from SSL/Certificate pinning, add them to `Snowdrop.Config.urlsExcludedFromPinning`.

### Body Argument

If you want to put some encodable object as a body of your request, you can either put it in your declaration as "body" argument or - if you want to use another name - use `@Body` macro like:

```Swift
@POST(url: "/posts")
@Body("model")
func addPost(model: Post) async throws -> Data
```

### File Upload

If you want to declare service's function that sends some file to the server as `multipart/form-data`, use `@FileUpload` macro. It'll automatically add `Content-Type: multipart/form-data` to the request's headers and extend the list of your function's arguments with `_payloadDescription: PayloadDescription` which you should then use to provide information such as `name`, `fileName` and `mimeType`.
For mime types such as jpeg, png, gif, tiff, pdf, vnd, plain, octetStream, you don't have to provide `PayloadDescription`. Snowdrop can automatically recognize them and create `PayloadDescription` for you.

```Swift
@Service
protocol MyEndpoint {

    @FileUpload
    @Body("image")
    @POST(url: "/uploadAvatar/")
    func uploadImage(_ image: UIImage) async throws -> Data
}

let payload = PayloadDescription(name: "avatar", fileName: "filename.jpeg", mimeType: "image/jpeg")
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!)
_ = try await service.uploadImage(someImage, _payloadDescription: payload)
```

### Query Parameters

Upon expanding macros, Snowdrop adds argument `_queryItems: [QueryItem]` to every service's function. For dynamic query parameters it's recommended to pass them using this argument like:

```Swift
@Service
protocol MyEndpoint {

    @GET(url: "/posts/{id}")
    func getPost(id: Int) async throws -> Post
}

let authorName = "John Smith"
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!)
let post = try await service.getPost(id: 7, _queryItems: [.init(key: "author", value: authorName)])
```

### Arguments' Default Values

Snowdrop allows you to define custom values for your arguments. Let's say your path includes `{id}` argument. As you already know by now, Snowdrop automatically associates it with `id` argument of your `func` declaration. If you want it to have default value equal "3", do it like: `{id=3}`. Be careful though as Snowdrop won't check if your default value's type conforms to the declaration.  
When inserting `String` default values such as {name="Some name"}, it is strongly recommended to use `Raw String` like `@GET(url: #"/authors/{name="John Smith"}"#)`.

### Interceptors

Each service provides two methods to add interception blocks - `addBeforeSendingBlock` and `addOnResponseBlock`. Both accept arguments such as `path` of type `String` and `block` which is closure.

To add `addBeforeSendingBlock` or `addOnResponseBlock` for a request with pathVariables, you should use path pattern. That means, regardless if your path is like "my/path/{id}/content" or "my/path/{id=4}/content" - you should provide it like:

```Swift
service.addBeforeSendingBlock(for: "my/path/{id}/content") { urlRequest in
    // some operations
    return urlRequest
}
```

To add `addBeforeSendingBlock` or `addOnResponseBlock` for ALL requests, do it like:

```Swift
service.addOnResponseBlock { data, httpUrlResponse in
    // some operations
    return data
}
```

Note that if you add interception block for a certain request path, general interceptors will be ignored.

### Mockable

If you'd like to create mockable version of your service, Snowdrop got you covered. Just add `@Mockable` macro to your service declaration like

```Swift
@Service
@Mockable
protocol Endpoint {
    @Get("/path")
    func getPosts() async throws -> [Posts]
}
```

Snowdrop will automatically create a `EndpointServiceMock` class with all the properties `Service` should have and additional properties such as `getPostsResult` to which you can assign value that should be returned.

#### Sample usage:

```Swift
func testEmptyArrayResult() async throws {
let mock = EndpointServiceMock(baseUrl: URL(string: "https://some.url")!
mock.getPostsResult = .success([])

let result = try await mock.getPosts()

XCTAssertTrue(result.isEmpty)
```

Note that mocked methods will directly return stubbed result without accessing Snowdrop.Core so your beforeSend and onResponse blocks won't be called.

## Acknowledgements

Retrofit was an inspiration for Snowdrop.
