//
//  Service.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 21/04/2024.
//

import Foundation

public protocol Service {
    var baseUrl: URL { get }

    var requestBlocks: [String: RequestHandler] { get set }
    var responseBlocks: [String: ResponseHandler] { get set }
    
    var testJSONDictionary: [String: String]? { get set }
    
    var decoder: JSONDecoder { get set }
    var pinningMode: PinningMode? { get set }
    var urlsExcludedFromPinning: [String] { get set }
    var verbose: Bool { get }

    init(baseUrl: URL,
         pinningMode: PinningMode?,
         urlsExcludedFromPinning: [String],
         decoder: JSONDecoder,
         verbose: Bool
    )
    
    func addBeforeSendingBlock(for path: String?, _ block: @escaping RequestHandler)
    func addOnResponseBlock(for path: String?, _ block: @escaping ResponseHandler)
}
