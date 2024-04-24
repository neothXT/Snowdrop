//
//  SnowdropTests.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import XCTest
@testable import Snowdrop

final class SnowdropTests: XCTestCase {
    private let service = TestEndpointService(baseUrl: URL(string: "https://jsonplaceholder.typicode.com")!)

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
        service.addBeforeSendingBlock { request in
            if request.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/12?test=true" {
                expectation.fulfill()
            }
            return request
        }
        _ = try await service.getPost(id: 12, _queryItems: [.init(key: "test", value: true)])
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testInterception() async throws {
        let expectation = expectation(description: "Should intercept request")
        service.addBeforeSendingBlock { request in
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
        service.addOnResponseBlock { data, urlResponse in
            if urlResponse.statusCode == 200 && urlResponse.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/9/comments" {
                expectation.fulfill()
            }
            return (data, urlResponse)
        }
        _ = try await service.getComments(id: 9)
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testNonThrowingPosts() async throws {
        let result = await service.getNonThrowingPosts()
        XCTAssert(result != nil)
    }
}
