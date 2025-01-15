//
//  RequestMethodMacros.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct GetMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "GET", declaration: declaration)
    }
}

public struct PostMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "POST", declaration: declaration)
    }
}

public struct PutMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "PUT", declaration: declaration)
    }
}

public struct DeleteMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "DELETE", declaration: declaration)
    }
}

public struct PatchMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "PATCH", declaration: declaration)
    }
}

public struct ConnectMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "CONNECT", declaration: declaration)
    }
}

public struct HeadMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "HEAD", declaration: declaration)
    }
}

public struct OptionsMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "OPTIONS", declaration: declaration)
    }
}

public struct QueryMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "QUERY", declaration: declaration)
    }
}

public struct TraceMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "TRACE", declaration: declaration)
    }
}

public struct HeadersMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "Headers", declaration: declaration)
    }
}

public struct BodyMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "Body", declaration: declaration)
    }
}

public struct FileUploadMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "FileUpload", declaration: declaration)
    }
}

public struct QueryParamsMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try checkType(FunctionDeclSyntax.self, for: "QueryParams", declaration: declaration)
    }
}

fileprivate func checkType<T: DeclSyntaxProtocol>(_ type: T.Type, for macroName: String, declaration: DeclSyntaxProtocol) throws -> [DeclSyntax] {
    guard let _ = declaration.as(T.self) else {
        throw RequestMacroError.badType(macroName: macroName, type: ProtocolDeclSyntax.self is T.Type ? "protocol" : "function")
    }
    return []
}
