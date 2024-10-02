// import Fluent
import Vapor

func routes(_ app: Application) throws {

    struct Hello: Content {
        var name: String?
    }

    
    app.get("hello") { req -> String in
        let hello = try req.query.decode(Hello.self)
        return "Hello, \(hello.name ?? "Anonymous")"
    }
    
    app.get("hello", ":name") {req -> String in
        guard let name = req.parameters.get("name", as: Int.self) else {
            throw Abort.redirect(to: "https://intron014.com/404")
        }
        return "\(name) wooo"
    }
    
    
    
    try app.register(collection: BicimadController())
    try app.register(collection: ClipboardController())
}
