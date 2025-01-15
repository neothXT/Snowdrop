//
//  SnowdropMacros.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

// MARK: - Service macro
@attached(peer, names: suffixed(Service), suffixed(Impl))
public macro Service() = #externalMacro(module: "SnowdropMacros", type: "ServiceMacro")

// MARK: - Mockable macro
@attached(peer, names: suffixed(ServiceMock), suffixed(Mock))
public macro Mockable() = #externalMacro(module: "SnowdropMacros", type: "MockableMacro")

// MARK: - Modifier macros
@attached(peer)
public macro Body(_: String) = #externalMacro(module: "SnowdropMacros", type: "BodyMacro")

@attached(peer)
public macro Headers(_: [String: Any]) = #externalMacro(module: "SnowdropMacros", type: "HeadersMacro")

@attached(peer)
public macro FileUpload() = #externalMacro(module: "SnowdropMacros", type: "FileUploadMacro")

@attached(peer)
public macro QueryParams(_: [String]) = #externalMacro(module: "SnowdropMacros", type: "QueryParamsMacro")


// MARK: - RequestMethod macros
@attached(peer)
public macro GET(url: String) = #externalMacro(module: "SnowdropMacros", type: "GetMacro")

@attached(peer)
public macro POST(url: String) = #externalMacro(module: "SnowdropMacros", type: "PostMacro")

@attached(peer)
public macro PUT(url: String) = #externalMacro(module: "SnowdropMacros", type: "PutMacro")

@attached(peer)
public macro DELETE(url: String) = #externalMacro(module: "SnowdropMacros", type: "DeleteMacro")

@attached(peer)
public macro PATCH(url: String) = #externalMacro(module: "SnowdropMacros", type: "PatchMacro")

@attached(peer)
public macro CONNECT(url: String) = #externalMacro(module: "SnowdropMacros", type: "ConnectMacro")

@attached(peer)
public macro HEAD(url: String) = #externalMacro(module: "SnowdropMacros", type: "HeadMacro")

@attached(peer)
public macro OPTIONS(url: String) = #externalMacro(module: "SnowdropMacros", type: "OptionsMacro")

@attached(peer)
public macro QUERY(url: String) = #externalMacro(module: "SnowdropMacros", type: "QueryMacro")

@attached(peer)
public macro TRACE(url: String) = #externalMacro(module: "SnowdropMacros", type: "TraceMacro")
