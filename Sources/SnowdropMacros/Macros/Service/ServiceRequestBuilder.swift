//
//  ServiceRequestBuilder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

struct ServiceRequestBuilder: ClassMethodBodyBuilderProtocol {
    private init() { /* NOP */ }
    
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
        var requestImpl = """
        
            if !_queryItems.isEmpty {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                components.queryItems = _queryItems.map {
                    $0.toUrlQueryItem()
                }
                url = components.url!
            }
        
            var request = URLRequest(url: url)
        
            request.httpMethod = "\(details.method)"
        
            headers.forEach { key, value in
                request.addValue("\\(value)", forHTTPHeaderField: key)
            }\n\n
        """
        
        if details.isUploadingFile, let body = details.body?.key {
            requestImpl += """
                if (headers["Content-Type"] as? String) == nil {
                    request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                }
            
                request.httpBody = Snowdrop.core.dataWithBoundary(\(body), payloadDescription: _payloadDescription)\n\n
            """
        } else if let body = details.body?.key {
            requestImpl += """
                var data: Data?
            
                if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                    data = Snowdrop.core.prepareUrlEncodedBody(data: \(body))
                } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                    data = Snowdrop.core.prepareBody(data: \(body))
                }
            
                request.httpBody = data\n\n
            """
        }
        
        if let _ = details.returnType {
            requestImpl += """
                return try\(details.doesThrow ? "" : "?") await Snowdrop.core.performRequestAndDecode(
                    request,
                    rawUrl: rawUrl,
                    requestBlocks: requestBlocks,
                    responseBlocks: responseBlocks
                )
            """
        } else {
            requestImpl += """
                _ = try\(details.doesThrow ? "" : "?") await Snowdrop.core.performRequest(
                    request,
                    rawUrl: rawUrl,
                    requestBlocks: requestBlocks,
                    responseBlocks: responseBlocks
                )
            """
        }
        
        return requestImpl
    }
}
