import NIOSSL
// import Fluent
// import FluentMySQLDriver
// import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    //app.databases.use(DatabaseConfigurationFactory.mysql(
    //    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
    //    port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
    //    username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
    //    password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
    //    database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    //), as: .mysql)

    //app.migrations.add(CreateTodo())

    //app.views.use(.leaf)

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)

    app.middleware.use(cors, at: .beginning)
    try routes(app)
}
