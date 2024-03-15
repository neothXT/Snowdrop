//
//  Diagnostics.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxBuilder

enum ServiceMacroError: Diagnostics, CustomStringConvertible, Error {
    case badType, badOrMissingParameter, syntaxError
    
    var domain: String { "endpoint" }
    
    var description: String {
        switch self {
        case .badType:
            return "@Service can only be applied to a protocol"
        case .badOrMissingParameter:
            return "Missing or bad parameter url passed"
        case .syntaxError:
            return "Unknown syntax error occurred"
        }
    }
}

enum RequestMacroError: Diagnostics, CustomStringConvertible, Error {
    case typeNotRecognized, badType(macroName: String, type: String = "function"), 
         badOrMissingUrlParameter, badOrMissingMethodParameter, syntaxError, badOrMissingReturnType, missingOptional
    
    var domain: String { "network request" }
    
    var description: String {
        switch self {
        case .typeNotRecognized:
            return "Type couldn't be recognized"
        case .badType(let macroName, let type):
            return "@\(macroName) can only be applied to a \(type)"
        case .badOrMissingUrlParameter:
            return "Bad or missing url parameter passed"
        case .badOrMissingMethodParameter:
            return "Bad or missing method parameter passed"
        case .badOrMissingReturnType:
            return "Bad or missing return type"
        case .missingOptional:
            return "Functions that don't throw require return type to be optional"
        case .syntaxError:
            return "Unknown syntax error occurred"
        }
    }
}

protocol Diagnostics {
    var domain: String { get }
    var description: String { get }
    func generate(for node: SyntaxProtocol, severity: DiagnosticSeverity, fixIts: [FixIt]) -> Diagnostic
}

extension Diagnostics {
    func generate(for node: SyntaxProtocol, severity: DiagnosticSeverity = .error, fixIts: [FixIt] = []) -> Diagnostic {
        .init(
            node: Syntax(node),
            message: DiagnosticMessageImpl(
                diagnosticID: .init(domain: domain,id: String(describing: self)),
                message: description, severity: severity),
            fixIts: fixIts)
    }
}

struct FixItMsg: FixItMessage {
    var fixItID: MessageID
    var message: String
}

fileprivate struct DiagnosticMessageImpl: DiagnosticMessage {
    var diagnosticID: MessageID
    var message: String
    var severity: DiagnosticSeverity
}
