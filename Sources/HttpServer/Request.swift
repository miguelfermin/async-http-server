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
    
    public func headerValue(key: String) -> String? { header.headers[key].first }
}

// MARK: - Decoding
extension Request {
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
    
    func prepareAndValidate(path: String, method: HTTPMethod) -> Bool {
        guard self.method == method else {
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
                    urlData.namedParams[String(name)] = String(value)
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

// MARK: - RequestURLData
public struct RequestURLData: Codable {
    public internal(set) var queryItems: [String: String] = [:]
    public internal(set) var namedParams: [String: String] = [:]
}

// MARK: - Input
public struct Input<I: Codable> {
    public let request: I
    public var requestURLData: RequestURLData
    
    init(_ httpRequest: Request) throws {
        if httpRequest.method == .GET {
            guard let request = httpRequest.urlData as? I else {
                throw HttpServerError.pathAndHandlerMissMatch
            }
            self.request = request
            self.requestURLData = httpRequest.urlData
        } else {
            self.request = try httpRequest.decodedBody()
            self.requestURLData = httpRequest.urlData
        }
    }
}

