//
//  MimeType.swift
//
//
//  Created by Maciej Burdzicki on 21/04/2024.
//

import Foundation

enum MimeType: String {
    case jpeg = "image/jpeg"
    case png = "image/png"
    case gif = "image/gif"
    case tiff = "image/tiff"
    case pdf = "application/pdf"
    case vnd = "application/vnd"
    case plain = "text/plain"
    case octetStream = "application/octet-stream"
    
    init(from data: Data) {
        var mimeByte: UInt8 = 0
        data.copyBytes(to: &mimeByte, count: 1)
        
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
