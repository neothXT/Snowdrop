//
//  FunctionMapper.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import SwiftSyntax

class FunctionMapper {
    private init() { /* NOP */ }
    
    static func map(accessModifier: String, declaration decl: FunctionDeclSyntax, serviceName: String) throws -> String {
        let fDetails = try generateDetails(accessModifier: accessModifier, decl: decl, serviceName: serviceName)
        let bodyDetails = try generateBodyDetails(accessModifier: accessModifier, decl: decl, serviceName: serviceName)
        
        let funcBody = generateBody(details: bodyDetails)
        let shortBody = RequestBuilder.buildShort(details: bodyDetails)
        
        return """
        \(accessModifier)func \(fDetails.funcName)(\(fDetails.enrichedParamsString))\(fDetails.effectSpecifiers)\(fDetails.returnClause) {
            \(shortBody)
            return \(bodyDetails.doesThrow ? "try await" : "await") \(fDetails.funcName)(\(fDetails.executableEnrichedParamsString))
        }
        
        \(accessModifier)func \(fDetails.funcName)(\(fDetails.extendedEnrichedParamsString))\(fDetails.effectSpecifiers)\(fDetails.returnClause)\(funcBody)
        """
    }
    
    private static func generateBody(details: RequestBuilder.FuncBodyDetails) -> String {
        """
        {
            var url = baseUrl.appendingPathComponent("\(details.url)")
            let rawUrl = baseUrl.appendingPathComponent("\(details.rawUrl)").absoluteString
            let headers: [String: Any] = \(details.headers)
            \(RequestBuilder.build(details: details))
        }
        """
    }
    
    private static func generateDetails(
        accessModifier: String,
        decl: FunctionDeclSyntax,
        serviceName: String
    ) throws -> FuncDetails {
        guard let passedArguments = decl.getPassedArguments(),
              let url = passedArguments.url else {
            throw RequestMacroError.badOrMissingUrlParameter
        }
        
        guard let method = decl.methodType?.rawValue.uppercased() else {
            throw RequestMacroError.badOrMissingMethodParameter
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
        
        let extendedEnrichedParamsString = extendedEnrichedParams.map { $0.toString() }.joined(separator: ", ")
        let executableEnrichedParamsString = extendedEnrichedParams.map { $0.toExecutableString() }.joined(separator: ", ")
        
        return .init(
            funcName: decl.name.text,
            enrichedParamsString: enrichedParams.map { $0.toString() }.joined(separator: ", "),
            extendedEnrichedParamsString: extendedEnrichedParams.map { $0.toString() }.joined(separator: ", "),
            executableEnrichedParamsString: extendedEnrichedParams.map { $0.toExecutableString() }.joined(separator: ", "),
            effectSpecifiers: effectSpecifiers,
            returnClause: decl.signature.returnClause?.description ?? ""
        )
    }
    
    private static func generateBodyDetails(
        accessModifier: String,
        decl: FunctionDeclSyntax,
        serviceName: String
    ) throws -> RequestBuilder.FuncBodyDetails {
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
            url: escape(url),
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
    
    private static func escape(_ string: String) -> String {
        let outcome = string
            .replacingOccurrences(of: "{", with: "\\(")
            .replacingOccurrences(of: "}", with: ")")
            .split(separator: "=")
        
        return outcome.count > 1 ? String(outcome.first ?? "") + ")" : String(outcome.first ?? "")
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

extension FunctionMapper {
    struct FuncDetails {
        let funcName: String
        let enrichedParamsString: String
        let extendedEnrichedParamsString: String
        let executableEnrichedParamsString: String
        let effectSpecifiers: String
        let returnClause: String
    }
}
