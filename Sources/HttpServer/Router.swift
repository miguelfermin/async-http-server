//
//  Router.swift
//  
//
//  Created by Miguel Fermin on 7/7/21.
//

import NIOHTTP1

public final class Router {
    private var middleware = [HandleFunc]()
    
    public init() {
        use(Middleware.queryString)
    }
    
    public func use(_ middleware: HandleFunc...) {
        self.middleware.append(contentsOf: middleware)
    }
}

// MARK: - Routes+Handler
extension Router: Handler {
    /// Request handler. Calls its middleware list in sequence until one doesn't call **next()**.
    func handle(request: Request, response: ResponseWriter, next upperNext: @escaping Next) {
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
#if compiler(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension Router {
    public func handle<O: Codable>(
        path: String,
        method: HTTPMethod,
        function: @escaping (Request) async throws -> O
    ) {
        use { request, response, next in
            if request.prepareAndValidate(path: path, method: method) == false {
                next()
                return
            }
            Task {
                do {
                    let output = try await function(request)
                    response.write(output, status: .ok)
                } catch {
                    if let errorProvider = (error as? ErrorInfoProvider) {
                        response.writeErrorInfo(errorProvider.errorInfo)
                    } else {
                        response.write(error.localizedDescription, status: .internalServerError)
                    }
                }
            }
        }
    }
}
#endif

// MARK: - Convenience API
#if compiler(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension Router {
    public func get<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        handle(path: path, method: .GET, function: function)
    }
    
    public func post<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        handle(path: path, method: .POST, function: function)
    }
    
    public func put<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        handle(path: path, method: .PUT, function: function)
    }
    
    public func patch<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        handle(path: path, method: .PATCH, function: function)
    }
    public func delete<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        handle(path: path, method: .DELETE, function: function)
    }
}
#endif
