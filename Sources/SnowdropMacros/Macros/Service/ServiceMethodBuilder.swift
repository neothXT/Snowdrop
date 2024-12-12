//
//  ServiceMethodBuilder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import SwiftSyntax

struct ServiceMethodBuilder: ClassMethodBuilderProtocol  {
    private init() { /* NOP */ }
    
    static func map(accessModifier: String, declaration decl: FunctionDeclSyntax, serviceName: String) throws -> String {
        let fDetails = try generateDetails(accessModifier: accessModifier, decl: decl)
        let bodyDetails = try generateBodyDetails(accessModifier: accessModifier, decl: decl, serviceName: serviceName)
        
        let funcBody = generateBody(details: bodyDetails)
        let shortBody = ServiceRequestBuilder.buildShort(details: bodyDetails)
        let awaitStmt = bodyDetails.doesThrow ? "try await" : "await"
        let optionalReturn = bodyDetails.returnType == nil ? "" : "return "
        
        return """
        \(accessModifier)func \(fDetails.funcName)(\(fDetails.enrichedParamsString))\(fDetails.effectSpecifiers)\(fDetails.returnClause) {
            \(shortBody)
            \(optionalReturn)\(awaitStmt) \(fDetails.funcName)(\(fDetails.executableEnrichedParamsString))
        }
        
        \(accessModifier)func \(fDetails.funcName)(\(fDetails.extendedEnrichedParamsString))\(fDetails.effectSpecifiers)\(fDetails.returnClause)\(funcBody)
        """
    }
    
    private static func generateBody(details: FuncBodyDetails) -> String {
        """
        {
            \(ServiceMethodBuilder.generateUrlPart(details: details))
            let headers: [String: Any] = \(details.headers)
            \(ServiceRequestBuilder.build(details: details))
        }
        """
    }
    
    private static func generateUrlPart(details: FuncBodyDetails) -> String {
        if !details.optionalParams.isEmpty {
            let optionalString = details.optionalParams.map{ "let \($0)" }.joined(separator: ", ")
            return """
            let url: URL
                if \(optionalString) {
                    url = baseUrl.appendingPathComponent("\(details.url)")
                } else {
                    url = baseUrl.appendingPathComponent("\(details.urlWithoutParams)")
                }
            
            """
        } else {
            return """
            let url = baseUrl.appendingPathComponent("\(details.url)")
            """
        }
    }
}
