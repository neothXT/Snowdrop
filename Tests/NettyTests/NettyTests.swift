//
//  NettyTests.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import XCTest
@testable import Netty

final class NettyTests: XCTestCase {
    private let service = TestEndpointService()

    func testGetTask() async throws {
        let result = try await service.getPost()
        XCTAssertTrue(result.id == 2)
    }
    
    func testPostTask() async throws {
        let result = try await service.addPost(model: .init(id: 101, userId: 1, title: "Some title", body: "some body"))
        XCTAssert(result.title == "Some title")
    }
    
    func testQueryItems() async throws {
        let expectation = expectation(description: "Should contain queryItems")
        service.beforeSending = { request in
            if request.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/12?test=true" {
                expectation.fulfill()
            }
            return request
        }
        _ = try await service.getPost(id: 12, queryItems: [.init(name: "test", value: "true")])
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testInterception() async throws {
        let expectation = expectation(description: "Should intercept request")
        service.beforeSending = { request in
            if request.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/7/comments" {
                expectation.fulfill()
            }
            return request
        }
        _ = try await service.getComments(id: 7)
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testOnResponse() async throws {
        let expectation = expectation(description: "Should intercept response")
        service.onResponse = { data, urlResponse in
            if urlResponse.statusCode == 200 {
                expectation.fulfill()
            }
            return data
        }
        _ = try await service.getComments(id: 7)
        
        await fulfillment(of: [expectation], timeout: 5)
    }
}
