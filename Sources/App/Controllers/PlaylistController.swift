//
//  PlaylistController.swift
//  
//
//  Created by Robert Cheal on 4/22/22.
//

import Vapor
import MusicMetadata

struct PlaylistController: RouteCollection {

    // MARK: - Routes
    func boot(routes: RoutesBuilder) throws {
        let version = routes.grouped("v1")
        let playlists = version.grouped("playlists")

        playlists.get(use: getPlaylists(req:))

        let playlist = playlists.grouped(":id")
        playlist.on(.HEAD, [], use: headPlaylist(req:))
        playlist.get(use: getPlaylist(req:))
        playlist.on(.POST, [], body: .collect, use: postPlaylist(req:))
        playlist.on(.PUT, [], body: .collect, use: putPlaylist(req:))
        playlist.delete(use: deletePlaylist(req:))
    }

    // MARK: - Route Handlers

    // GET /playlists
    private func getPlaylists(req: Request) async throws -> APIPlaylists {
        let ds = Datastore.shared()
        let auth = try req.query.decode(UserParams.self)
        let user = auth.user
        let query = try req.query.decode(ListParams.self)
        let fields = query.fields
        let offset = query.offset ?? 0
        let limit = query.limit ?? 10
        let playlists = try await ds.getPlaylists(user: user, limit: limit, offset: offset, fields: fields)
        let count = try await ds.getPlaylistCount()
        let metadata = APIMetadata(totalCount: count, limit: limit, offset: offset)
        return APIPlaylists(playlists: playlists, _metadata: metadata)
    }

    // HEAD /playlists/:id
    private func headPlaylist(req: Request) throws -> HTTPResponseStatus {
        let ds = Datastore.shared()
        if let id = req.parameters.get("id") {
            if try ds.playlistExists(id) {
                return(.ok)
            } else {
                return(.notFound)
            }
        }
        throw Abort(.notFound)
    }

    // GET /playlists/:id
    private func getPlaylist(req: Request) async throws -> Playlist {
        let ds = Datastore.shared()
        if let id = req.parameters.get("id") {
            if let playlist = try await ds.getPlaylist(id) {
                return playlist
            }
        }
        throw Abort(.notFound)
    }

    // POST /playlists/:id
    private func postPlaylist(req: Request) async throws -> Transaction {
        let ds = Datastore.shared()
        let id = req.parameters.get("id")!
        let playlist = try req.content.decode(Playlist.self)

        if id != playlist.id {
            throw Abort(.conflict)
        }

        do {
            return try await ds.postPlaylist(playlist)
        } catch {
            throw Abort(.conflict)
        }
    }

    // PUT /playlists/:id
    private func putPlaylist(req: Request) async throws -> Transaction {
        let ds = Datastore.shared()
        let id = req.parameters.get("id")!
        let playlist = try req.content.decode(Playlist.self)

        if id != playlist.id {
            throw Abort(.conflict)
        }

        return try await ds.putPlaylist(playlist)
    }

    // DELETE /playlists/:id
    private func deletePlaylist(req: Request) async throws -> Transaction {
        let ds = Datastore.shared()
        let id = req.parameters.get("id")!

        return try await ds.deletePlaylist(id)
    }
}

