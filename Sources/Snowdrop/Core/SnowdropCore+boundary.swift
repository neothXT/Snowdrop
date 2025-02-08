//
//  SnowdropCore+boundary.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 21/04/2024.
//

import Foundation

public extension Snowdrop.Core {
    func dataWithBoundary(_ file: Encodable, payloadDescription: PayloadDescription) -> Data {
        var data = Data()
        let contentDisposition = "Content-Disposition: form-data; name=\"\(payloadDescription.name)\"; filename=\"\(payloadDescription.fileName)\"\r\n"
        
        guard let nameData = "--\(payloadDescription.name)\r\n".data(using: .utf8),
              let closingData = "\r\n--\(payloadDescription.name)--\r\n".data(using: .utf8),
              let contentDispData = contentDisposition.data(using: .utf8),
              let contentTypeData = "Content-Type: \(payloadDescription.mimeType)\r\n\r\n".data(using: .utf8),
              let fileData = try? file.toJsonData() else {
            return data
        }
        
        data.append(nameData)
        data.append(contentDispData)
        data.append(contentTypeData)
        data.append(fileData)
        data.append(closingData)
        
        return data
    }
}
