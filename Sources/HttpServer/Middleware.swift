//
//  Middleware.swift
//  
//
//  Created by Miguel Fermin on 7/7/21.
//
import struct Foundation.URLComponents

public enum Middleware {}

// MARK: - CORS
extension Middleware {
    static public func cors(allowOrigin origin: String) -> HandleFunc {
        return { req, res, next in
            res.setHeader(key: "Access-Control-Allow-Origin", value: origin)
            res.setHeader(key: "Access-Control-Allow-Headers", value: "Accept, Content-Type")
            res.setHeader(key: "Access-Control-Allow-Methods", value: "GET, OPTIONS")
            
            if req.method == .OPTIONS {
                res.setHeader(key: "Allow", value: "GET, OPTIONS")
                res.write("")
            } else {
                next()
            }
        }
    }
}

// MARK: - QueryString
private let paramDictKey = "com.mafsoftware.httpserver.query.string.param"

extension Middleware {
    /// A middleware which parses the URL query parameters.
    static func queryString(req: Request, res: ResponseWriter, next: @escaping Next) {
        if let queryItems = URLComponents(string: req.uri)?.queryItems {
            req.userInfo[paramDictKey] = Dictionary(grouping: queryItems, by: { $0.name })
                .mapValues { $0.compactMap({ $0.value })
                    .joined(separator: ",") }
        }
        // pass on control to next middleware
        next()
    }
}

public extension Request {
    /// Access query parameters, like:
    ///
    ///     let userId = req.param("id")
    ///     let token  = req.param("token")
    func param(_ id: String) -> String? {
        (userInfo[paramDictKey] as? [String: String])?[id]
    }
    
    var params: [String: String] {
        userInfo[paramDictKey] as? [String: String] ?? [:]
    }
}
