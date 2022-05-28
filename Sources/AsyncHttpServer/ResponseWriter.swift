//
//  ResponseWriter.swift
//  
//
//  Created by Miguel Fermin on 7/7/21.
//

import NIO
import NIOHTTP1

import struct Foundation.Data
import class  Foundation.JSONEncoder

public protocol ResponseWriter {
    var headers: HTTPHeaders { get }
    func write(_ string: String)
    func write(_ data: Data, status: HTTPResponseStatus)
    func write<T: Encodable>(_ model: T, status: HTTPResponseStatus)
    func writeErrorInfo(_ errorInfo: ErrorInfo)
    func setHeader(key: String, value: String)
}

// MARK: - DefaultResponseWriter
class DefaultResponseWriter {
    private let channel: Channel
    private var status = HTTPResponseStatus.ok
    private var didWriteHeader = false
    private var didEnd = false
    
    private(set) public var headers = HTTPHeaders()
    
    init(channel: Channel) {
        self.channel = channel
    }
}

// MARK: ResponseWriter
extension DefaultResponseWriter: ResponseWriter {
    func setHeader(key: String, value: String) {
        self[key] = value
    }
    
    func write(_ string: String) {
        flushHeader()
        
        var buffer = channel.allocator.buffer(capacity: string.count)
        buffer.writeString(string)
        write(buffer)
    }
    
    func write<T: Encodable>(_ model: T, status: HTTPResponseStatus = .ok) {
        let data: Data
        do {
            data = try JSONEncoder().encode(model)
            write(data, status: status)
        } catch {
            if let data = "Server Error: \(error.localizedDescription)".data(using: .utf8) {
                write(data, status: .internalServerError)
            }
            handleError(error)
        }
    }
    
    func writeErrorInfo(_ errorInfo: ErrorInfo) {
        let data: Data
        do {
            data = try errorInfo.data.jsonEncoded()
            write(data, status: errorInfo.status)
        } catch {
            if let data = "Server Error: \(error.localizedDescription)".data(using: .utf8) {
                write(data, status: .internalServerError)
            }
            handleError(error)
        }
    }
    
    func write(_ data: Data, status: HTTPResponseStatus) {
        self["Content-Type"]   = "application/json"
        self["Content-Length"] = "\(data.count)"
        self.status = status
        flushHeader()
        var buffer = channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        write(buffer)
    }
}

// MARK: Implementation
extension DefaultResponseWriter {
    private subscript(name: String) -> String? {
        set {
            assert(!didWriteHeader, "header is out")
            if let value = newValue {
                headers.replaceOrAdd(name: name, value: value)
            } else {
                headers.remove(name: name)
            }
        }
        get {
            headers[name].joined(separator: ", ")
        }
    }
    
    /// Check whether we already wrote the response header. If not, do so.
    private func flushHeader() {
        guard !didWriteHeader else { return }
        didWriteHeader = true
        
        let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: status, headers: headers)
        let part = HTTPServerResponsePart.head(head)
        _ = channel.writeAndFlush(part)
            .recover(handleError)
    }
    
    private func handleError(_ error: Error) {
        print("ERROR:", error)
        end()
    }
    
    private func end() {
        guard !didEnd else { return }
        didEnd = true
        
        _ = channel.writeAndFlush(HTTPServerResponsePart.end(nil))
            .map {
                self.channel.close()
            }
    }
    
    private func write(_ buffer: ByteBuffer) {
        let part = HTTPServerResponsePart.body(.byteBuffer(buffer))
        _ = channel.writeAndFlush(part)
                   .recover(handleError)
                   .map(end)
    }
}
