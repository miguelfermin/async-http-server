//
//  HTTPServer.swift
//
//
//  Created by Miguel Fermin on 7/7/21.
//

import NIO
import NIOHTTP1
import struct Foundation.UUID

final public class HTTPServer {
    let router: Router
    let eventLoopGroup: MultiThreadedEventLoopGroup
    
    public init(eventLoopGroup: MultiThreadedEventLoopGroup) {
        self.router = Router()
        self.eventLoopGroup = eventLoopGroup
    }
    
    /// Adds middleware HandleFunc to be invoked on every handled request.
    /// - important: Your implementation must call **next()** to pass on control to next middleware.
    /// - note: You can also add middleware on a per-handler basis when setting up your routes.
    /// - Parameter middleware: The middleware HandleFunc to add.
    public func addMiddlewareHandler(_ middleware: @escaping HandleFunc) {
        router.use(middleware)
    }

    /// Starts listening and serving requests.
    /// - Parameters:
    ///   - host: The host to bind on.
    ///   - port: The port to bind on.
    public func listenAndServe(host: String, port: Int) throws {
        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)
        
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(ChannelHandler(handler: self.router))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(reuseAddrOpt, value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
        
        let channel = try bootstrap.bind(host: host, port: port).wait()
        print("Server running on: \(channel.localAddress!)")
        
        try channel.closeFuture.wait()
    }
}

// MARK: - Routes
#if compiler(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension HTTPServer {
    public func get<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        router.handle(path: path, method: .GET, function: function)
    }
    
    public func post<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        router.handle(path: path, method: .POST, function: function)
    }
    
    public func put<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        router.handle(path: path, method: .PUT, function: function)
    }
    
    public func patch<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        router.handle(path: path, method: .PATCH, function: function)
    }
    
    public func delete<O: Codable>(_ path: String, function: @escaping (Request) async throws -> O) {
        router.handle(path: path, method: .DELETE, function: function)
    }
}
#endif

// MARK: - ChannelHandler
private class ChannelHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    private let handler: Handler
    private var tasks: [RequestTask] = []
    
    fileprivate init(handler: Handler) {
        self.handler = handler
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = unwrapInboundIn(data)
        switch requestPart {
        case .head(let header):
            tasks.append(RequestTask(header: header))
        case .body(let body):
            tasks.last?.body = body
        case .end(let end):
            tasks.last?.end = end
            tasks.last?.complete(with: handler, context: context)
            _ = tasks.popLast()
        }
    }
}

// MARK: - RequestTask
private class RequestTask {
    let id = UUID().uuidString
    let header: HTTPRequestHead
    var body: ByteBuffer?
    var end: HTTPHeaders?
    
    init(header: HTTPRequestHead) {
        self.header = header
    }
    
    func complete(with handler: Handler, context: ChannelHandlerContext) {
        let request = Request(header: header, body: body, end: end)
        let response = DefaultResponseWriter(channel: context.channel)
        handler.handle(request: request, response: response) { (items: Any...) in
            response.write("Resource Not Found", status: .notFound)
        }
    }
}
