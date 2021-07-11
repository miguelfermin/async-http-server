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
    public var userInfo = [String: Any]()
    
    private let header: HTTPRequestHead
    private var body: ByteBuffer?
    private var end: HTTPHeaders?
    
    init(header: HTTPRequestHead, body: ByteBuffer?, end: HTTPHeaders?) {
        self.header = header
        self.body = body
        self.end = end
    }
    
    public var uri: String {
        header.uri
    }
    
    public var method: HTTPMethod {
        header.method
    }
    
    public func model<T: Decodable>() -> T? {
        guard let body = body else { return nil }
        let decoder = JSONDecoder()
        let model = try? decoder.decode(T.self, from: body)
        return model
    }
}
