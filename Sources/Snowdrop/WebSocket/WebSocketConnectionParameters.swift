//
//  WebSocketConnectionParameters.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 04/02/2024.
//

import Foundation

public struct WebSocketConnectionParameters {
    public let url: URL?
    public let protocols: [String]
    public let ignorePinning: Bool
    public let request: URLRequest?
    
    public init(url: URL, protocols: [String], ignorePinning: Bool) {
        self.url = url
        self.protocols = protocols
        self.ignorePinning = ignorePinning
        self.request = nil
    }
    
    public init(request: URLRequest, ignorePinning: Bool) {
        self.url = request.url
        self.protocols = []
        self.ignorePinning = ignorePinning
        self.request = request
    }
}
