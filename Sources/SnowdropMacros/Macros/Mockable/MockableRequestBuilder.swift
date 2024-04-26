//
//  MockableRequestBuilder.swift
//
//
//  Created by Maciej Burdzicki on 27/04/2024.
//

import Foundation

struct MockableRequestBuilder: ClassMethodBodyBuilderProtocol {
    private init() { /* NOP */}
    
    static func buildShort(details: FuncBodyDetails) -> String {
        var requestImpl = """
        let _queryItems: [QueryItem] = []
        """
        
        if details.isUploadingFile {
            requestImpl += """
            
                let _payloadDescription: PayloadDescription? = PayloadDescription(name: "payload",
                                                                                  fileName: "payload",
                                                                                  mimeType: MimeType(from: fileData).rawValue)
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
}

