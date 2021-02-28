//
//  routes+playlists.swift
//  
//
//  Created by Robert Cheal on 1/15/21.
//

import Foundation
import Vapor
import MusicMetadata

func routeplaylists(_ playlists: RoutesBuilder) throws {
    
    // MARK: GET /playlists
    playlists.get { req -> APIPlaylists in
        let ds = Datastore.shared()
        let auth = try req.query.decode(UserParams.self)
        let user = auth.user
        let query = try req.query.decode(ListParams.self)
        let fields = query.fields
        let offset = query.offset ?? 0
        let limit = query.limit ?? 10
        let playlists = try ds.getPlaylists(user: user, limit: limit, offset: offset, fields: fields)
        let count = ds.getPlaylistCount()
        let metadata = APIMetadata(totalCount: count, limit: limit, offset: offset)
        return APIPlaylists(playlists: playlists, _metadata: metadata)
    }
    
    
    try playlists.group(":id") { playlist in
        
        try routeplaylist(playlist)
    }

}

func routeplaylist(_ playlist: RoutesBuilder) throws {
    let ds = Datastore.shared()

    // MARK: HEAD /playlists/:id
    playlist.on(.HEAD, []) { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id") {
            if try ds.playlistExists(id) {
                return(.ok)
            } else {
                return(.notFound)
            }
        }
        throw Abort(.notFound)
    }
    
    // MARK: GET /playlists/:id
    playlist.get { req -> Playlist in
        if let id = req.parameters.get("id") {
            if let playlist = try ds.getPlaylist(id) {
                return playlist
            }
        }
        throw Abort(.notFound)
    }
    
    // MARK: POST /playlists/:id
    playlist.on(.POST, [], body: .collect) { req -> HTTPResponseStatus in
        let id = req.parameters.get("id")!
        let playlist = try req.content.decode(Playlist.self)
        
        if id != playlist.id {
            return HTTPResponseStatus.conflict
        }
        
        do {
            try ds.postPlaylist(playlist)
        } catch {
            return HTTPResponseStatus.internalServerError
        }
        
        return HTTPResponseStatus.ok
        
    }
    
    // MARK: PUT /playlists/:id
    playlist.on(.PUT, [], body: .collect) { req -> HTTPResponseStatus in
        let id = req.parameters.get("id")!
        let playlist = try req.content.decode(Playlist.self)
        
        if id != playlist.id {
            return HTTPResponseStatus.conflict
        }
        
        try ds.putPlaylist(playlist)
        
        return HTTPResponseStatus.ok
    }
    
    // MARK: DELETE /playlists/:id - notImplemented
    playlist.delete { req -> HTTPResponseStatus in
        if let id = req.parameters.get("id") {
            try ds.deletePlaylist(id)
        } else {
            throw Abort(.notFound)
        }
        
        return HTTPResponseStatus.ok
    }

}
