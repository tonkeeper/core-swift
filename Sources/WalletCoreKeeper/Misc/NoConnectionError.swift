//
//  NoConnectionError.swift
//  
//
//  Created by Grigory Serebryanyy on 25.10.2023.
//

import Foundation
import OpenAPIRuntime

public extension Swift.Error {
    var isNoConnectionError: Bool {
        switch self {
        case let urlError as URLError:
            switch urlError.code {
            case URLError.Code.notConnectedToInternet,
                URLError.Code.networkConnectionLost,
                URLError.Code.cannotConnectToHost:
                return true
            default: return false
            }
        case let clientError as OpenAPIRuntime.ClientError:
            return clientError.underlyingError.isNoConnectionError
        default:
            return false
        }
    }
}
