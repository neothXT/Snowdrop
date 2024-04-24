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
                @GET(url: "/posts/{id=2}")
                @Headers(["Content-Type": "application/json"])
                @Body("model")
                func getPosts(for id: Int, model: Model) async throws -> Post
            }
            """,
            expandedSource:
            """
            
            protocol TestEndpoint {
                func getPosts(for id: Int, model: Model) async throws -> Post
            }
            
            class TestEndpointService: TestEndpoint, Service {
                let baseUrl: URL
            
                var requestBlocks: [String: RequestHandler] = [:]
                var responseBlocks: [String: ResponseHandler] = [:]
            
                required init(baseUrl: URL) {
                    self.baseUrl = baseUrl
                }
            
                func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    requestBlocks[key] = block
                }
            
                func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    responseBlocks[key] = block
                }
            
                func getPosts(for id: Int = 2, model: Model) async throws -> Post {
                    let _queryItems: [QueryItem] = []
                    return try await getPosts(for: id, model: model, _queryItems: _queryItems)
                }

                func getPosts(for id: Int = 2, model: Model, _queryItems: [QueryItem]) async throws -> Post {
                    var url = baseUrl.appendingPathComponent("/posts/\\(id)")
                    let rawUrl = baseUrl.appendingPathComponent("/posts/{id}").absoluteString
                    let headers: [String: Any] = ["Content-Type": "application/json"]
            
                    if !_queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.queryItems = _queryItems.map {
                            $0.toUrlQueryItem()
                        }
                        url = components.url!
                    }
            
                    var request = URLRequest(url: url)
            
                    request.httpMethod = "GET"
            
                    headers.forEach { key, value in
                        request.addValue("\\(value)", forHTTPHeaderField: key)
                    }
            
                    var data: Data?
            
                    if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                        data = Snowdrop.core.prepareUrlEncodedBody(data: model)
                    } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                        data = Snowdrop.core.prepareBody(data: model)
                    }
            
                    request.httpBody = data
            
                    return try await Snowdrop.core.performRequestAndDecode(
                        request,
                        rawUrl: rawUrl,
                        requestBlocks: requestBlocks,
                        responseBlocks: responseBlocks
                    )
                }
            }
            """,
            macros: [
                "Service": ServiceMacro.self,
                "GET": GetMacro.self,
                "Headers": HeadersMacro.self,
                "Body": BodyMacro.self
            ]
        )
    }
    
    func testUploadMacro() throws {
        assertMacroExpansion(
            """
            @Service(url: "https://google.com")
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
            
                public required init(baseUrl: URL) {
                    self.baseUrl = baseUrl
                }
            
                public func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
                    }
                    requestBlocks[key] = block
                }
            
                public func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                    var key = "all"
                    if let path {
                        key = baseUrl.appending(path: path).absoluteString
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
                    var url = baseUrl.appendingPathComponent("/file")
                    let rawUrl = baseUrl.appendingPathComponent("/file").absoluteString
                    let headers: [String: Any] = [:]
            
                    if !_queryItems.isEmpty {
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.queryItems = _queryItems.map {
                            $0.toUrlQueryItem()
                        }
                        url = components.url!
                    }
            
                    var request = URLRequest(url: url)
            
                    request.httpMethod = "POST"
            
                    headers.forEach { key, value in
                        request.addValue("\\(value)", forHTTPHeaderField: key)
                    }
            
                    if (headers["Content-Type"] as? String) == nil {
                        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                    }
            
                    request.httpBody = Snowdrop.core.dataWithBoundary(file, payloadDescription: _payloadDescription)
            
                    return try await Snowdrop.core.performRequestAndDecode(
                        request,
                        rawUrl: rawUrl,
                        requestBlocks: requestBlocks,
                        responseBlocks: responseBlocks
                    )
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
}
