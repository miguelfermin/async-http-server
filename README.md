# AsyncHttpServer

Naive implementation of a simple HTTP Server. Built with [SwiftNIO](https://github.com/apple/swift-nio).

> The short-term goal of this package is to experiment with SwiftNIO and design a simple HTTP Server API. Once the API design is done, the second step will be to build a robust implementation that could be use in production. 

## Example

```swift

// Setup
let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

let server = HTTPServer(eventLoopGroup: eventLoopGroup)

defer {
    try? eventLoopGroup.syncShutdownGracefully()
}

try server.listenAndServe(host: "localhost", port: 8000)

// Routes
server.post("/v1/todo", function: createTodo)
server.get("/v1/todo", function: getTodoList)
server.get("/v1/todo/:id", function: getTodo)

// Handlers
func getTodoList(request: Request) async throws -> [TodoResponse] {
    ...
}

func getTodo(request: Request) async throws -> TodoResponse {
    guard let id = request.params["id"] else {
        throw TodoError(code: 14, message: "id required", statusCode: 400)
    }
    ...
}

func createTodo(request: Request) async throws -> CreateTodoResponse {
    let todo: CreateTodoRequest = try request.decodedBody()
    
    ...
}
```

## References:
- [SwiftNIO](https://github.com/apple/swift-nio)
- [The Always Right Institute](https://www.alwaysrightinstitute.com/microexpress-nio2/)
