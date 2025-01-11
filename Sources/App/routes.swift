// import Fluent
import Vapor

func routes(_ app: Application) throws {

    struct Hello: Content {
        var name: String?
    }

    struct HealthResponse: Content {
        var status: [String]
        var version: String
    }

    let statusMessages = [
        "All systems go!",
        "Running smoothly!",
        "Everything is awesome!",
        "Service is up and running!",
        "All good here!"
    ]

    @Sendable
    func getHealthResponse() -> HealthResponse {
        let randomStatus = statusMessages.randomElement() ?? "ok"
        return HealthResponse(status: [randomStatus], version: "1.3.3")
    }

    app.get("health") { req -> HealthResponse in
        return getHealthResponse()
    }

    app.get("") { req -> HealthResponse in
        return getHealthResponse()
    }
    
    app.get("webfiles", "**") { req -> Response in
        let path = req.parameters.getCatchall().joined(separator: "/")
        let filePath = app.directory.workingDirectory + "webfiles/" + path
        return req.fileio.streamFile(at: filePath)
    }
    
    
    
    try app.register(collection: BicimadController())
    try app.register(collection: EMTController())
    try app.register(collection: ClipboardController())
    try app.register(collection: LastFMController())
    try app.register(collection: GasopriceController())
    try app.register(collection: YouTubeAnalyticsController())
}
