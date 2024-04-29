//
//  ClassMethodBuilder.swift.swift
//
//
//  Created by Maciej Burdzicki on 26/04/2024.
//

import SwiftSyntax
import Foundation

protocol ClassMethodBuilderProtocol {
    static func map(accessModifier: String, declaration decl: FunctionDeclSyntax, serviceName: String) throws -> String
}

protocol ClassMethodBodyBuilderProtocol {
    static func buildShort(details: FuncBodyDetails) -> String
    static func build(details: FuncBodyDetails) -> String
}

extension ClassMethodBuilderProtocol {
    static func generateDetails(
        accessModifier: String,
        decl: FunctionDeclSyntax
    ) throws -> FuncDetails {
        guard let passedArguments = decl.getPassedArguments() else {
            throw RequestMacroError.badOrMissingUrlParameter
        }
        
        let enrichedParams = decl.signature.parameterClause.parameters.asEnrichedStringParams(defaultValues: passedArguments.urlParams)
        let effectSpecifiers = decl.signature.effectSpecifiers?.description ?? ""
        let returnType = decl.signature.returnClause?.type.description
        
        guard effectSpecifiers.contains("throws") || (returnType?.contains("?") ?? true) else {
            throw RequestMacroError.missingOptional
        }
        
        var extendedEnrichedParams = enrichedParams
        
        if passedArguments.isUploadingFile {
            extendedEnrichedParams.append(.init(key: "_payloadDescription", type: "PayloadDescription?", value: nil))
        }
        
        extendedEnrichedParams.append(.init(key: "_queryItems", type: "[QueryItem]", value: nil))
        
        return .init(
            funcName: decl.name.text,
            enrichedParamsString: enrichedParams.map { $0.toString() }.joined(separator: ", "),
            extendedEnrichedParamsString: extendedEnrichedParams.map { $0.toString() }.joined(separator: ", "),
            executableEnrichedParamsString: extendedEnrichedParams.map { $0.toExecutableString() }.joined(separator: ", "),
            effectSpecifiers: effectSpecifiers,
            returnClause: decl.signature.returnClause?.description ?? ""
        )
    }
    
    static func generateBodyDetails(
        accessModifier: String,
        decl: FunctionDeclSyntax,
        serviceName: String
    ) throws -> FuncBodyDetails {
        guard let passedArguments = decl.getPassedArguments(),
              let url = passedArguments.url else {
            throw RequestMacroError.badOrMissingUrlParameter
        }
        
        guard let method = decl.methodType?.rawValue.uppercased() else {
            throw RequestMacroError.badOrMissingMethodParameter
        }
        
        let enrichedParams = decl.signature.parameterClause.parameters.asEnrichedStringParams(defaultValues: passedArguments.urlParams)
        let effectSpecifiers = decl.signature.effectSpecifiers?.description ?? ""
        let body = enrichedParams.first { $0.key == passedArguments.body ?? "body" }
        
        let returnType = decl.signature.returnClause?.type.description

        return .init(
            url: try escape(url),
            rawUrl: rawUrl(from: url, enrichedParams: enrichedParams),
            method: method,
            headers: passedArguments.headers ?? "[:]",
            body: body,
            returnType: returnType,
            isUploadingFile: passedArguments.isUploadingFile,
            serviceName: serviceName,
            doesThrow: effectSpecifiers.contains("throws")
        )
    }
    
    private static func escape(_ string: String) throws -> String {
        var outcome = string
        let shortRegex = "=[a-zA-Z0-9\"]+"
        let regex = try NSRegularExpression(pattern: #"\{[a-z]+[a-zA-Z0-9]+={0,1}[a-zA-Z0-9\"]*\}"#, options: [])
        let matches = regex.matches(in: string, range: .init(location: 0, length: string.count))
        
        matches.forEach { match in
            guard let matchRange = Range(match.range) else { return }
            let startIndex = string.index(string.startIndex, offsetBy: matchRange.lowerBound)
            let endIndex = string.index(string.startIndex, offsetBy: matchRange.upperBound)
            let range = startIndex ..< endIndex
            outcome = outcome
                .replacingOccurrences(of: "}", with: ")", range: range)
                .replacingOccurrences(of: "{", with: "\\(", range: range)
                .replacingOccurrences(of: shortRegex, with: "", options: .regularExpression, range: range)
        }
        
        return outcome
    }
    
    private static func rawUrl(from url: String, enrichedParams: [EnrichedParameter]) -> String {
        var rawUrl = url
        
        enrichedParams.forEach { param in
            guard let paramValue = param.value else { return }
            rawUrl = rawUrl.replacingOccurrences(of: paramValue, with: "")
        }
        
        return rawUrl.replacingOccurrences(of: "=", with: "")
    }
}
