//
//  Handler.swift
//  
//
//  Created by Miguel Fermin on 7/7/21.
//

public typealias Next = (Any...) -> Void
public typealias HandleFunc = (Request, ResponseWriter, @escaping Next) -> Void

public protocol Handler {
    func handle(request: Request, response: ResponseWriter, next upperNext: @escaping Next)
}
