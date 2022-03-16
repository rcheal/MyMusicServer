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

    // MARK: *** Server ***

    // MARK: GET /
    app.get { req -> APIServerStatus in
        return APIServerStatus.create(app, req: req)
    }
    
    // MARK GET /v1
    try app.group("v1") { version in
        try routeVersion1(app, version)
    }
    
    // MARK GET /v2
//    app.group("v2") { version in
//
//        version.get { req -> Int in
//            throw Abort(.notImplemented)
//
//        }
//    }
}

func routeVersion1(_ app: Application, _ ver: RoutesBuilder) throws {

    let ds = Datastore.shared()

    
    // MARK: GET /v1
    ver.get { req -> APIServerStatus in
        return APIServerStatus.create(app, req: req)
    }
    
    // MARK: GET /transactions?startTime=:time
    ver.get("transactions") { req -> APITransactions in
        let query = try req.query.decode(StartTime.self)
        if let startTime = query.startTime {
            return APITransactions(transactions: try ds.getTransactions(since: startTime))
        }
        throw Abort(.badRequest)
    }
    
    // MARK: *** Albums ***
    try ver.group("albums") { albums in
        
        try routealbums(albums)
        
    }

    // MARK: *** Singles ***
    try ver.group("singles") { singles in
        
        try routesingles(singles)
        
    }

    // MARK: *** Playlists ***
    try ver.group("playlists") { playlists in
        
        try routeplaylists(playlists)
    }
}
