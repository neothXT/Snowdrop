//
//  MockableMethodBuilder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 27/04/2024.
//

import SwiftSyntax

struct MockableMethodBuilder: ClassMethodBuilderProtocol  {
    private init() { /* NOP */ }
    
    static func map(accessModifier: String, declaration decl: FunctionDeclSyntax, serviceName: String) throws -> String {
        let fDetails = try generateDetails(accessModifier: accessModifier, decl: decl)
        let bodyDetails = try generateBodyDetails(accessModifier: accessModifier, decl: decl, serviceName: serviceName)
        let funcBody = generateBody(funcName: fDetails.funcName, doesReturn: !fDetails.returnClause.isEmpty, doesThrow: bodyDetails.doesThrow)
        let shortBody = MockableRequestBuilder.buildShort(details: bodyDetails)
        return """
        \(accessModifier)func \(fDetails.funcName)(\(fDetails.enrichedParamsString))\(fDetails.effectSpecifiers)\(fDetails.returnClause) {
            \(shortBody)
            return \(bodyDetails.doesThrow ? "try await" : "await") \(fDetails.funcName)(\(fDetails.executableEnrichedParamsString))
        }
        
        \(accessModifier)func \(fDetails.funcName)(\(fDetails.extendedEnrichedParamsString))\(fDetails.effectSpecifiers)\(fDetails.returnClause)\(funcBody)
        """
    }
    
    private static func generateBody(funcName: String, doesReturn: Bool, doesThrow: Bool) -> String {
        guard doesReturn else {
            return """
            {
                \(MockableRequestBuilder.buildNonReturnable(funcName: funcName, doesThrow: doesThrow))
            }
            """
        }
        
        return """
        {
            \(MockableRequestBuilder.build(funcName: funcName, doesThrow: doesThrow))
        }
        """
    }
}
