//
//  RequestBuilder.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

class RequestBuilder {
    private init() {}
    
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
            
                request.httpBody = Snowdrop.Core.dataWithBoundary(\(body), payloadDescription: _payloadDescription)\n\n
            """
        } else if let body = details.body?.key {
            requestImpl += """
                var data: Data?
            
                if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                    data = Snowdrop.Core.prepareUrlEncodedBody(data: \(body))
                } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                    data = Snowdrop.Core.prepareBody(data: \(body))
                }
            
                request.httpBody = data\n\n
            """
        }
        
        requestImpl += """
            request = \(details.serviceName).beforeSending?(request) ?? request
            let session = Snowdrop.Config.getSession()\n\n
        """
        
        if let _ = details.returnType {
            requestImpl += """
                return try\(details.doesThrow ? "" : "?") await Snowdrop.Core.performRequestAndDecode(session: session,
                                                                        request: request,
                                                                        onResponse: \(details.serviceName).onResponse)
            """
        } else {
            requestImpl += """
                _ = try\(details.doesThrow ? "" : "?") await Snowdrop.Core.performRequest(session: session,
                                                            request: request,
                                                            onResponse: \(details.serviceName).onResponse)
            """
        }
        
        return requestImpl
    }
}

extension RequestBuilder {
    struct FuncBodyDetails {
        let url: String
        let method: String
        let headers: String
        let body: EnrichedParameter?
        let returnType: String?
        let isUploadingFile: Bool
        let serviceName: String
        let doesThrow: Bool
    }
}
