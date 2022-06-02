//
//  Datastore.swift
//  
//
//  Created by Robert Cheal on 1/9/21.
//

import Foundation
import MusicMetadata
import Vapor
import Fluent
import FluentSQL

class Datastore {
    public static var sharedInstance: Datastore?

    public static var db: Database?

    public static var baseURL: URL?
    
    public var fileRootURL: URL

    public static func create(memory: Bool = false) -> Datastore {
        let datastore = Datastore(memory: memory)
        sharedInstance = datastore
        return datastore
    }
    
    public static func shared() -> Datastore {
        if let dm = sharedInstance {
            return dm
        } else {
            let dm = Datastore(memory: false)
            sharedInstance = dm
            return dm
        }
    }
    
    private init(memory: Bool = false) {
        guard Self.db != nil else {
            print("Startup Failed! - missing Database")
            fileRootURL = Self.baseURL ?? URL(fileURLWithPath: "/")
            return
        }
        guard let baseURL = Self.baseURL else {
            print("Startup Failed! - missing directory")
            fileRootURL = URL(fileURLWithPath: "/")
            return
        }
        fileRootURL = baseURL.appendingPathComponent("music")
    }


    // MARK: - Server functions
    
    func getTransactions(since timestamp: String) async throws -> [Transaction] {
        var transactions: [Transaction] = []
        guard let db = Self.db else {
            return []
        }

        do {
            transactions = try await TransactionModel.query(on: db)
                .filter(\.$time >= timestamp)
                .sort(\.$time, .ascending)
                .all()
                .map { model -> Transaction in
                    var transaction = Transaction(method: model.method, entity: model.entity, id: model.entityid)
                    transaction.time = model.time
                    return transaction
                }
        }

        return transactions
    }

    func getLastTransactionTime() -> String? {
        guard let db = Self.db else {
            return nil
        }

        do {
            let time = try TransactionModel.query(on: db)
                .sort(\.$time, .descending)
                .first()
                .wait()?.time
            return time

        } catch {
            return nil
        }
    }
    
    // MARK: Album functions
    
    func getAlbums(limit: Int, offset: Int, fields: String?) async throws -> [Album] {
        var albums: [Album] = []
        guard let db = Self.db else {
            return albums
        }

        do {
            albums = try await AlbumModel.query(on: db)
                .offset(offset)
                .limit(limit)
                .all()
                .compactMap { model -> Album? in
                    if var album = Album.decodeFrom(json: model.json) {
                        if let fields = fields {
                            let fullAlbum = album
                            album = Album(title: fullAlbum.title)
                            album.id = fullAlbum.id
                            album.addFields(fields, from: fullAlbum)
                        }
                        return album
                    }
                    return nil
                }
        } catch {

        }
        return albums
    }
    
    func getAlbumCount()  async throws -> Int {
        var count = -1
        guard let db = Self.db else {
            return count
        }

        do {
            count = try await AlbumModel.query(on: db)
                .count()
        } catch {

        }
        return count
    }

    func albumExists(_ id: String) async throws -> Bool {
        var exists = false
        guard let db = Self.db else {
            return exists
        }
        if let uuid = UUID(uuidString: id) {
            do {
                exists = try await AlbumModel.find(uuid, on: db) != nil
            }
        }
        return exists
    }

    /**
     Retrieves an album from the database
     
     The return value contains all metadata.  References to audio files and artwork files
     are included, but the files themselves must be retrieved separately via getArtwork(:artRef:)
     and/or getAudiofile(...)
     
     - paramter id: Unique identifier of album to retrieve
     
     - returns: Album?
     */
    func getAlbum(_ id: String) async throws  -> Album? {
        guard let db = Self.db else {
            return nil
        }
        if let uuid = UUID(uuidString: id) {
            do {
                if let model = try await AlbumModel.find(uuid, on: db) {
                    if let album = Album.decodeFrom(json: model.json) {
                        return album
                    }
                }
            } catch {
                throw Abort(.notFound)
            }
        }

        return nil
    }
    
    /**
     Insert new album into the database
     
     Insert album into albums table

     - parameter album: album to be inserted into database
     
     - throws: Database exceptions
     */
    func postAlbum(_ album: Album) async throws -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "POST", entity: "album", id: album.id)
        if let json = album.json {
            do {
                let albumModel = AlbumModel(id: UUID(uuidString: album.id), json: json)
                let transactionModel = TransactionModel(transaction: transaction)

                try await db.transaction { database in
                    try await albumModel.create(on: database)
                    try await transactionModel.create(on: database)
                }

            }
        } else {
            throw Abort(.noContent)
        }

        return transaction
    }
    
    func putAlbum(_ album: Album) async throws  -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "PUT", entity: "album", id: album.id)
        if let json = album.json {
            var albumModel: AlbumModel?
            do {
                albumModel = try await AlbumModel.find(UUID(uuidString: album.id), on: db)
            } catch {
                throw Abort(.notFound)
            }

            if let albumModel = albumModel {
                albumModel.json = json
                do {
                    let transactionModel = TransactionModel(transaction: transaction)
                    try await db.transaction { database in
                        try await albumModel.update(on: database)
                        try await transactionModel.create(on: database)
                    }
                } catch {
                    let myError = error as Error
                    print(myError)
                    throw Abort(.conflict)
                }
            } else {
                throw Abort(.notFound)
            }
        }
        return transaction
    }
    
    /**
     Delete specified album
     
     Deletes row with matching id from albums.
     Also deletes the directory containing the albums audiofiles and artwork.
     
     - paramter id: Unique id of album to be deleted
     
     - throws: Database or filesystem errors.
     */
    func deleteAlbum(_ id: String) async throws -> Transaction {
        var albumModel: AlbumModel?

        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "DELETE", entity: "album", id: id)

        do {
            albumModel = try await AlbumModel.find(UUID(uuidString: id), on: db)
        } catch {
            throw Abort(.notFound)
        }

        if let albumModel = albumModel {

            do {
                if let album = Album.decodeFrom(json: albumModel.json) {
                    if let albumDir = album.directory {
                        let fm = FileManager.default

                        let dirURL = fileRootURL.appendingPathComponent(albumDir)
                        try? fm.removeItem(at: dirURL)
                    }

                    let transactionModel = TransactionModel(transaction: transaction)

                    try await db.transaction { database in
                        try await albumModel.delete(on: database)
                        try await transactionModel.create(on: database)
                    }
                    return transaction
                }
                throw Abort(.notFound)
            } catch {
                print(error)
                throw Abort(.conflict)
            }
        }
        throw Abort(.notFound)

    }
    
    private func getAlbumDirectoryURL(_ id: String) async throws -> URL? {
        do {
            if let album = try await getAlbum(id),
               let directory = album.directory {
                return fileRootURL.appendingPathComponent(directory)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getAlbumFilePath(_ id: String, filename: String) async throws -> String? {
        if let albumDirectoryURL = try await getAlbumDirectoryURL(id) {
            return albumDirectoryURL.appendingPathComponent(filename).path
        }
        return nil
    }
    
    func getAlbumFile(_ id: String, filename: String) async throws -> Data? {
        if let albumURL = try await getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)

            let fm = FileManager.default
            return fm.contents(atPath: fileURL.path)
        }
        return nil
    }
    
    func postAlbumFile(_ id: String, filename: String, data: Data) async throws {
        if let albumURL = try await getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if !fm.fileExists(atPath: albumURL.path) {
                try fm.createDirectory(at: albumURL, withIntermediateDirectories: true, attributes: nil)
            }
            if !fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.found)
            }
        }
    }
    
    func putAlbumFile(_ id: String, filename: String, data: Data) async throws {
        if let albumURL = try await getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
        
    func deleteAlbumFile(_ id: String, filename: String) async throws {
        if let albumURL = try await getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try fm.removeItem(at: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
    
    // MARK: Single functions

    func getSingles(limit: Int, offset: Int, fields: String?) async throws -> [Single] {
        var singles: [Single] = []
        guard let db = Self.db else {
            return singles
        }

        do {
            singles = try await SingleModel.query(on: db)
                .offset(offset)
                .limit(limit)
                .all()
                .compactMap { model -> Single? in
                    if var single = Single.decodeFrom(json: model.json) {
                        if let fields = fields {
                            let fullSingle = single
                            single = Single(title: fullSingle.title, filename: "")
                            single.id = fullSingle.id
                            single.addFields(fields, from: fullSingle)
                        }
                        return single
                    }
                    return nil
                }
        } catch {

        }
        return singles
    }
    
    func getSingleCount() async throws -> Int {
        var count = -1
        guard let db = Self.db else {
            return count
        }

        do {
            count = try await SingleModel.query(on: db)
                .count()
        } catch {

        }
        return count
    }

    func singleExists(_ id: String) async throws -> Bool {
        var exists = false
        guard let db = Self.db else {
            return exists
        }

        if let uuid = UUID(uuidString: id) {
            do {
                exists = try await SingleModel.find(uuid, on: db) != nil
            }
        }
        return exists
    }
    
    /**
     Retrieves an single from the database

     The return value contains all metadata.  References to audio files
     are included, but the files themselves must be retrieved separately via getAudiofile(...)

     - paramter id: Unique identifier of single to retrieve

     - returns: Single?
     */
    func getSingle(_ id: String) async throws  -> Single? {
        guard let db = Self.db else {
            return nil
        }

        if let uuid = UUID(uuidString: id) {
            do {
                if let model = try await SingleModel.find(uuid, on: db) {
                    if let single = Single.decodeFrom(json: model.json) {
                        return single
                    }
                }
            } catch {
                throw Abort(.notFound)
            }
        }
        return nil
    }
    
    /**
     Insert new single into the database

     Insert single into singles table

     - parameter single: single to be inserted into database

     - throws: Database exceptions
     */
    func postSingle(_ single: Single) async throws -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "POST", entity: "single", id: single.id)
        if let json = single.json,
           let uuid = UUID(uuidString: single.id) {
            if try await SingleModel.find(uuid, on: db) != nil {
                throw Abort(.conflict)
            }
            do {
                let singleModel = SingleModel(id: uuid, json: json)
                let transactionModel = TransactionModel(transaction: transaction)

                try await db.transaction { database in
                    try await singleModel.create(on: database)
                    try await transactionModel.create(on: database)
                }
            } catch {
                print(error)
                throw Abort(.internalServerError)
            }
        } else {
            throw Abort(.noContent)
        }

        return transaction
    }
    
    func putSingle(_ single: Single) async throws -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "PUT", entity: "single", id: single.id)
        if let json = single.json {
            var singleModel: SingleModel?
            do {
                singleModel = try await SingleModel.find(UUID(uuidString: single.id), on: db)
            } catch {
                throw Abort(.notFound)
            }

            if let singleModel = singleModel {
                singleModel.json = json
                do {
                    let transactionModel = TransactionModel(transaction: transaction)
                    try await db.transaction { database in
                        try await singleModel.update(on: database)
                        try await transactionModel.create(on: database)
                    }
                } catch {
                    let myError = error as Error
                    print(myError)
                    throw Abort(.conflict)
                }
            } else {
                throw Abort(.notFound)
            }
        }
        return transaction
    }

    /**
     Delete specified single

     Deletes row with matching id from singles.
     Also deletes the directory containing the albums audiofiles.

     - paramter id: Unique id of single to be deleted

     - throws: Database or filesystem errors.
     */
    func deleteSingle(_ id: String) async throws -> Transaction {
        var singleModel: SingleModel?

        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "DELETE", entity: "single", id: id)

        do {
            singleModel = try await SingleModel.find(UUID(uuidString: id), on: db)
        } catch {
            throw Abort(.notFound)
        }

        if let singleModel = singleModel {
            do {
                if let single = Single.decodeFrom(json: singleModel.json) {
                    if let singleDir = single.directory {
                        let fm = FileManager.default

                        let dirURL = fileRootURL.appendingPathComponent(singleDir)
                        try? fm.removeItem(at: dirURL)
                    }

                    let transactionModel = TransactionModel(transaction: transaction)

                    try await db.transaction { database in
                        try await singleModel.delete(on: database)
                        try await transactionModel.delete(on: database)
                    }
                    return transaction
                }
                throw Abort(.internalServerError)
            } catch {
                throw Abort(.conflict)
            }
        }
        throw Abort(.notFound)
    }
    
    private func getSingleDirectoryURL(_ id: String) async throws -> URL? {
        do {
            if let single = try await getSingle(id),
               let directory = single.directory {
                return fileRootURL.appendingPathComponent(directory)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getSingleFilePath(_ id: String, filename: String) async throws -> String? {
        if let singleDirectoryURL = try await getSingleDirectoryURL(id) {
            return singleDirectoryURL.appendingPathComponent(filename).path
        }
        return nil
    }
    
    func getSingleFile(_ id: String, filename: String) async throws -> Data? {
        if let singleDirectoryURL = try await getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)

            let fm = FileManager.default
            return fm.contents(atPath: fileURL.path)
        }
        return nil
    }
    
    func postSingleFile(_ id: String, filename: String, data: Data) async throws {
        if let singleDirectoryURL = try await getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if !fm.fileExists(atPath: singleDirectoryURL.path) {
                try fm.createDirectory(at: singleDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            if !fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.found)
            }
        }
    }
    
    func putSingleFile(_ id: String, filename: String, data: Data) async throws {
        if let singleDirectoryURL = try await getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
        
    func deleteSingleFile(_ id: String, filename: String) async throws {
        if let singleDirectoryURL = try await getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try fm.removeItem(at: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
    
    // MARK: Playlist functions
    
    func getPlaylists(user: String?, limit: Int, offset: Int, fields: String?) async throws -> [Playlist] {
        var playlists: [Playlist] = []
        guard let db = Self.db else {
            return playlists
        }

        do {
            playlists = try await PlaylistModel.query(on: db)
                .filter(\.$user == user)
                .offset(offset)
                .limit(limit)
                .all()
                .compactMap { model -> Playlist? in
                    if var playlist = Playlist.decodeFrom(json: model.json) {
                        if let fields = fields {
                            let fullPlaylist = playlist
                            playlist = Playlist(fullPlaylist.title)
                            playlist.id = fullPlaylist.id
                            playlist.addFields(fields, from: fullPlaylist)
                        }
                        return playlist
                    }
                    return nil
                }
        } catch {

        }
        return playlists
    }
    
    func getPlaylistCount() async throws -> Int {
        var count = -1
        guard let db = Self.db else {
            return count
        }

        do {
            count = try await PlaylistModel.query(on: db)
                .count()
        } catch {

        }
        return count
    }
    
    func playlistExists(_ id: String) async throws -> Bool {
        var exists = false
        guard let db = Self.db else {
            return exists
        }
        if let uuid = UUID(uuidString: id) {
            do {
                exists = try await PlaylistModel.find(uuid, on: db) != nil
            }
        }
        return exists
    }
    
    /**
     Retrieves an playlist from the database

     The return value contains the playlist.

     - paramter id: Unique identifier of playlist to retrieve

     - returns: Playlist?
     */
    func getPlaylist(_ id: String) async throws  -> Playlist? {
        guard let db = Self.db else {
            return nil
        }

        if let uuid = UUID(uuidString: id) {
            do {
                if let model = try await PlaylistModel.find(uuid, on: db) {
                    if let playlist = Playlist.decodeFrom(json: model.json) {
                        return playlist
                    }
                }
            } catch {
                throw Abort(.notFound)
            }
        }
        return nil
    }

    /**
     Insert new playlist into the database

     Insert playlist into playlists table

     - parameter playlist: playlist to be inserted into database

     - throws: Database exceptions
     */
    func postPlaylist(_ playlist: Playlist) async throws -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "POST", entity: "playlist", id: playlist.id)
        if let json = playlist.json,
           let uuid = UUID(uuidString: playlist.id) {
            if try await PlaylistModel.find(uuid, on: db) != nil {
                throw Abort(.conflict)
            }
            do {
                let playlistModel = PlaylistModel(id: uuid, json: json)
                let transactionModel = TransactionModel(transaction: transaction)

                try await db.transaction { database in
                    try await playlistModel.create(on: database)
                    try await transactionModel.create(on: database)
                }
            } catch {
                print(error)
                throw Abort(.internalServerError)
            }
        } else {
            throw Abort(.noContent)
        }

        return transaction
    }

    func putPlaylist(_ playlist: Playlist) async throws -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "PUT", entity: "playlist", id: playlist.id)
        if let json = playlist.json {
            var playlistModel: PlaylistModel?
            do {
                playlistModel = try await PlaylistModel.find(UUID(uuidString: playlist.id), on: db)
            } catch {
                throw Abort(.notFound)
            }

            if let playlistModel = playlistModel {
                playlistModel.json = json
                do {
                    let transactionModel = TransactionModel(transaction: transaction)
                    try await db.transaction { database in
                        try await playlistModel.update(on: database)
                        try await transactionModel.create(on: database)
                    }
                } catch {
                    let myError = error as Error
                    print(myError)
                    throw Abort(.conflict)
                }
            } else {
                throw Abort(.notFound)
            }
        }
        return transaction
    }

    /**
     Delete specified single

     Deletes row with matching id from singles.
     Also deletes the directory containing the albums audiofiles.

     - paramter id: Unique id of single to be deleted

     - throws: Database or filesystem errors.
     */
    func deletePlaylist(_ id: String) async throws -> Transaction {
        var playlistModel: PlaylistModel?

        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "DELETE", entity: "playlist", id: id)

        do {
            playlistModel = try await PlaylistModel.find(UUID(uuidString: id), on: db)
        } catch {
            throw Abort(.notFound)
        }

        if let playlistModel = playlistModel {
            do {
                let transactionModel = TransactionModel(transaction: transaction)

                try await db.transaction { database in
                    try await playlistModel.delete(on: database)
                    try await transactionModel.delete(on: database)
                }
                return transaction
            } catch {
                throw Abort(.conflict)
            }
        }
        throw Abort(.notFound)
    }
}
