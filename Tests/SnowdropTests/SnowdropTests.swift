//
//  SnowdropTests.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import XCTest
@testable import Snowdrop

final class SnowdropTests: XCTestCase {
    private let baseUrl = URL(string: "https://jsonplaceholder.typicode.com")!
    private lazy var service = TestEndpointService(baseUrl: baseUrl)
    private lazy var mock = TestEndpointServiceMock(baseUrl: baseUrl)

    func testGetTask() async throws {
        let result = try await service.getPost()
        XCTAssertTrue(result.id == 2)
    }
    
    func testPostTask() async throws {
        let result = try await service.addPost(model: .init(id: 101, userId: 1, title: "Some title", body: "some body"))
        XCTAssertTrue(result.title == "Some title")
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
        service.addOnResponseBlock(for: "posts/{id}/comments") { data, urlResponse in
            if urlResponse.statusCode == 200 && urlResponse.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/9/comments" {
                expectation.fulfill()
            }
            return data
        }
        _ = try await service.getComments(id: 9)
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testOnResponseWithMultipleVariables() async throws {
        let expectation = expectation(description: "Should intercept response")
        service.addOnResponseBlock(for: "/posts/{id}/comments/{commentId}") { data, urlResponse in
            if urlResponse.url?.absoluteString == "https://jsonplaceholder.typicode.com/posts/9/comments/6" {
                expectation.fulfill()
            }
            return data
        }
        _ = try? await service.getCertainComment(id: 9, commentId: 6)
        
        await fulfillment(of: [expectation], timeout: 5)
    }
    
    func testNonThrowingPosts() async throws {
        let result = await service.getNonThrowingPosts()
        XCTAssertNotNil(result)
    }
    
    func testPositiveGetTaskMock() async throws {
        let post = Post(id: 1, userId: 1, title: "Mock title", body: "Mock body")
        mock.getPostResult = .success(post)
        let result = try await mock.getPost()
        XCTAssertTrue(post.title == result.title)
    }
    
    func testNegativeGetTaskMock() async throws {
        mock.getPostResult = .failure(SnowdropError(type: .emptyResponse))
        do {
            let _ = try await mock.getPost()
        } catch {
            let snowdropError = try XCTUnwrap(error as? SnowdropError)
            XCTAssertTrue(snowdropError.type == .emptyResponse)
        }
    }
}
