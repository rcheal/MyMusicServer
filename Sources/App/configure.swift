import Vapor

// configures your application
public func configure(_ app: Application) throws {
    
    switch app.environment {
    case .production:
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 8180
    case .testing:
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = 8888
        Datastore.sharedInstance = nil
        let _ = Datastore.create(memory: true)
    case .development:
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = 8180
    default:
        break
            
    }
    
    
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
