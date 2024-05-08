import Vapor
import Fluent
import FluentSQL
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    
    var isMemory = false
    
    switch app.environment {
    case .production:
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 8080
        app.http.server.configuration.serverName = "MyMusic-Server"
    case .testing:
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = 8888
        app.http.server.configuration.serverName = "Roberts-Mac-Studio"
        isMemory = true
    case .development:
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 7180
        app.http.server.configuration.serverName = "Roberts-Mac-Studio"
    default:
        break
            
    }

    let dbUser = Environment.get("DB_USER") ?? "bob"
    let dbPassword = Environment.get("DB_PASSWORD") ?? ""
    let database = Environment.get("DATABASE") ?? "mymusic"
    let dbHostname = Environment.get("DB_HOSTNAME") ?? "localhost"
    let dbPort = Int(Environment.get("DB_PORT") ?? "5432") ?? 5432

    let dbConfig = SQLPostgresConfiguration(hostname: dbHostname, port: dbPort, username: dbUser, password: dbPassword, database: database, tls: .disable)
    let dbConfigTest = SQLPostgresConfiguration(hostname: dbHostname, port: dbPort, username: dbUser, password: dbPassword, database: "\(database)test", tls: .disable)
    let dbConfigDev = SQLPostgresConfiguration(hostname: dbHostname, port: dbPort, username: dbUser, password: dbPassword, database: "\(database)dev", tls: .disable)

    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let subDirectory = isMemory ? "MyMusicPiServerMemoryFiles" : "MyMusicServerFiles"
    let homeURL = FileManager.default.homeDirectoryForCurrentUser
    let baseURL = homeURL.appendingPathComponent(subDirectory)
    Datastore.baseURL = baseURL
    
    let fm = FileManager()
    if !fm.fileExists(atPath: baseURL.path) {
        try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
    Datastore.baseURL = baseURL
    switch app.environment {
    case .production:
        app.databases.use(.postgres(configuration: dbConfig), as: .psql)
    case .testing:
        app.databases.use(.postgres(configuration: dbConfigTest), as: .psql)
    case .development:
        app.databases.use(.postgres(configuration: dbConfigDev), as: .psql)
    default:
        break
    }

    Datastore.db = app.db
    let _ = Datastore.create(memory: isMemory)

    app.migrations.add(CreateMyMusicDB())
    let _ = app.autoMigrate()

    // register routes
    try routes(app)
}
