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
import struct Foundation.URLComponents

public class Request {
    fileprivate let header: HTTPRequestHead
    private var body: ByteBuffer?
    private var end: HTTPHeaders?
    
    public var context: [String: Any] = [:]
    public var queryItems: [String: String] = [:]
    public var namedParams: [String: String] = [:]
    
    init(header: HTTPRequestHead, body: ByteBuffer?, end: HTTPHeaders?) {
        self.header = header
        self.body = body
        self.end = end
    }
}

// MARK: - API
extension Request {
    public var uri: String { header.uri }
    
    public var method: HTTPMethod { header.method }
    
    public func headerValue(forKey key: String) -> String? { header.headers[key].first }
    
    public func decodedBody<T: Decodable>() throws -> T {
        guard let body = body else {
            throw HttpServerError.decoding(dict: ["title": "Missing Request Body"])
        }
        do {
            return try JSONDecoder().decode(T.self, from: body)
        } catch DecodingError.keyNotFound(let key, _) {
            throw HttpServerError.decoding(dict: [key.stringValue: "Missing"])
        } catch DecodingError.typeMismatch(_, let context) {
            let title = context.codingPath.first?.stringValue ?? ""
            let description = context.debugDescription
            throw HttpServerError.decoding(dict: [title : description])
        }
    }
}

// MARK: - Helpers
extension Request {
    func prepareAndValidate(path: String, method: HTTPMethod) -> Bool {
        guard header.method == method else {
            return false
        }
        guard let requestPath = URLComponents(string: uri)?.path else {
            return false
        }
        var hasNamedParam = false
        if path.contains(":") {
            let comps = path.split(separator: ":")
            if comps.count > 1, let name = comps.last {
                if let value = requestPath.split(separator: "/").last {
                    hasNamedParam = true
                    namedParams[String(name)] = String(value)
                }
            }
        }
        // Named parameters only match a single path segment
        if hasNamedParam {
            if requestPath.split(separator: "/").dropLast() != path.split(separator: "/").dropLast() {
                return false
            }
        } else {
            guard (requestPath == path || requestPath == "\(path)/") else {
                return false
            }
        }
        return true
    }
}
