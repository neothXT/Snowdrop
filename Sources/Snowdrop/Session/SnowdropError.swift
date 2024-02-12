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
    public let data: Data?
    
    public init(type: ErrorType, details: SnowdropErrorDetails? = nil, data: Data? = nil) {
        self.type = type
        self.details = details
        self.data = data
    }
}

public extension SnowdropError {
    enum ErrorType {
        case failedToBuildRequest, failedToMapResponse, unexpectedResponse, authenticationFailed, notConnected, emptyResponse, conversionFailed, noInternetConnection, requestFinished, finishedWithoutValue
    }
    
    var errorDescription: String? {
        switch type {
        case .conversionFailed:
            return "Conversion to AccessTokenConvertible failed."
            
        case .failedToBuildRequest:
            return "Failed to build URLRequest. Please make sure the URL is correct."
            
        case .failedToMapResponse:
            return "Failed to map response."
            
        case .unexpectedResponse:
            return "Unexpected response."
            
        case .authenticationFailed:
            return "Authentication failed."
            
        case .notConnected:
            return "There's no active WebSocket connection."
            
        case .noInternetConnection:
            return "Please check your internet connection."
            
        case .emptyResponse:
            return "Empty response."
            
        case .requestFinished:
            return "Request finished."
            
        case .finishedWithoutValue:
            return "Request finished without value."
        }
    }
}

public struct SnowdropErrorDetails {
    public let statusCode: Int
    public let localizedString: String
    public let url: URL?
    public let mimeType: String?
    public let headers: [AnyHashable: Any]?
    public let data: Data?
    
    public init(statusCode: Int, localizedString: String, url: URL? = nil, mimeType: String? = nil, headers: [AnyHashable: Any]? = nil, data: Data? = nil) {
        self.statusCode = statusCode
        self.localizedString = localizedString
        self.url = url
        self.mimeType = mimeType
        self.headers = headers
        self.data = data
    }
}
