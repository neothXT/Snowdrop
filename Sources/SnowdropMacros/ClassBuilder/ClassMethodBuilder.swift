//
//  ClassMethodBuilder.swift.swift
//  Snowdrop
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
            extendedEnrichedParams.append(.init(key: "_payloadDescription", type: "PayloadDescription", value: nil, optional: false))
        }
        
        extendedEnrichedParams.append(.init(key: "_queryItems", type: "[QueryItem]", value: nil, optional: false))
        
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
            url: try PathVariableFinder(url: url).escape(),
            urlWithoutParams: try PathVariableFinder(url: url).strippedFromVariables(),
            optionalParams: enrichedParams.filter(\.optional).map(\.keyWithoutPrefix),
            method: method,
            headers: passedArguments.headers ?? "[:]",
            queryParams: passedArguments.queryParams,
            body: body,
            returnType: returnType,
            isUploadingFile: passedArguments.isUploadingFile,
            serviceName: serviceName,
            doesThrow: effectSpecifiers.contains("throws")
        )
    }
}
