import Foundation
import os

/// Answers requests on a `URLSession` built by `makeSession()` with the stub
/// for their URL path (or the fallback), and records the requests. Suites
/// using it must be serialized.
final class StubURLProtocol: URLProtocol {
    enum Response: Sendable {
        case http(status: Int, body: String)
        case failure(URLError.Code)
    }

    private struct State {
        var routes: [String: Response] = [:]
        var fallback: Response = .http(status: 200, body: "{}")
        var requests: [URLRequest] = []
    }

    private static let state = OSAllocatedUnfairLock(initialState: State())

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Every request gets `response`.
    static func stub(_ response: Response) {
        state.withLock { $0 = State(fallback: response) }
    }

    /// Requests whose URL path is a key get that response; others get `fallback`.
    static func stub(routes: [String: Response], fallback: Response = .failure(.notConnectedToInternet)) {
        state.withLock { $0 = State(routes: routes, fallback: fallback) }
    }

    static var requests: [URLRequest] {
        state.withLock { $0.requests }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let request = request
        let response = Self.state.withLock { state in
            state.requests.append(request)
            return state.routes[request.url?.path ?? ""] ?? state.fallback
        }
        switch response {
        case .http(let status, let body):
            let http = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
    }

    override func stopLoading() {}
}

extension URLRequest {
    /// The request body, also when URLSession moved it into a stream.
    var bodyData: Data? {
        if let httpBody { return httpBody }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
