//
//  MimeType.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 21/04/2024.
//

import Foundation

public protocol DataConvertible {
    func toData() -> Data
}

extension Data: DataConvertible {
    public func toData() -> Data {
        self
    }
}

public enum MimeType: String {
    case jpeg = "image/jpeg"
    case png = "image/png"
    case gif = "image/gif"
    case tiff = "image/tiff"
    case pdf = "application/pdf"
    case vnd = "application/vnd"
    case plain = "text/plain"
    case octetStream = "application/octet-stream"
    
    public init?(fromFile file: DataConvertible) {
        var mimeByte: UInt8 = 0
        file.toData().copyBytes(to: &mimeByte, count: 1)
        
        switch mimeByte {
        case 0xFF:
            self = .jpeg
        case 0x89:
            self = .png
        case 0x47:
            self = .gif
        case 0x4D, 0x49:
            self = .tiff
        case 0x25:
            self = .pdf
        case 0xD0:
            self = .vnd
        case 0x46:
            self = .plain
        default:
            self = .octetStream
        }
    }
}
