![alt [version]](https://img.shields.io/github/v/release/neothXT/Netty) ![alt spm available](https://img.shields.io/badge/SPM-available-green) ![alt cocoapods available](https://img.shields.io/badge/CocoaPods-unavailable-red) ![alt carthage unavailable](https://img.shields.io/badge/Carthage-unavailable-red)

# Netty

Meet Netty - type-safe, easy to use framework powered by Swift Macros created to let you build and maintain complex network requests with ease.

## Navigation

- [Installation](#installation)
- [Key Functionalities](#key-functionalities)
- [Basic Usage](#macro-powered-networking)
    - [Service Declaration](#service-declaration)
    - [Request Execution](#request-execution)
- [Advanced Usage](#advanced-usage)
    - [Configuration](#configuration)
        - [SSL/Certificate Pinning](#sslcertificate-pinning)
        - [Access Token Storage](#access-token-storage)
    - [Body Argument](#body-argument)
    - [File Upload](#file-upload)
    - [Query Parameters](#query-parameters)
    - [Arguments' Default Values](#arguments-default-values)
    - [Authorization](#authorization)
        - [Access Token Refresh Automation](#access-token-refresh-automation)
        - [Defining Custom Access Token Storage](#defining-custom-access-token-storage)
        - [Custom Access Token storage key](#custom-access-token-storage-key)
    - [Interceptions](#interceptions)

## Installation

Netty is available via SPM. It works with iOS Deployment Target has to be 14.0 or newer. If you code for macOS, your Deployment Target has to be 11 or newer.

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

Creating network services with Netty is really easy. Just declare a protocol along with its functions. 

```Swift
@Service(url: "https://my-endpoint.com")
protocol MyEndpoint {

    @GET(url: "posts")
    func getAllPosts() async throws -> [Post]
}
```

If your request includes some dynamic values, such as `id`, you can add it to your path wrapping it with `{}`. Netty will automatically bind your function declaration's arguments with those you include in request's path.

WARNING: You should not name your path variables "queryItems" or "payloadDescription".

```Swift
@GET(url: "posts/{id}")
func getPost(id: Int) async throws -> Post
```

### Request Execution

Upon expanding macros, Netty creates a class `MyEndpointService` which implements `MyEndpoint` protocol and generates all the functions you declared.

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
let service = MyEndpointService()
let post = try await getPost(id: 7)
```

## Advanced Usage

### Configuration

-

#### SSL/Certificate Pinning

-

#### Access Token Storage

-

### Body Argument

If you want to put some encodable object as a body of your request, use `@Body` macro like:

```Swift
@POST(url: "posts")
@Body("model")
func addPost(model: Post) async throws -> Data
```

### File Upload

If you want to declare service's function that sends some file to the server as `multipart/form-data`, use `@FileUpload` macro. It'll automatically add `Content-Type: multipart/form-data` to the request's headers and extend the list of your function's arguments with `payloadDescription: PayloadDescription` which you should then use to provide information such as `name`, `fileName` and `mimeType`.

```Swift
@Service(url: "https://my-endpoint.com")
protocol MyEndpoint {

    @FileUpload
    @Body("image")
    @POST(url: "uploadAvatar/")
    func uploadImage(_ image: UIImage) async throws -> Data
}

let payload = PayloadDescription(name: "avatar", fileName: "filename.jpeg", mimeType: "image/jpeg")
let service = MyEndpointService()
_ = try await service.uploadImage(someImage, payloadDescription: payload)
```

### Query Parameters

Upon expanding macros, Netty adds argument `queryItems: [URLQueryItem]` to every service's function. For dynamic query parameters it's recommended to pass them using this argument like:

```Swift
@Service(url: "https://my-endpoint.com")
protocol MyEndpoint {

    @GET(url: "posts/{id}")
    func getPost(id: Int) async throws -> Post
}

let authorName = "John Smith"
let service = MyEndpointService()
let post = try await service.getPost(id: 7, queryItems: [.init(name: "author", value: authorName)])
```

However, if you want to add static query parameters to your request, you may also include them in your path like:

```Swift
@GET(url: "posts/{id}?myStaticParam=value")
func getPost(id: Int) async throws -> Post
```
 
WARNING: Do not combine those approaches in one request.

### Arguments' Default Values

Netty allows you to define custom values for your arguments. Let's say your path includes `{id}` argument. As you already know by now, Netty automatically associates it with `id` argument of your `func` declaration. If you want it to have default value equal "3", do it like: `{id=3}`. Be careful though as Netty won't check if your default value's type conforms to the declaration.  

### Authorization

-

#### Access Token Refresh Automation

-

#### Defining Custom Access Token Storage

-

#### Custom Access Token storage key

By default, Netty uses "NettyToken" as an access token storage key for each service. If you want to use some other name, use `@TokenLabel` macro like:

```Swift
@Service(url: "https://my-endpoint.com")
@TokenLabel("My label")
protocol MyEndpoint {
    // function declarations
}
```

### Interceptions

Each service provides two interceptors - `beforeSending` and `onResponse`. You should use them like:

```Swift
let service = MyEndpointService()

service.beforeSending = { request in
    // some operations
    return request
}

service.onResponse = { data, urlResponse in
    // some operations
    return data
}
```

Those interceptors are then called for each MyEndpointService function's call.
