//
//  Router.swift
//  
//
//  Created by Miguel Fermin on 7/7/21.
//

import NIOHTTP1

public final class Router: Handler {
    private var middleware = [Middleware]()
    
    public init() {
        use(queryString)
    }
    
    public func use(_ middleware: Middleware...) {
        self.middleware.append(contentsOf: middleware)
    }
    
    /// Request handler. Calls its middleware list in sequence until one doesn't call **next()**.
    public func handle(request: Request, response: ResponseWriter, next upperNext: @escaping Next) {
        let stack = self.middleware
        guard !stack.isEmpty else { return upperNext() }
        
        var next: Next? = { (args: Any...) in }
        var i = stack.startIndex
        
        next = { (args: Any...) in
            // grab next item from matching middleware array
            let middleware = stack[i]
            i = stack.index(after: i)
            
            let isLast = i == stack.endIndex
            middleware(request, response, isLast ? upperNext : next!)
        }
        next!()
    }
}

// MARK: - Routes
extension Router {
    public func get(_ path: String, middleware: @escaping Middleware) {
        handle(path: path, method: .GET, middleware: middleware)
    }
    
    public func post(_ path: String, middleware: @escaping Middleware) {
        handle(path: path, method: .POST, middleware: middleware)
    }
    
    public func put(_ path: String, middleware: @escaping Middleware) {
        handle(path: path, method: .PUT, middleware: middleware)
    }
    
    public func patch(_ path: String, middleware: @escaping Middleware) {
        handle(path: path, method: .PATCH, middleware: middleware)
    }
    
    public func delete(_ path: String, middleware: @escaping Middleware) {
        handle(path: path, method: .DELETE, middleware: middleware)
    }
    
    public func handle(path: String, method: HTTPMethod , middleware: @escaping Middleware) {
        use { req, res, next in
            guard let first = req.uri.split(separator: "?").first, req.method == method, (first == path || first == "\(path)/") else {
                next()
                return
            }
            middleware(req, res, next)
        }
    }
}
