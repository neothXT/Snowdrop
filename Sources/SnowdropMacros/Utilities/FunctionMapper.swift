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
        var enrichedParams = params.asEnrichedStringParams(defaultValues: passedArguments.urlParams)
        var body: EnrichedParameter?
        let funcName = decl.name.text
        let effectSpecifiers = signature.effectSpecifiers?.description ?? ""
        let returnClause = signature.returnClause?.description ?? ""
        
        let bodyParamName = passedArguments.body ?? "body"
        body = enrichedParams.first { $0.key == bodyParamName }
        
        guard let returnType = signature.returnClause?.type.description else {
            throw RequestMacroError.badOrMissingReturnType
        }
        
        guard effectSpecifiers.contains("throws") || returnType.contains("?") else {
            throw RequestMacroError.missingOptional
        }
        
        // TODO: Add mapping for other passedArguments
        let bodyDetails = RequestBuilder.FuncBodyDetails(
            url: escape(url),
            method: method,
            headers: passedArguments.headers ?? "[:]",
            body: body,
            returnType: returnType,
            requiresAccessToken: passedArguments.requiresAccessToken,
            isUploadingFile: passedArguments.isUploadingFile,
            serviceName: serviceName,
            doesThrow: effectSpecifiers.contains("throws")
        )
        
        if passedArguments.isUploadingFile {
            enrichedParams.append(.init(key: "_payloadDescription", type: "PayloadDescription", value: nil))
        }
        
        enrichedParams.append(.init(key: "_queryItems", type: "[QueryItem]", value: "[]"))
        
        let enrichedParamsString = enrichedParams.map { $0.toString() }.joined(separator: ", ")
        
        let funcBody = generateBody(details: bodyDetails)
        
        return """
        \(accessModifier)func \(funcName)(\(enrichedParamsString))\(effectSpecifiers)\(returnClause)\(funcBody)
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
