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
            @TokenLabel("TestToken")
            protocol TestEndpoint {
                @GET(url: "/posts/{id=2}")
                @RequiresAccessToken
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
            
            class TestEndpointService: Recoverable {
                private let baseUrl: URL
                static public let tokenLabel = "TestToken"
            
                static var beforeSending: ((URLRequest) -> URLRequest)?
                static var onResponse: ((Data?, HTTPURLResponse) -> Data?)?
                static var onAuthRetry: ((TestEndpointService) async throws -> AccessTokenConvertible)?
            
                init(baseUrl: URL) {
                    self.baseUrl = baseUrl
                }

                func getPosts(for id: Int = 2, model: Model, _queryItems: [QueryItem] = []) async throws -> Post {
                    var url = baseUrl.appendingPathComponent("/posts/\\(id)")
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
            
                    let token = Snowdrop.Config.accessTokenStorage.fetch(for: TestEndpointService.tokenLabel)?.access_token
                    request.addValue("Bearer \\(token ?? "")", forHTTPHeaderField: "Authorization")
            
                    var data: Data?
            
                    if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                        data = Snowdrop.Core.prepareUrlEncodedBody(data: model)
                    } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                        data = Snowdrop.Core.prepareBody(data: model)
                    }
            
                    request.httpBody = data
            
                    request = TestEndpointService.beforeSending?(request) ?? request
                    let session = Snowdrop.Config.getSession()
            
                    return try await Snowdrop.Core.sendRequest(session: session,
                                                               request: request,
                                                               requiresAccessToken: true,
                                                               tokenLabel: TestEndpointService.tokenLabel,
                                                               onResponse: TestEndpointService.onResponse) {
                        try await TestEndpointService.onAuthRetry?(self)
                    }
                }
            }
            """,
            macros: [
                "Service": ServiceMacro.self, 
                "TokenLabel": TokenLabelMacro.self,
                "GET": GetMacro.self,
                "RequiresAccessToken": RequiresAccessTokenMacro.self,
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
            
            public class TestEndpointService: Recoverable {
                private let baseUrl: URL
                static public let tokenLabel = "TestEndpointServiceToken"
            
                public static var beforeSending: ((URLRequest) -> URLRequest)?
                public static var onResponse: ((Data?, HTTPURLResponse) -> Data?)?
                public static var onAuthRetry: ((TestEndpointService) async throws -> AccessTokenConvertible)?
            
                public init(baseUrl: URL) {
                    self.baseUrl = baseUrl
                }
            
                public func uploadFile(file: UIImage, _payloadDescription: PayloadDescription, _queryItems: [QueryItem] = []) async throws -> Post {
                    var url = baseUrl.appendingPathComponent("/file")
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
            
                    request.httpBody = Snowdrop.Core.dataWithBoundary(file, payloadDescription: _payloadDescription)
            
                    request = TestEndpointService.beforeSending?(request) ?? request
                    let session = Snowdrop.Config.getSession()
            
                    return try await Snowdrop.Core.sendRequest(session: session,
                                                               request: request,
                                                               requiresAccessToken: false,
                                                               tokenLabel: TestEndpointService.tokenLabel,
                                                               onResponse: TestEndpointService.onResponse) {
                        try await TestEndpointService.onAuthRetry?(self)
                    }
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
