//
//  Service.swift
//
//
//  Created by Maciej Burdzicki on 21/04/2024.
//

import Foundation

public protocol Service {
    var baseUrl: URL { get }

    static var beforeSending: ((URLRequest) -> URLRequest)? { get set }
    static var onResponse: ((Data?, HTTPURLResponse) -> Data?)? { get set }

    init(baseUrl: URL)
}
