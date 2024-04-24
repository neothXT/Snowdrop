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
        
        let name = decl.name.text
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
        
        return [printOutcome(accessModifier: accessModifier, name: name, functions: functions)]
    }
    
    private static func printOutcome(accessModifier: String, name: String, functions: String) -> DeclSyntax {
                """
                \(raw: accessModifier)class \(raw: name)Service: \(raw: name), Service {
                    \(raw: accessModifier)let baseUrl: URL
                
                    \(raw: accessModifier)var requestBlocks: [String: RequestHandler] = [:]
                    \(raw: accessModifier)var responseBlocks: [String: ResponseHandler] = [:]
                
                    \(raw: accessModifier)required init(baseUrl: URL) {
                        self.baseUrl = baseUrl
                    }
                
                    \(raw: accessModifier)func addBeforeSendingBlock(for path: String? = nil, _ block: @escaping RequestHandler) {
                        var key = "all"
                        if let path {
                            key = baseUrl.appending(path: path).absoluteString
                        }
                        requestBlocks[key] = block
                    }
                    
                    \(raw: accessModifier)func addOnResponseBlock(for path: String? = nil, _ block: @escaping ResponseHandler) {
                        var key = "all"
                        if let path {
                            key = baseUrl.appending(path: path).absoluteString
                        }
                        responseBlocks[key] = block
                    }
                
                \(raw: functions)
                }
                """
    }
}
