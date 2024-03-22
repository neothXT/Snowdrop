//
//  ServiceMacro.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct ServiceMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let decl = declaration.as(ProtocolDeclSyntax.self) else {
            throw ServiceMacroError.badType
        }
        
        let access = decl.modifiers.first?.name.text ?? ""
        
        let name = decl.name.text + "Service"
        let accessModifier = access == "" ? "" : "\(access) "
        
        let functions: String = decl.memberBlock.members.compactMap { member -> String? in
            guard let fDecl = member.decl.as(FunctionDeclSyntax.self) else { return nil }
            var function: String?
            do {
                function = try FunctionMapper.map(accessModifier: accessModifier, declaration: fDecl, serviceName: name)
            } catch {
                context.diagnose((error as! Diagnostics).generate(for: member, severity: .error, fixIts: []))
            }
            return function
        }.joined(separator: "\n\n")
        
        return ["""
        \(raw: accessModifier)class \(raw: name) {
            private let baseUrl: URL
        
            \(raw: accessModifier)static var beforeSending: ((URLRequest) -> URLRequest)?
            \(raw: accessModifier)static var onResponse: ((Data?, HTTPURLResponse) -> Data?)?
        
            \(raw: accessModifier)init(baseUrl: URL) {
                self.baseUrl = baseUrl
            }
        
        \(raw: functions)
        }
        """]
    }
}
