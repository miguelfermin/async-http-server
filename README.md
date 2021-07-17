# HttpServer

Simple HTTP Server built with [SwiftNIO](https://github.com/apple/swift-nio) and inspired by Go's [http](https://golang.org/pkg/net/http/) package

## Example

1. Create Router
```swift
let router = Router()
```
2. Add Middleware
```swift
router.use(
    Middleware.cors(allowOrigin: "*"),
    myCustomMiddleware
)
```
3. Add Handlers
```swift
// GET List
router.get("/v1/devices") { req, res, _ in
    let devices = DataSource.fetchDevices()
    res.write(devices, status: .ok)
}

// GET One
router.get("/v1/device") { req, res, _ in
    guard let param = req.param("id"), let id = Int(param) else {
        res.write("Missing query param \"id\"", status: .badRequest)
        return
    }
    guard let device = DataSource.device(id: id) else {
        res.write("Device not found", status: .notFound)
        return
    }
    res.write(device, status: .ok)
}

// POST
router.post("/v1/devices") { req, res, _ in
    do {
        let device: Device = try req.model()
        let savedDevice = try DataSource.addDevice(device)
        res.write(savedDevice, status: .ok)
    } catch RequestDecodingError.info(let info) {
        res.write(info, status: .badRequest)
    } catch SaveDeviceError.info(let info, let status) {
        res.write(info, status: status)
    } catch {
        res.write(error.localizedDescription, status: .internalServerError)
    }
}

// DELETE
router.delete("/v1/device") { req, res, _ in
    do {
        let device: Device = try req.model()
        try DataSource.deleteDevice(id: device.id)
        res.write("Device deleted", status: .ok)
    } catch RequestDecodingError.info(let info) {
        res.write(info, status: .badRequest)
    } catch DeleteDeviceError.info(let info, let status) {
        res.write(info, status: status)
    } catch {
        res.write(error.localizedDescription, status: .internalServerError)
    }
}
```
4. Start Server
```swift
let server = Server()
let host = "localhost"
let port = 1338

try server.listenAndServe(host: host, port: port, handler: router)
```


## References:
- [SwiftNIO](https://github.com/apple/swift-nio)
- [Go's http package](https://golang.org/pkg/net/http/)
- [The Always Right Institute](https://www.alwaysrightinstitute.com/microexpress-nio2/)
- [raywenderlich](https://www.raywenderlich.com/8016626-swiftnio-tutorial-practical-guide-for-asynchronous-problems)
