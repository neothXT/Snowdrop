//
//  SnowdropConfig.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 11/02/2024.
//

import Foundation

public extension Snowdrop {
    class Config {
        public static var pinningModes: PinningMode = PinningMode(rawValue: 0)
        public static var urlsExcludedFromPinning: [String] = []
        public static var defaultJSONDecoder: JSONDecoder = .init()
        private(set) public static var accessTokenStorage: AccessTokenStorage = DefaultStorage()
        public static var accessTokenErrorCodes: [Int] = [401]
        
        public static func setAccessTokenStorage(_ storage: AccessTokenStorage) {
            accessTokenStorage = storage
        }
        
        public static func getSession(ignorePinning: Bool = false) -> URLSession {
            let operationQueue = OperationQueue()
            operationQueue.qualityOfService = .utility
            
            if pinningModes.rawValue == 0 || ignorePinning {
                return URLSession(configuration: .default,
                                  delegate: nil,
                                  delegateQueue: operationQueue)
            }
            
            let delegate = SessionDelegate(mode: pinningModes, excludedURLs: urlsExcludedFromPinning)
            return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
        }
    }
}
