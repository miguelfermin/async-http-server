//
//  Request.swift
//  
//
//  Created by Miguel Fermin on 7/7/21.
//

import NIO
import NIOHTTP1
import NIOFoundationCompat
import class  Foundation.JSONDecoder

public class Request {
    private let header: HTTPRequestHead
    private var body: ByteBuffer?
    private var end: HTTPHeaders?
    var urlData = RequestURLData()
    
    init(header: HTTPRequestHead, body: ByteBuffer?, end: HTTPHeaders?) {
        self.header = header
        self.body = body
        self.end = end
    }
    
    public var uri: String { header.uri }
    
    public var method: HTTPMethod { header.method }
    
    public func headerValue(key: String) -> String? {
        header.headers[key].first
    }
}

// MARK: - Decoding
extension Request {
    public func model<T: Decodable>() throws -> T {
        guard let body = body else {
            let info = RequestDecodingError.Info(title: "Missing Request Body", description: "")
            throw RequestDecodingError.info(info: info)
        }
        do {
            return try JSONDecoder().decode(T.self, from: body)
        } catch DecodingError.keyNotFound(let key, _) {
            let info = RequestDecodingError.Info(title: key.stringValue, description: "Missing")
            throw RequestDecodingError.info(info: info)
        } catch DecodingError.typeMismatch(_, let context) {
            let title = context.codingPath.first?.stringValue ?? ""
            let description = context.debugDescription
            let info = RequestDecodingError.Info(title: title, description: description)
            throw RequestDecodingError.info(info: info)
        }
    }
}

// MARK: - RequestURLData
public struct RequestURLData: Codable {
    public internal(set) var queryItems: [String: String] = [:]
    public internal(set) var namedParams: [String: String] = [:]
}

// MARK: - RequestDecodingError
public enum RequestDecodingError: Error {
    case info(info: Info)
    
    public struct Info: Codable {
        public let title: String
        public let description: String
    }
}
