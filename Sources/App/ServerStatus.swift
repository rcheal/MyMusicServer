//
//  ServerStatus.swift
//  
//
//  Created by Robert Cheal on 10/21/20.
//

import Vapor

var myMusicServerVersion = "0.1.1" // You must manually sync this with the git tag

class ServerState {
    static var shared = ServerState()
    
    
    var startDate: Date
    
    var upTime: String {
        get {
            let elapsedSeconds = Date().timeIntervalSince(startDate)
            let hours = Int(elapsedSeconds) / 3600
            let minutes = (Int(elapsedSeconds) % 3600) / 60
            let seconds = Int(elapsedSeconds) % 60
            return String(hours) + ":" + String(minutes) + ":" + String(seconds)
        }
    }
    
    init() {
        startDate = Date()
    }
}

let serverState = ServerState.shared

struct ServerStatus: Content {

    var version = myMusicServerVersion
    var serverName: String
    var ipAddress: String
    var port: Int
    var albumCount = 0
    var singleCount = 0
    var upTime: String
    
    init(_ app: Application) {
        upTime = serverState.upTime
        serverName = app.http.server.configuration.serverName ?? Host.current().localizedName ?? "Unknown"
        ipAddress = app.http.server.configuration.hostname
        port = app.http.server.configuration.port
    }
}
