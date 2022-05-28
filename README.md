# AsyncHttpServer

Naive implementation of a simple HTTP Server. Built with [SwiftNIO](https://github.com/apple/swift-nio).

> The short-term goal of this package is to experiment with SwiftNIO and design a simple HTTP Server API. Once the API design is done, the second step will be to build a robust implementation that could be use in production. 

## Example

Setup

```swift

let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

let httpServer = HTTPServer(eventLoopGroup: eventLoopGroup)

defer {
    try? eventLoopGroup.syncShutdownGracefully()
}

try httpServer.listenAndServe(host: "localhost", port: 8000)
```
Add a handler

```swift

httpServer.post("/v1/todo/:id", function: createTodo)

httpServer.get("/v1/todos", function: getTodoList)

httpServer.get("/v1/todo/:id", function: getTodo)

func getTodoList(request: Request) async throws -> [TodoResponse] {
    ...
}

func getTodo(request: Request) async throws -> TodoResponse {
    guard let id = request.namedParams["id"] else {
        throw TodoError(code: 14, message: "id required", statusCode: 400)
    }
    ...
}

func createTodo(request: Request) async throws -> CreateTodoResponse {
    // CreateTodoRequest simple conforms to Codable
    let todo: CreateTodoRequest = try request.decodedBody()
    
    ...
}

```

## References:
- [SwiftNIO](https://github.com/apple/swift-nio)
- [Go's http package](https://golang.org/pkg/net/http/)
- [The Always Right Institute](https://www.alwaysrightinstitute.com/microexpress-nio2/)
