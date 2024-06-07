//
//  SnowdropError.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public struct SnowdropError: Error {
    public let type: ErrorType
    public let details: SnowdropErrorDetails?
    /// Data returned by the request
    public let data: Data?
    
    public init(type: ErrorType, details: SnowdropErrorDetails? = nil, data: Data? = nil) {
        self.type = type
        self.details = details
        self.data = data
    }
}

public extension SnowdropError {
    enum ErrorType {
        case failedToMapResponse, unexpectedResponse, noInternetConnection, unknown
    }
    
    var errorDescription: String? {
        switch type {
        case .failedToMapResponse:
            return "Failed to map response."
            
        case .unexpectedResponse:
            return "Unexpected response."
            
        case .noInternetConnection:
            return "Please check your internet connection."
        
        case .unknown:
            return "Unknown"
        }
    }
}

public struct SnowdropErrorDetails {
    public let statusCode: Int
    public let localizedString: String
    public let url: URL?
    public let mimeType: String?
    public let headers: [AnyHashable: Any]?
    /// Original (underlying) error
    public let ogError: Error?
    
    public init(
        statusCode: Int,
        localizedString: String,
        url: URL? = nil,
        mimeType: String? = nil,
        headers: [AnyHashable: Any]? = nil,
        ogError: Error? = nil
    ) {
        self.statusCode = statusCode
        self.localizedString = localizedString
        self.url = url
        self.mimeType = mimeType
        self.headers = headers
        self.ogError = ogError
    }
}
