//
//  Error.swift
//  
//
//  Created by Miguel Fermin on 2/13/22.
//


import NIOHTTP1
import struct Foundation.Data

public protocol ErrorInfoProvider {
    var errorInfo: ErrorInfo? { get }
}

public struct ErrorInfo {
    public let data: Data
    public let status: HTTPResponseStatus
    
    public init(data: Data, statusCode: Int) {
        self.data = data
        self.status = HTTPResponseStatus(statusCode: statusCode)
    }
}

