//
//  NettyMacros.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

// MARK: - Service macro
@attached(peer, names: suffixed(Service))
public macro Service(url: String) = #externalMacro(module: "NettyMacros", type: "ServiceMacro")

// MARK: - Modifier macros
@attached(peer)
public macro TokenLabel(_: String) = #externalMacro(module: "NettyMacros", type: "TokenLabelMacro")

@attached(peer)
public macro RequiresAccessToken() = #externalMacro(module: "NettyMacros", type: "RequiresAccessTokenMacro")

@attached(peer)
public macro Body(_: String) = #externalMacro(module: "NettyMacros", type: "BodyMacro")

@attached(peer)
public macro Headers(_: [String: Any]) = #externalMacro(module: "NettyMacros", type: "HeadersMacro")

@attached(peer)
public macro FileUpload() = #externalMacro(module: "NettyMacros", type: "FileUploadMacro")


// MARK: - RequestMethod macros
@attached(peer, names: arbitrary)
public macro GET(url: String) = #externalMacro(module: "NettyMacros", type: "GetMacro")

@attached(peer)
public macro POST(url: String) = #externalMacro(module: "NettyMacros", type: "PostMacro")

@attached(peer)
public macro PUT(url: String) = #externalMacro(module: "NettyMacros", type: "PutMacro")

@attached(peer)
public macro DELETE(url: String) = #externalMacro(module: "NettyMacros", type: "DeleteMacro")

@attached(peer)
public macro PATCH(url: String) = #externalMacro(module: "NettyMacros", type: "PatchMacro")

@attached(peer)
public macro CONNECT(url: String) = #externalMacro(module: "NettyMacros", type: "ConnectMacro")

@attached(peer)
public macro HEAD(url: String) = #externalMacro(module: "NettyMacros", type: "HeadMacro")

@attached(peer)
public macro OPTIONS(url: String) = #externalMacro(module: "NettyMacros", type: "OptionsMacro")

@attached(peer)
public macro QUERY(url: String) = #externalMacro(module: "NettyMacros", type: "QueryMacro")

@attached(peer)
public macro TRACE(url: String) = #externalMacro(module: "NettyMacros", type: "TraceMacro")
