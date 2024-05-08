//
//  ServerStatus.swift
//  
//
//  Created by Robert Cheal on 10/21/20.
//

import Vapor
import MyMusic

var myMusicApiVersions = "v1"  // comma separated list of supported api versions

class ServerState {
    static var shared = ServerState()
    
    
    var startDate: Date
    
    var upTime: Double {
        get {
            Date().timeIntervalSince(startDate)
        }
    }

    
    init() {
        startDate = Date()
    }
}

let serverState = ServerState.shared

extension APIServerStatus: Content {
    
    static func create(_ app: Application, req: Request? = nil) async throws -> APIServerStatus {
        var serverStatus = APIServerStatus()
        serverStatus.version = myMusicServerVersion
        serverStatus.apiVersions = myMusicApiVersions
        let hostname = app.http.server.configuration.hostname
        
        let ds = Datastore.shared()
        
        serverStatus.upTime = Int(serverState.upTime)
        
        serverStatus.name = app.http.server.configuration.serverName ?? Host.current().localizedName ?? "Unknown"
        serverStatus.address = "\(hostname):\(app.http.server.configuration.port)"
        serverStatus.albumCount = try await ds.getAlbumCount()
        serverStatus.singleCount = try await ds.getSingleCount()
        serverStatus.playlistCount = try await ds.getPlaylistCount()
        serverStatus.lastTransactionTime = ds.getLastTransactionTime()
        return serverStatus
    }

    static func create(req: Request) async throws ->APIServerStatus {
        let app = req.application
        var serverStatus = APIServerStatus()
        serverStatus.version = myMusicServerVersion
        serverStatus.apiVersions = myMusicApiVersions
        let hostname = app.http.server.configuration.hostname

        let ds = Datastore.shared()

        serverStatus.upTime = Int(serverState.upTime)

        serverStatus.name = app.http.server.configuration.serverName ?? Host.current().localizedName ?? "Unknown"
        serverStatus.address = "\(hostname):\(app.http.server.configuration.port)"
        serverStatus.albumCount = try await ds.getAlbumCount()
        serverStatus.singleCount = try await ds.getSingleCount()
        serverStatus.playlistCount = try await ds.getPlaylistCount()
        serverStatus.lastTransactionTime = ds.getLastTransactionTime()
        return serverStatus
    }
        
}
