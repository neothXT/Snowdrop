//
//  SnowdropConfig.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 11/02/2024.
//

import Foundation

public extension Snowdrop.Config {
    func getSession(ignorePinning: Bool = false) -> URLSession {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .utility
        
        if ignorePinning {
            return URLSession(configuration: .default,
                              delegate: nil,
                              delegateQueue: operationQueue)
        }
        
        let delegate = SessionDelegate(excludedURLs: urlsExcludedFromPinning)
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
    }
}
