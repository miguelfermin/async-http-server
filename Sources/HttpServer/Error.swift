//
//  Error.swift
//  
//
//  Created by Miguel Fermin on 2/13/22.
//


import NIOHTTP1

public protocol ErrorInfoProvider {
    var errorInfo: ErrorInfo { get }
}

public struct ErrorInfo {
    public let data: Encodable
    public let status: HTTPResponseStatus
    
    public init(data: Encodable, statusCode: Int) {
        self.data = data
        self.status = HTTPResponseStatus(statusCode: statusCode)
    }
    
    public init(dict: [String: String], statusCode: Int) {
        self.init(data: dict, statusCode: statusCode)
    }
    
    public static var unknown: ErrorInfo {
        return ErrorInfo(dict: ["message": "Unknown Error"], statusCode: 500)
    }
}

enum HttpServerError: Error, ErrorInfoProvider {
    case pathAndHandlerMissMatch
    case decoding(dict: [String: String])
    
    var errorInfo: ErrorInfo {
        switch self {
        case .pathAndHandlerMissMatch:
            return ErrorInfo(dict: ["error": "Path Handler Miss Match"], statusCode: 500)
        case .decoding(let dict):
            return ErrorInfo(dict: dict, statusCode: 400)
        }
    }
}
