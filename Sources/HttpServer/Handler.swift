//
//  Handler.swift
//  
//
//  Created by Miguel Fermin on 7/7/21.
//

public protocol Handler {
    func handle(request: Request, response: ResponseWriter, next upperNext: @escaping Next)
}
