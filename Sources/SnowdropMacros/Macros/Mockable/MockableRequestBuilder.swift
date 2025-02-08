//
//  MockableRequestBuilder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 27/04/2024.
//

import Foundation

struct MockableRequestBuilder: ClassMethodBodyBuilderProtocol {
    private init() { /* NOP */ }
    
    static func buildShort(details: FuncBodyDetails) -> String {
        var requestImpl = """
        let _queryItems: [QueryItem] = []
        """
        
        if details.isUploadingFile, let body = details.body?.key {
            requestImpl += """
            
                let _payloadDescription = PayloadDescription(name: "payload",
                                                             fileName: "payload",
                                                             mimeType: MimeType(fromFile: \(body))?.rawValue ?? "unknown")
            """
        }
        
        return requestImpl
    }
    
    static func build(details: FuncBodyDetails) -> String {
        assertionFailure("Use build(funcName:) instead")
        return ""
    }
    
    static func build(funcName: String, doesThrow: Bool) -> String {
        """
        try\(doesThrow ? "" : "?") \(funcName)Result.get()
        """
    }
    
    static func buildNonReturnable(funcName: String, doesThrow: Bool) -> String {
        guard doesThrow else { return "/* NOP */" }
        return """
        guard let \(funcName)Result else { 
                return
            }
            throw \(funcName)Result
        """
    }
}

