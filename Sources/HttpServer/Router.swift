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
    public func get<I: Codable, O: Codable>(_ path: String, function: @escaping (I) async throws -> O) {
        handle(path: path, method: .GET, function: function)
    }
    
    public func post<I: Codable, O: Codable>(_ path: String, function: @escaping (I) async throws -> O) {
        handle(path: path, method: .POST, function: function)
    }
    
    public func put<I: Codable, O: Codable>(_ path: String, function: @escaping (I) async throws -> O) {
        handle(path: path, method: .PUT, function: function)
    }
    
    public func patch<I: Codable, O: Codable>(_ path: String, function: @escaping (I) async throws -> O) {
        handle(path: path, method: .PATCH, function: function)
    }
    
    public func delete<I: Codable, O: Codable>(_ path: String, function: @escaping (I) async throws -> O) {
        handle(path: path, method: .DELETE, function: function)
    }
    
    public func handle<I: Codable, O: Codable>(path: String, method: HTTPMethod, function: @escaping (I) async throws -> O) {
        use { request, response, next in
            guard let first = request.uri.split(separator: "?").first, request.method == method, (first == path || first == "\(path)/") else {
                next()
                return
            }
            Task {
                do {
                    let input: I = try request.model()
                    let output = try await function(input)
                    response.write(output, status: .ok)
                } catch RequestDecodingError.info(let info) {
                    response.write(info, status: .badRequest)
                } catch {
                    if let errorProvider = (error as? ErrorInfoProvider), let errorInfo = errorProvider.errorInfo {
                        response.write(errorInfo.data, status: errorInfo.status)
                    } else {
                        response.write(error.localizedDescription, status: .internalServerError)
                    }
                }
            }
        }
    }
}

#endif
