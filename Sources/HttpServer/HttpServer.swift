//
//  HttpServer.swift
//
//
//  Created by Miguel Fermin on 7/7/21.
//

import NIO
import NIOHTTP1
import struct Foundation.UUID

public class HttpServer {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    public init() {}
    
    public func listenAndServe(host: String, port: Int, handler: Handler) throws {
        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
        
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline()
                    .flatMap {
                        channel.pipeline.addHandler(ChannelHandler(handler: handler))
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
