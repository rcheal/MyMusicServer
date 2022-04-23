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
import Network
import CryptoKit

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
    
    func getAlbums(limit: Int, offset: Int, fields: String?) throws -> [Album] {
        var albums: [Album] = []
        guard let db = Self.db else {
            return albums
        }

        do {
            albums = try AlbumModel.query(on: db)
                .offset(offset)
                .limit(limit)
                .all()
                .wait()
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

    func albumExists(_ id: String) throws -> Bool {
        var exists = false
        guard let db = Self.db else {
            return exists
        }
        do {
            if let uuid = UUID(uuidString: id) {
                exists = try AlbumModel.query(on: db)
                    .filter(\.$id == uuid)
                    .count()
                    .wait() > 0
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
                if let model = try await AlbumModel.query(on: db)
                    .filter(\.$id == uuid)
                    .first()
                {
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
     
     Insert album into album and albumListItem tables
     Insert singles contained in album into singleListItem table
     Insert compositions contained in album into compositionListItem table
     
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

                try await albumModel.create(on: db)
                try await transactionModel.create(on: db)

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
                throw Abort(.noContent)
            }
        }
        return transaction
    }
    
    /**
     Delete specified album
     
     Deletes all records from database associated with id.  This includes
     records in the album. albumListItem, compositionListItem and singleListItem tables.
     Also deletes the directory containing the albums audiofiles and artwork.
     
     - paramter id: Unique id of album to be deleted
     
     - throws: Database or filesystem errors.  There is no error if the album does not exist.
     */
    func deleteAlbum(_ id: String) async throws -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        print("In deleteAlbum")
        let transaction = Transaction(method: "DELETE", entity: "album", id: id)

        if let album = try await getAlbum(id) {

            do {
                if let albumDir = album.directory {
                    let fm = FileManager.default

                    let dirURL = fileRootURL.appendingPathComponent(albumDir)
                    try? fm.removeItem(at: dirURL)
                }

                if let json = album.json {
                    let albumModel = AlbumModel(id: UUID(uuidString: album.id), json: json)
                    let transactionModel = TransactionModel(transaction: transaction)

                    try await albumModel.delete(on: db)
                    try await transactionModel.create(on: db)
                    return transaction
                }
                throw Abort(.notFound)
            } catch {
                throw Abort(.conflict)
            }
        } else {
            throw Abort(.notFound)
        }

//            try awa
//            let albumToDelete = table.filter(self.id == id)
//            let transaction = Transaction(method: "DELETE", entity: "album", id: id)
//            try db.transaction {
//                if try db.run(albumToDelete.delete()) > 0 {
//                    try db.run(transactionTable.insert(
//                        time <- transaction.time,
//                        method <- transaction.method,
//                        entity <- transaction.entity,
//                        self.id <- transaction.id))
//                } else {
//                    throw Abort(.notFound)
//                }
//            }
//            return transaction
//        }
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
        if let albumURL = try await getAlbumDirectoryURL(id) {
            return albumURL.appendingPathComponent(filename).path
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

    func getSingles(limit: Int, offset: Int, fields: String?) throws -> [Single] {
        var singles: [Single] = []
        guard let db = Self.db else {
            return singles
        }

        do {
            singles = try SingleModel.query(on: db)
                .offset(offset)
                .limit(limit)
                .all()
                .wait()
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
    
    func getSingleCount() -> Int {
        var count = -1
        guard let db = Self.db else {
            return count
        }

        do {
            count = try SingleModel.query(on: db)
                .count()
                .wait()
        } catch {

        }
        return count
    }

    func singleExists(_ id: String) throws -> Bool {
        var exists = false
        guard let db = Self.db else {
            return exists
        }

        do {
            if let uuid = UUID(uuidString: id) {
                exists = try SingleModel.query(on: db)
                    .filter(\.$id == uuid)
                    .count()
                    .wait() > 0
            }
        }
        return exists
    }
    
    func getSingle(_ id: String) throws  -> Single? {
        guard let db = Self.db else {
            return nil
        }

        if let uuid = UUID(uuidString: id) {
            if let model = try SingleModel.query(on: db)
                .filter(\.$id == uuid)
                .first()
                .wait() {
                if let single = Single.decodeFrom(json: model.json) {
                    return single
                }
            }
        }
        return nil
    }
    
    func postSingle(_ single: Single) throws -> Transaction {
        guard let db = Self.db else {
            throw Abort(.serviceUnavailable)
        }

        let transaction = Transaction(method: "POST", entity: "single", id: single.id)
        if let json = single.json {
            do {
                let singleModel = SingleModel(id: UUID(uuidString: single.id), json: json)
                let transactionModel = TransactionModel(transaction: transaction)
                try singleModel.create(on: db)
                    .wait()

                try transactionModel.create(on: db)
                    .wait()
            }
        } else {
            throw Abort(.noContent)
        }

        return transaction
    }
    
    func putSingle(_ single: Single) throws -> Transaction {
//        guard let db = Self.db else {
//            throw Abort(.serviceUnavailable)
//        }
//        let table = Table("single")
//        let transactionTable = Table("transaction")
//        let transaction = Transaction(method: "PUT", entity: "single", id: single.id)
//        if let json = single.json {
//            let singleToModify = table.filter(id == single.id)
//            do {
//                try db.transaction {
//                    if try db.run(singleToModify.update(self.json <- json.datatypeValue)) > 0 {
//                        try db.run(transactionTable.insert(
//                            time <- transaction.time,
//                            method <- transaction.method,
//                            entity <- transaction.entity,
//                            id <- transaction.id))
//                    } else {
//                        throw Abort(.notFound)
//                    }
//                }
//            } catch {
//                throw Abort(.notFound)
//            }
//        }
//        return transaction
        throw  Abort(.notImplemented)
    }

    func deleteSingle(_ id: String) throws -> Transaction {
//        var directory: String?
//        var filename: String?
//        guard let db = db else {
//            throw Abort(.serviceUnavailable)
//        }
//        let table = Table("single")
//        let transactionTable =  Table("transaction")
//        for row in try db.prepare(table.select(json).filter(self.id == id)) {
//            if let single = Single.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
//                directory = single.directory
//                filename = single.filename
//            }
//            break
//        }
//        if let directory = directory,
//           let filename = filename {
//            let fm = FileManager.default
//
//            let dirURL = fileRootURL.appendingPathComponent(directory)
//            let fileURL = dirURL.appendingPathComponent(filename)
//            try? fm.removeItem(at: fileURL)
//            if let contents = try? fm.contentsOfDirectory(atPath: dirURL.path), contents.isEmpty {
//                try? fm.removeItem(at: dirURL)
//            }
//        }
//        do {
//            let singleToDelete = table.filter(self.id == id)
//            let transaction = Transaction(method: "DELETE", entity: "single", id: id)
//            try db.transaction {
//                if try db.run(singleToDelete.delete()) > 0 {
//                    try db.run(transactionTable.insert(
//                        time <- transaction.time,
//                        method <- transaction.method,
//                        entity <- transaction.entity,
//                        self.id <- transaction.id))
//                } else {
//                    throw Abort(.notFound)
//                }
//            }
//            return transaction
//        }
        throw Abort(.notImplemented)
    }
    
    private func getSingleDirectoryURL(_ id: String) -> URL? {
        do {
            if let single = try getSingle(id),
               let directory = single.directory {
                return fileRootURL.appendingPathComponent(directory)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getSingleFilePath(_ id: String, filename: String) -> String? {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            return singleDirectoryURL.appendingPathComponent(filename).path
        }
        return nil
    }
    
    func getSingleFile(_ id: String, filename: String) -> Data? {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)

            let fm = FileManager.default
            return fm.contents(atPath: fileURL.path)
        }
        return nil
    }
    
    func postSingleFile(_ id: String, filename: String, data: Data) throws {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
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
    
    func putSingleFile(_ id: String, filename: String, data: Data) throws {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
            let fileURL = singleDirectoryURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
        
    func deleteSingleFile(_ id: String, filename: String) throws {
        if let singleDirectoryURL = getSingleDirectoryURL(id) {
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
    
    func getPlaylists(user: String?, limit: Int, offset: Int, fields: String?) throws -> [Playlist] {
//        var playlists: [Playlist] = []
//        guard let db = db else {
//            return playlists
//        }
//        let table = Table("playlist")
//        for row in try db.prepare(table.select(json).limit(limit, offset: offset)) {
//            if var playlist = Playlist.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
//                if let fields = fields {
//                    let fullSingle = playlist
//                    playlist = Playlist(fullSingle.title)
//                    playlist.id = fullSingle.id
//                    playlist.addFields(fields, from: fullSingle)
//                }
//                playlists.append(playlist)
//            }
//        }
//        return playlists
        throw Abort(.notImplemented)
    }
    
    func getPlaylistCount() -> Int {
        var count = -1
        guard let db = Self.db else {
            return count
        }

        do {
            count = try PlaylistModel.query(on: db)
                .count()
                .wait()
        } catch {

        }
        return count
    }
    
    func playlistExists(_ id: String) throws -> Bool {
        var exists = false
        guard let db = Self.db else {
            return exists
        }
        do {
            if let uuid = UUID(uuidString: id) {
                exists = try PlaylistModel.query(on: db)
                    .filter(\.$id == uuid)
                    .count()
                    .wait() > 0
            }
        }
        return exists
    }
    
    func getPlaylist(_ id: String) throws -> Playlist?  {
//        var playlist: Playlist? = nil
//        guard let db = db else {
//            return playlist
//        }
//        let table = Table("playlist")
//        for row in try db.prepare(table.select(json).filter(self.id == id)) {
//            playlist = Playlist.decodeFrom(json: Data.fromDatatypeValue(row[json]))
//            return playlist
//        }
//        return playlist
        throw Abort(.notImplemented)
    }
    
    func postPlaylist(_ playlist: Playlist) throws -> Transaction  {
//        guard let db = db else {
//            throw Abort(.serviceUnavailable)
//        }
//        let table = Table("playlist")
//        let transactionTable = Table("transaction")
//        let transaction = Transaction(method: "POST", entity: "playlist", id: playlist.id)
//        if let json = playlist.json {
//            do {
//                try db.transaction {
//                    if let user = playlist.user {
//                        try db.run(table.insert(self.id <- playlist.id, self.user <- user, shared <- playlist.shared, self.json <- json.datatypeValue))
//                    } else {
//                        try db.run(table.insert(self.id <- playlist.id, shared <- playlist.shared, self.json <- json.datatypeValue))
//                    }
//                    try db.run(transactionTable.insert(
//                        time <- transaction.time,
//                        method <- transaction.method,
//                        entity <- transaction.entity,
//                        id <- transaction.id))
//                }
//            } catch let Result.error(a, code, b) where code == SQLITE_CONSTRAINT {
//                print(a)
//                print(b)
//                throw Abort(.found)
//            } catch {
//                throw Abort(.serviceUnavailable)
//            }
//        } else {
//            throw Abort(.noContent)
//        }
//        return transaction
        throw Abort(.notImplemented)
    }
    
    func putPlaylist(_ playlist: Playlist) throws -> Transaction {
//        guard let db = db else {
//            throw Abort(.serviceUnavailable)
//        }
//        let table = Table("playlist")
//        let transactionTable = Table("transaction")
//        let transaction = Transaction(method: "PUT", entity: "playlist", id: playlist.id)
//        if let json = playlist.json {
//            let playlistToModify = table.filter(id == playlist.id)
//            do {
//                try db.transaction {
//                    var count = 0
//                    if let user = playlist.user {
//                        count = try db.run(playlistToModify.update(self.user <- user, shared <- playlist.shared, self.json <- json.datatypeValue))
//                    } else {
//                        count = try db.run(playlistToModify.update(shared <- playlist.shared, self.json <- json.datatypeValue))
//                    }
//                    if count > 0 {
//                        try db.run(transactionTable.insert(
//                            time <- transaction.time,
//                            method <- transaction.method,
//                            entity <- transaction.entity,
//                            id <- transaction.id))
//                    } else {
//                        throw Abort(.notFound)
//                    }
//                }
//            } catch {
//                throw Abort(.notFound)
//            }
//        }
//        return transaction
        throw Abort(.notImplemented)
    }
    
    func deletePlaylist(_ id: String) throws -> Transaction {
//        guard let db = db else {
//            throw Abort(.serviceUnavailable)
//        }
//        let table = Table("playlist")
//        let transactionTable = Table("transaction")
//        do {
//            let playlistToDelete = table.filter(self.id == id)
//            let transaction = Transaction(method: "DELETE", entity: "playlist", id: id)
//            try db.transaction {
//                if try db.run(playlistToDelete.delete()) > 0 {
//                    try db.run(transactionTable.insert(
//                        time <- transaction.time,
//                        method <- transaction.method,
//                        entity <- transaction.entity,
//                        self.id <- transaction.id))
//                } else {
//                    throw Abort(.notFound)
//                }
//            }
//            return transaction
//        }
        throw Abort(.notImplemented)
    }
}
