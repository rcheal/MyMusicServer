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
        app.http.server.configuration.port = 7180
    case .testing:
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = 8888
        isMemory = true
    case .development:
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 7180
    default:
        break
            
    }
    
    
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
        app.databases.use(.postgres(hostname: "localhost", port: 5432, username: "bob", password: "", database: "mymusic"), as: .psql)
    case .testing:
        app.databases.use(.postgres(hostname: "localhost", port: 5432, username: "bob", password: "", database: "mymusictest"), as: .psql)
    case .development:
        app.databases.use(.postgres(hostname: "localhost", port: 5432, username: "bob", password: "", database: "mymusicdev"), as: .psql)
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
