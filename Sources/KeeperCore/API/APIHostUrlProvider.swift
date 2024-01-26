import Foundation
import TonAPI
import OpenAPIRuntime
import HTTPTypes

final class APIHostUrlProvider: ClientMiddleware {
  func intercept(_ request: HTTPTypes.HTTPRequest,
                 body: OpenAPIRuntime.HTTPBody?,
                 baseURL: URL,
                 operationID: String,
                 next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, URL)
                 async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?))
  async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
    let url = URL(string: "https://keeper.tonapi.io") ?? baseURL
    
    var mutableRequest = request
    mutableRequest
        .headerFields
        .append(
            .init(name: .authorization,
                  value: "Bearer AF77F5JNEUSNXPQAAAAMDXXG7RBQ3IRP6PC2HTHL4KYRWMZYOUQGDEKYFDKBETZ6FDVZJBI")
        )
    return try await next(mutableRequest, body, url)
  }
}
