//
//  Endpoint.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import Combine
import Netty

public struct Post: Codable {
    let id, userId: Int
    let title, body: String
}

public struct Comment: Codable {
    let postId, id: Int
    let name, email, body: String
}

@TokenLabel("TestToken")
@Service(url: "https://jsonplaceholder.typicode.com")
public protocol TestEndpoint {

    @RequiresAccessToken
    @GET(url: "/posts/{id=2}")
    func getPost(id: Int) async throws -> Post
    
    @GET(url: "posts/{id}?test1=true")
    func getPostWithStaticQuery(id: Int) async throws -> Post
    
    @GET(url: "/posts/{id}/comments")
    func getComments(id: Int) async throws -> [Comment]
    
    @RequiresAccessToken
    @POST(url: "/posts")
    @Headers([
        "Content-Type": "application/json",
    ])
    @Body("model")
    func addPost(model: Post) async throws -> Post
}


