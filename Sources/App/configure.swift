import Vapor

// configures your application
public func configure(_ app: Application) throws {
    
    app.http.server.configuration.hostname = "192.168.1.20"
    app.http.server.configuration.port = 8180
    
    
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
