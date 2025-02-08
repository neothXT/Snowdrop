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
        var requestImpl = ""
        if let queryParams = details.queryParams {
            let queryParamsList = queryParams
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .split(separator: ",")
                .map { ".init(key: \"\($0)\", value: \($0))" }
            
            requestImpl = """
            let _queryItems: [QueryItem] = [
                    \(queryParamsList.joined(separator: ",\n"))
                ]
            """
        } else {
            requestImpl = """
            let _queryItems: [QueryItem] = []
            """
        }
        
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
        let variableType = details.body?.key != nil ? "var" : "let"
        var requestImpl = """
        
            \(variableType) request = prepareBasicRequest(url: url, method: "\(details.method)", queryItems: _queryItems, headers: headers)\n
        """
        
        if details.isUploadingFile, let body = details.body?.key {
            requestImpl += """
            
                if (headers["Content-Type"] as? String) == nil {
                    request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                }
            
                request.httpBody = Snowdrop.core.dataWithBoundary(\(body), payloadDescription: _payloadDescription)\n
            """
        } else if let body = details.body?.key {
            requestImpl += """
                var data: Data?
            
                if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                    data = Snowdrop.core.prepareUrlEncodedBody(data: \(body))
                } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                    data = Snowdrop.core.prepareBody(data: \(body))
                }
            
                request.httpBody = data\n
            """
        }
        
        if let _ = details.returnType {
            requestImpl += """
                
                return try\(details.doesThrow ? "" : "?") await Snowdrop.core.performRequestAndDecode(request, service: self)
            """
        } else {
            requestImpl += """
                _ = try\(details.doesThrow ? "" : "?") await Snowdrop.core.performRequest(request, service: self)
            """
        }
        
        return requestImpl
    }
}
