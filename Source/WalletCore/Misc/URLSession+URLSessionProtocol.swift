//
//  URLSession+URLSessionProtocol.swift
//  
//
//  Created by Grigory on 3.7.23..
//

import Foundation
import TonAPI

extension URLSession: URLSessionProtocol {}

@available(iOS, deprecated: 15.0)
extension URLSession {
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }
                
                continuation.resume(returning: (data, response))
            }
            
            task.resume()
        }
    }
}
