# HttpServer

Naive implementation of a simple HTTP Server. Built with [SwiftNIO](https://github.com/apple/swift-nio).

> The short-term goal of this package is to experiment with SwiftNIO and design a simple HTTP Server API. Once the API design is done, the second step will be to build a robust implementation that could be use in production. 

## Example

Suppose you need a web server to allow customers to register their organizations in your backend.

### Setup

Here's how that setup would look like:
```swift
let router = Router()
let server = Server()
var logger = Logger(label: "com.mycompany.MyApp")
let httpClient = HTTPClient(eventLoopGroupProvider: .shared(server.eventLoopGroup))

defer { try? httpClient.syncShutdown() }
```

We have a `Router`, `Server`, `Logger`, and `HTTPClient`. The router and server will be used to get the server started. The logger and httpClient are dependencies to be injected in a type called `Organization`, which encapsulates functionality related to the Organization entity. We also provide a `defer { ... }` to do clean up work.

Instantiate Organization and call its `setupRoutes` method
```swift
let organization = Organization(logger: logger, httpClient: httpClient)
organization.setupRoutes(router)
```

Start the server
```swift
let host = "localhost"
let port = 1338
try server.listenAndServe(host: host, port: port, handler: router)
```
### Organization Example

This is just an example of how to use this package to provide an API for an organization entity. This package is not opinionated about how it is used.

Define Organization type and its dependencies
```swift
struct Organization {
    let logger: Logger
    let httpClient: HTTPClient
}
```
Setup HTTP endpoints to be exposed
```swift
// MARK: Routes
extension Organization {
    func setupRoutes(_ router: Router) {
        router.post("/v1/organization", function: register)
        
        ...
    }
}
```
The Router's `post` method takes a path string and a function to be called. This is perhaps the only opinionated part of this package. The function can be any function that has an input (I) parameter and returns an output (O). Both input and output conform to the Codable protocol. This function is also `async` and `throws`. Here's the definition:
```swift
public func post<I: Codable, O: Codable>(_ path: String, function: @escaping (I) async throws -> O)
```  

> This is subject to change as the package API keeps getting refined. 


Then we have the `register` method which matches the signature of the Router's `post` function parameter

```swift
extension Organization {
    /// Registers an organization with Cloud.
    /// - Parameter organization: The organization request model with information to register.
    /// - Returns: The response of registering the organization.
    func register(organization: OrganizationRequest) async throws -> OrganizationResponse {
        // This sample implementation uses AsyncHTTPClient to make an HTTP request to another HTTP server.
        // We could also connect to a database to execute queries
        
        // Request
        var request = HTTPClientRequest(url: "http://localhost:8000/api/v1/organization")
        request.headers.add(name: "ApiSecret", value: "SOME_API_SECRET")
        request.method = .POST
        request.body = .bytes(try organization.jsonEncoded())
        
        // Response
        let response = try await httpClient.execute(request, timeout: .seconds(30))
        if response.status == .ok {
            return try await response.decodedType()
        } else {
            let errorResponse: ErrorResponse = try await response.decodedType()
            logger.error("Registering Organization <\(errorResponse.message)>")
            throw APIError.errorResponse(errorResponse)
        }
    }
}
```
This sample project has an `APIError` type that conforms to a `ErrorInfoProvider`, which is defined in HttpServer package. This allows you to provide meaningful error responses to your users. You are free to structure your error types as you like, but just have to provide a `var errorInfo: ErrorInfo? { ... }` implementation. For example:
```swift
enum APIError: Error, ErrorInfoProvider {
    case errorResponse(ErrorResponse)
    case unknown
    
    var errorInfo: ErrorInfo? {
        switch self {
        case .errorResponse(let response):
            guard let data = try? response.jsonEncoded() else { return nil }
            return ErrorInfo(data: data, statusCode: response.statusCode)
        case .unknown:
            return nil
        }
    }
}

struct ErrorResponse: Error, Codable  {
    let code: Int
    let message: String
    let statusCode: Int
}
```

## References:
- [SwiftNIO](https://github.com/apple/swift-nio)
- [Go's http package](https://golang.org/pkg/net/http/)
- [The Always Right Institute](https://www.alwaysrightinstitute.com/microexpress-nio2/)
