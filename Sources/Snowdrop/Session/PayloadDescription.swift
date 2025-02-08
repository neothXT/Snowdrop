//
//  PayloadDescription.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 05/02/2024.
//

import Foundation

public struct PayloadDescription {
    var name: String
    var fileName: String
    var mimeType: String
    
    public init(name: String, fileName: String, mimeType: String) {
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
