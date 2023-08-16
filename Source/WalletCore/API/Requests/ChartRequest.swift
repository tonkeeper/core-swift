//
//  ChartRequest.swift
//
//
//  Created by Grigory on 15.8.23..
//

import Foundation
import TonAPI

struct ChartRequest: APIRequest {
    typealias Entity = ChartEntity
    
    var request: Request {
        Request(path: path,
                method: .GET,
                headers: [],
                queryItems: queryItems,
                bodyParameter: [:])
    }
    
    let path = "/stock/chart-new"
    var queryItems: [URLQueryItem] {
        [
            .init(name: "period", value: period)
        ]
    }
    
    let period: String
    
    init(period: String) {
        self.period = period
    }
}
