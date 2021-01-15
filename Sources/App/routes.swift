//
//  routes.swift
//
//
//  Created by Robert Cheal on 1/15/21.
//

import Vapor
import MusicMetadata

func routes(_ app: Application) throws {
    let _ = ServerState.shared
    let ds = Datastore.shared()

    // MARK: *** Server ***
    // MARK: GET /
    app.get { req -> ServerStatus in
        return ServerStatus(app)
    }

    // MARK: DELETE /_removeAll?user=:user&password=:password
    app.delete("removeAll") { req -> HTTPResponseStatus in
        let userQuery = try req.query.decode(UserPassword.self)
        if let user = userQuery.user,
           let password = userQuery.password {
            try ds.removeAll(user: user, password: password)

        } else {
            throw Abort(.unauthorized)
        }
        return HTTPResponseStatus.ok
    }
    
    // MARK: GET /transactions?startTime=:time
    app.get("transactions") { req -> TransactionList in
        let query = try req.query.decode(StartTime.self)
        if let startTime = query.startTime {
            return TransactionList(transactions: try ds.getTransactionList(since: startTime))
        }
        throw Abort(.badRequest)
    }

    // MARK: *** Albums ***
    try app.group("albums") { albums in
        
        try routealbums(albums)
        
    }

    // MARK: *** Singles ***
    try app.group("singles") { singles in
        
        try routesingles(singles)
        
    }

    // MARK: *** Playlists ***
    try app.group("playlists") { playlists in
        
        try routeplaylists(playlists)
    }
}
