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
        - [Access Token Storage](#access-token-storage)
    - [Body Argument](#body-argument)
    - [File Upload](#file-upload)
    - [Query Parameters](#query-parameters)
    - [Arguments' Default Values](#arguments-default-values)
    - [Authorization](#authorization)
        - [Defining Custom Access Token Storage](#defining-custom-access-token-storage)
        - [Access Token Refresh Automation](#access-token-refresh-automation)
        - [Custom Access Token storage key](#custom-access-token-storage-key)
    - [Interceptions](#interceptions)
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
- SSL and Certificate pinning
- WebSocket connection support
- Automated Access Token refresh with `Recoverable` protocol

## Basic Usage

### Service Declaration

Creating network services with Snowdrop is really easy. Just declare a protocol along with its functions. 

```Swift
@Service
protocol MyEndpoint {

    @GET(url: "/posts")
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

By default SSL/Certificate pinning is turned OFF. To enable it, use `Snowdrop.Config.pinningModes`. Possible settings are:

```Swift
Snowdrop.Config.pinningModes = .ssl
// or
Snowdrop.Config.pinningModes = .certificate
// or
Snowdrop.Config.pinningModes = [.ssl, .certificate]
```

If you want to exclude some URLs from SSL/Certificate pinning, add them to `Snowdrop.Config.urlsExcludedFromPinning`.

#### Access Token Storage

`Snowdrop.Config.accessTokenStorage` allows you to define your own storage for your access tokens. The default storage saves your tokens in RAM until your app is killed.

### Body Argument

If you want to put some encodable object as a body of your request, use `@Body` macro like:

```Swift
@POST(url: "/posts")
@Body("model")
func addPost(model: Post) async throws -> Data
```

### File Upload

If you want to declare service's function that sends some file to the server as `multipart/form-data`, use `@FileUpload` macro. It'll automatically add `Content-Type: multipart/form-data` to the request's headers and extend the list of your function's arguments with `_payloadDescription: PayloadDescription` which you should then use to provide information such as `name`, `fileName` and `mimeType`.

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

However, if you want to add static query parameters to your request, you may also include them in your path like:

```Swift
@GET(url: "/posts/{id}?myStaticParam=value")
func getPost(id: Int) async throws -> Post
```
 
WARNING: Do not combine those approaches in one request.

### Arguments' Default Values

Snowdrop allows you to define custom values for your arguments. Let's say your path includes `{id}` argument. As you already know by now, Snowdrop automatically associates it with `id` argument of your `func` declaration. If you want it to have default value equal "3", do it like: `{id=3}`. Be careful though as Snowdrop won't check if your default value's type conforms to the declaration.  

### Authorization

To let Snowdrop know a request requires access token, use `@RequiresAccessToken` macro like:

```Swift
@GET(url: "/posts")
@RequiresAccessToken
func getAllPosts() async throws -> [Post]
```

WARNING: For Snowdrop to be able to work with your access token regardless of its structure, make sure your token model conforms to `AccessTokenConvertible` protocol.

```Swift
public protocol AccessTokenConvertible: Codable {
    func convert() -> AccessToken?
}
```

#### Defining Custom Access Token Storage

Snowdrop comes with default access token storage that saves your tokens in RAM until your app is killed but you can also provide your own storage.
When doing so, remember that your storage has to conform to `AccessTokenStorage` protocol.

```Swift
public protocol AccessTokenStorage {
    func store(_ token: AccessToken?, for storingLabel: String)
    func fetch(for storingLabel: String) -> AccessToken?
    func delete(for storingLabel: String) -> Bool
}
```

Once your Access Token Storage is ready, assign it by invoking `Snowdrop.Config.setAccessTokenStorage(_ storage: AccessTokenStorage)`.

#### Access Token Refresh Automation

Upon expanding macros, for each service Snowdrop adds to it conformance to Recoverable protocol. That means, each service has `onAuthRetry` property which is called whenever request fails due to authentication error (401). You should put your access token refresh logic in it like:

```Swift 
MyEndpointService.onAuthRetry = { service in
    if let token = Snowdrop.Config.accessTokenStorage.fetch(for: MyEndpointService.tokenLabel) {
        return try await service.refreshToken(oldToken: token)
    } else {
        return try await service.getToken()
    }
}
```

You can also change which error codes should trigger `onAuthRetry` by setting `Snowdrop.Config.accessTokenErrorCodes` value.

#### Custom Access Token storage key

By default, Snowdrop uses "SnowdropToken" as an access token storage key for each service. If you want to use some other name, use `@TokenLabel` macro like:

```Swift
@Service
@TokenLabel("My label")
protocol MyEndpoint {
    // function declarations
}
```

### Interceptions

Each service provides two static interceptors - `beforeSending` and `onResponse`. You should use them like:

```Swift
MyEndpointService.beforeSending = { request in
    // some operations
    return request
}

MyEndpointService.onResponse = { data, urlResponse in
    // some operations
    return data
}
```

Those interceptors are then called for each MyEndpointService function's call.

## Acknowledgements

Retrofit was an inspiration for Snowdrop.
