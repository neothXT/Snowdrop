//
//  SnowdropMacrosTests.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SnowdropMacros

final class SnowdropMacrosTests: XCTestCase {
    func testEndpointMacro() throws {
        assertMacroExpansion(
            """
            @Service
            protocol TestEndpoint {
                @GET(url: "/posts/{id}/comments")
                @Headers(["Content-Type": "application/json"])
                @Body("model")
                @QueryParams(["test"])
                func getPosts(for id: Int?, model: Model, test: Bool) async throws -> Post
            }
            """,
            expandedSource:
            """
            
            protocol TestEndpoint {
                func getPosts(for id: Int?, model: Model, test: Bool) async throws -> Post
            }
            
            class TestEndpointService: TestEndpoint, Service {
                let baseUrl: URL
            
                var requestBlocks: [String: RequestHandler] = [:]
                var responseBlocks: [String: ResponseHandler] = [:]
            
                var testJSONDictionary: [String: String]?
            
                var decoder: JSONDecoder
                var pinningMode: PinningMode?
                var urlsExcludedFromPinning: [String]
                let verbose: Bool
            
                required init(
                    baseUrl: URL,
                    pinningMode: PinningMode? = nil,
                    urlsExcludedFromPinning: [String] = [],
                    decoder: JSONDecoder = .init(),
                    verbose: Bool = false
                ) {
                    self.baseUrl = baseUrl
                    self.pinningMode = pinningMode
                    self.urlsExcludedFromPinning = urlsExcludedFromPinning
                    self.decoder = decoder
                    self.verbose = verbose
                }
            
                func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    var key = "all"
                    if let path {
                        if #available(iOS 16, *) {
                            key = baseUrl.appending(path: path).absoluteString
                        } else {
                            key = baseUrl.appendingPathComponent(path).absoluteString
                        }
                    }
                    requestBlocks[key] = block
                }
            
                func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    var key = "all"
                    if let path {
                        if #available(iOS 16, *) {
                            key = baseUrl.appending(path: path).absoluteString
                        } else {
                            key = baseUrl.appendingPathComponent(path).absoluteString
                        }
                    }
                    responseBlocks[key] = block
                }
            
                func getPosts(for id: Int?, model: Model, test: Bool) async throws -> Post {
                    let _queryItems: [QueryItem] = [
                        .init(key: "test", value: test)
                    ]
                    return try await getPosts(for: id, model: model, test: test, _queryItems: _queryItems)
                }

                func getPosts(for id: Int?, model: Model, test: Bool, _queryItems: [QueryItem]) async throws -> Post {
                    let url: URL
                    if let id {
                        url = baseUrl.appendingPathComponent("/posts/\\(id)/comments")
                    } else {
                        url = baseUrl.appendingPathComponent("/posts/comments")
                    }
            
                    let headers: [String: Any] = ["Content-Type": "application/json"]
            
                    var request = prepareBasicRequest(url: url, method: "GET", queryItems: _queryItems, headers: headers)
                    var data: Data?
            
                    if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                        data = Snowdrop.core.prepareUrlEncodedBody(data: model)
                    } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                        data = Snowdrop.core.prepareBody(data: model)
                    }
            
                    request.httpBody = data
            
                    return try await Snowdrop.core.performRequestAndDecode(request, service: self)
                }
            
                private func prepareBasicRequest(url: URL, method: String, queryItems: [QueryItem], headers: [String: Any]) -> URLRequest {
                    var finalUrl = url

                    if !queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.queryItems = queryItems.map {
                            $0.toUrlQueryItem()
                        }
                        finalUrl = components.url!
                    }

                    var request = URLRequest(url: finalUrl)
                    request.httpMethod = method

                    headers.forEach { key, value in
                        request.addValue("\\(value)", forHTTPHeaderField: key)
                    }

                    return request
                }
            }
            """,
            macros: [
                "Service": ServiceMacro.self,
                "GET": GetMacro.self,
                "Headers": HeadersMacro.self,
                "Body": BodyMacro.self,
                "QueryParams": QueryParamsMacro.self
            ]
        )
    }
    
    func testUploadMacro() throws {
        assertMacroExpansion(
            """
            @Service
            public protocol TestEndpoint {
                @POST(url: "/file")
                @FileUpload
                @Body("file")
                func uploadFile(file: UIImage) async throws -> Post
            }
            """,
            expandedSource:
            """
            
            public protocol TestEndpoint {
                func uploadFile(file: UIImage) async throws -> Post
            }
            
            public class TestEndpointService: TestEndpoint, Service {
                public let baseUrl: URL
            
                public var requestBlocks: [String: RequestHandler] = [:]
                public var responseBlocks: [String: ResponseHandler] = [:]
            
                public var testJSONDictionary: [String: String]?
            
                public var decoder: JSONDecoder
                public var pinningMode: PinningMode?
                public var urlsExcludedFromPinning: [String]
                public let verbose: Bool
            
                public required init(
                    baseUrl: URL,
                    pinningMode: PinningMode? = nil,
                    urlsExcludedFromPinning: [String] = [],
                    decoder: JSONDecoder = .init(),
                    verbose: Bool = false
                ) {
                    self.baseUrl = baseUrl
                    self.pinningMode = pinningMode
                    self.urlsExcludedFromPinning = urlsExcludedFromPinning
                    self.decoder = decoder
                    self.verbose = verbose
                }
            
                public func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    var key = "all"
                    if let path {
                        if #available(iOS 16, *) {
                            key = baseUrl.appending(path: path).absoluteString
                        } else {
                            key = baseUrl.appendingPathComponent(path).absoluteString
                        }
                    }
                    requestBlocks[key] = block
                }
            
                public func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    var key = "all"
                    if let path {
                        if #available(iOS 16, *) {
                            key = baseUrl.appending(path: path).absoluteString
                        } else {
                            key = baseUrl.appendingPathComponent(path).absoluteString
                        }
                    }
                    responseBlocks[key] = block
                }
            
                public func uploadFile(file: UIImage) async throws -> Post {
                    let _queryItems: [QueryItem] = []
                    let _payloadDescription: PayloadDescription? = PayloadDescription(name: "payload",
                                                                                      fileName: "payload",
                                                                                      mimeType: MimeType(from: fileData).rawValue)
                    return try await uploadFile(file: file, _payloadDescription: _payloadDescription, _queryItems: _queryItems)
                }
            
                public func uploadFile(file: UIImage, _payloadDescription: PayloadDescription?, _queryItems: [QueryItem]) async throws -> Post {
                    let url = baseUrl.appendingPathComponent("/file")
                    let headers: [String: Any] = [:]
            
                    var request = prepareBasicRequest(url: url, method: "POST", queryItems: _queryItems, headers: headers)

                    if (headers["Content-Type"] as? String) == nil {
                        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                    }
            
                    request.httpBody = Snowdrop.core.dataWithBoundary(file, payloadDescription: _payloadDescription)
            
                    return try await Snowdrop.core.performRequestAndDecode(request, service: self)
                }
            
                private func prepareBasicRequest(url: URL, method: String, queryItems: [QueryItem], headers: [String: Any]) -> URLRequest {
                    var finalUrl = url

                    if !queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.queryItems = queryItems.map {
                            $0.toUrlQueryItem()
                        }
                        finalUrl = components.url!
                    }

                    var request = URLRequest(url: finalUrl)
                    request.httpMethod = method

                    headers.forEach { key, value in
                        request.addValue("\\(value)", forHTTPHeaderField: key)
                    }

                    return request
                }
            }
            """,
            macros: [
                "Service": ServiceMacro.self,
                "POST": GetMacro.self,
                "Body": BodyMacro.self,
                "FileUpload": FileUploadMacro.self
            ]
        )
    }
    
    func testMockableMacro() throws {
        assertMacroExpansion(
            """
            @Mockable
            public protocol TestEndpoint {
                @POST(url: "/file")
                @FileUpload
                @Body("file")
                func uploadFile(file: UIImage) async throws -> Post
            }
            """,
            expandedSource:
            """
            
            public protocol TestEndpoint {
                func uploadFile(file: UIImage) async throws -> Post
            }
            
            public class TestEndpointServiceMock: TestEndpoint, Service {
                public let baseUrl: URL
            
                public var requestBlocks: [String: RequestHandler] = [:]
                public var responseBlocks: [String: ResponseHandler] = [:]
            
                public var testJSONDictionary: [String: String]?
            
                public var decoder: JSONDecoder
                public var pinningMode: PinningMode?
                public var urlsExcludedFromPinning: [String]
                public let verbose: Bool
            
                public required init(
                    baseUrl: URL,
                    pinningMode: PinningMode? = nil,
                    urlsExcludedFromPinning: [String] = [],
                    decoder: JSONDecoder = .init(),
                    verbose: Bool = false
                ) {
                    self.baseUrl = baseUrl
                    self.pinningMode = pinningMode
                    self.urlsExcludedFromPinning = urlsExcludedFromPinning
                    self.decoder = decoder
                    self.verbose = verbose
                }
            
                public func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    addBeforeSendingBlockCallsCount += 1
                }
            
                public func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    addOnResponseBlockCallsCount += 1
                }
            
                public var uploadFileResult: Result<Post, Error> = .failure(SnowdropError(type: .unknown))
            
                public var addBeforeSendingBlockCallsCount = 0
                public var addOnResponseBlockCallsCount = 0
            
                public func uploadFile(file: UIImage) async throws -> Post {
                    let _queryItems: [QueryItem] = []
                    let _payloadDescription: PayloadDescription? = PayloadDescription(name: "payload",
                                                                                      fileName: "payload",
                                                                                      mimeType: MimeType(from: fileData).rawValue)
                    return try await uploadFile(file: file, _payloadDescription: _payloadDescription, _queryItems: _queryItems)
                }
            
                public func uploadFile(file: UIImage, _payloadDescription: PayloadDescription?, _queryItems: [QueryItem]) async throws -> Post {
                    try uploadFileResult.get()
                }
            }
            """,
            macros: [
                "Mockable": MockableMacro.self,
                "POST": GetMacro.self,
                "Body": BodyMacro.self,
                "FileUpload": FileUploadMacro.self
            ]
        )
    }
}
