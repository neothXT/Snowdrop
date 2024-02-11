//
//  RequestBuilder.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

class RequestBuilder {
    private init() {}
    
    static func build(details: FuncBodyDetails) -> String {
        var requestImpl = """
        
            if !queryItems.isEmpty {
                url.append(queryItems: queryItems)
            }
        
            var request = URLRequest(url: url)
        
            request.httpMethod = "\(details.method)"
        
            headers.forEach { key, value in
                request.addValue("\\(value)", forHTTPHeaderField: key)
            }\n\n
        """
        
        if details.requiresAccessToken {
            requestImpl += """
                let token = Netty.Config.accessTokenStorage.fetch(for: \(details.serviceName).tokenLabel)?.access_token
                request.addValue("Bearer \\(token ?? "")", forHTTPHeaderField: "Authorization")\n\n
            """
        }
        
        if details.isUploadingFile, let body = details.body?.key {
            requestImpl += """
                if (headers["Content-Type"] as? String) == nil {
                    request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
                }
            
                request.httpBody = Netty.Core.dataWithBoundary(\(body), payloadDescription: payloadDescription)\n\n
            """
        } else if let body = details.body?.key {
            requestImpl += """
                var data: Data?
            
                if let header = headers["Content-Type"] as? String, header == "application/x-www-form-urlencoded" {
                    data = Netty.Core.prepareUrlEncodedBody(data: \(body))
                } else if let header = headers["Content-Type"] as? String, header == "application/json" {
                    data = Netty.Core.prepareBody(data: \(body))
                }
            
                request.httpBody = data\n\n
            """
        }
        
        requestImpl += """
            request = \(details.serviceName).beforeSending?(request) ?? request
            let session = Netty.Config.getSession()
        
            return try await Netty.Core.sendRequest(session: session,
                                                    request: request,
                                                    requiresAccessToken: \(details.requiresAccessToken), 
                                                    tokenLabel: \(details.serviceName).tokenLabel, 
                                                    onResponse: \(details.serviceName).onResponse) {
                try await \(details.serviceName).onAuthRetry?(self)
            }
        """
        
        return requestImpl
    }
}

extension RequestBuilder {
    struct FuncBodyDetails {
        let url: String
        let method: String
        let headers: String
        let body: EnrichedParameter?
        let returnType: String
        let requiresAccessToken: Bool
        let isUploadingFile: Bool
        let serviceName: String
    }
}
