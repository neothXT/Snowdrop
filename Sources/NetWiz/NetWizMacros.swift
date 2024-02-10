//
//  NetWizPlugin.swift
//
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

// MARK: - Service macro
@attached(peer, names: suffixed(Service))
public macro Service(url: String) = #externalMacro(module: "NetWizMacros", type: "ServiceMacro")

// MARK: - Modifier macros
@attached(peer)
public macro TokenLabel(_ label: String) = #externalMacro(module: "NetWizMacros", type: "TokenLabelMacro")

@attached(peer)
public macro AccessToken() = #externalMacro(module: "NetWizMacros", type: "AccessTokenMacro")

@attached(peer)
public macro AccessTokenRefresh() = #externalMacro(module: "NetWizMacros", type: "AccessTokenRefreshMacro")

@attached(peer)
public macro Path(_ name: String) = #externalMacro(module: "NetWizMacros", type: "PathMacro")

@attached(peer)
public macro Body() = #externalMacro(module: "NetWizMacros", type: "BodyMacro")

@attached(peer)
public macro Headers(_ headers: [String: Any]) = #externalMacro(module: "NetWizMacros", type: "HeadersMacro")


// MARK: - RequestMethod macros
@attached(accessor)
public macro NetworkRequest(url: String, method: String) = #externalMacro(module: "NetWizMacros", type: "NetworkRequestMacro")

@attached(peer)
public macro GET(url: String) = #externalMacro(module: "NetWizMacros", type: "GetMacro")

@attached(peer)
public macro POST(url: String) = #externalMacro(module: "NetWizMacros", type: "PostMacro")

@attached(peer)
public macro PUT(url: String) = #externalMacro(module: "NetWizMacros", type: "PutMacro")

@attached(peer)
public macro DELETE(url: String) = #externalMacro(module: "NetWizMacros", type: "DeleteMacro")

@attached(peer)
public macro PATCH(url: String) = #externalMacro(module: "NetWizMacros", type: "PatchMacro")

@attached(peer)
public macro CONNECT(url: String) = #externalMacro(module: "NetWizMacros", type: "ConnectMacro")

@attached(peer)
public macro HEAD(url: String) = #externalMacro(module: "NetWizMacros", type: "HeadMacro")

@attached(peer)
public macro OPTIONS(url: String) = #externalMacro(module: "NetWizMacros", type: "OptionsMacro")

@attached(peer)
public macro QUERY(url: String) = #externalMacro(module: "NetWizMacros", type: "QueryMacro")

@attached(peer)
public macro TRACE(url: String) = #externalMacro(module: "NetWizMacros", type: "TraceMacro")
