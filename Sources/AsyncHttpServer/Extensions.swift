//
//  Extensions.swift
//  
//
//  Created by Miguel Fermin on 2/13/22.
//

import struct Foundation.Data
import class  Foundation.JSONEncoder

// MARK: - Encodable
extension Encodable {
    public func jsonEncoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
