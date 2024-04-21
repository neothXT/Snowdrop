//
//  FunctionMapper.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import SwiftSyntax

class FunctionMapper {
    private init() {}
    
    static func map(accessModifier: String, declaration decl: FunctionDeclSyntax, serviceName: String) throws -> String {
        guard let passedArguments = decl.getPassedArguments(),
              let url = passedArguments.url else {
            throw RequestMacroError.badOrMissingUrlParameter
        }
        
        guard let method = decl.methodType?.rawValue.uppercased() else {
            throw RequestMacroError.badOrMissingMethodParameter
        }
        
        let signature = decl.signature
        let params = signature.parameterClause.parameters
        let enrichedParams = params.asEnrichedStringParams(defaultValues: passedArguments.urlParams)
        var body: EnrichedParameter?
        let funcName = decl.name.text
        let effectSpecifiers = signature.effectSpecifiers?.description ?? ""
        let returnClause = signature.returnClause?.description ?? ""
        
        let bodyParamName = passedArguments.body ?? "body"
        body = enrichedParams.first { $0.key == bodyParamName }
        
        let returnType = signature.returnClause?.type.description
        
        guard effectSpecifiers.contains("throws") || (returnType?.contains("?") ?? true) else {
            throw RequestMacroError.missingOptional
        }
        
        // TODO: Add mapping for other passedArguments
        let bodyDetails = RequestBuilder.FuncBodyDetails(
            url: escape(url),
            method: method,
            headers: passedArguments.headers ?? "[:]",
            body: body,
            returnType: returnType,
            isUploadingFile: passedArguments.isUploadingFile,
            serviceName: serviceName,
            doesThrow: effectSpecifiers.contains("throws")
        )
        
        var extendedEnrichedParams = enrichedParams
        
        if passedArguments.isUploadingFile {
            extendedEnrichedParams.append(.init(key: "_payloadDescription", type: "PayloadDescription?", value: nil))
        }
        
        extendedEnrichedParams.append(.init(key: "_queryItems", type: "[QueryItem]", value: nil))
        
        let enrichedParamsString = enrichedParams.map { $0.toString() }.joined(separator: ", ")
        let extendedEnrichedParamsString = extendedEnrichedParams.map { $0.toString() }.joined(separator: ", ")
        let executableEnrichedParamsString = extendedEnrichedParams.map { $0.toExecutableString() }.joined(separator: ", ")
        
        let funcBody = generateBody(details: bodyDetails)
        let shortBody = RequestBuilder.buildShort(details: bodyDetails)
        
        return """
        \(accessModifier)func \(funcName)(\(enrichedParamsString))\(effectSpecifiers)\(returnClause) {
            \(shortBody)
            return \(bodyDetails.doesThrow ? "try await" : "await") \(funcName)(\(executableEnrichedParamsString))
        }
        
        \(accessModifier)func \(funcName)(\(extendedEnrichedParamsString))\(effectSpecifiers)\(returnClause)\(funcBody)
        """
    }
    
    private static func generateBody(details: RequestBuilder.FuncBodyDetails) -> String {
        """
        {
            var url = baseUrl.appendingPathComponent("\(details.url)")
            let headers: [String: Any] = \(details.headers)
            \(RequestBuilder.build(details: details))
        }
        """
    }
    
    private static func escape(_ string: String) -> String {
        let outcome = string
            .replacingOccurrences(of: "{", with: "\\(")
            .replacingOccurrences(of: "}", with: ")")
            .split(separator: "=")
        
        return outcome.count > 1 ? String(outcome.first ?? "") + ")" : String(outcome.first ?? "")
    }
}
