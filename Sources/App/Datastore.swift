//
//  Datastore.swift
//  
//
//  Created by Robert Cheal on 1/9/21.
//

import Foundation
import MusicMetadata
import Vapor
import SQLite
import SQLite3

class Datastore {
    public static var sharedInstance: Datastore?
    
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
    
    var isMemory = false
    private let id = Expression<String>("id")
    private let json = Expression<Blob>("json")
    private let user = Expression<String?>("user")
    private let shared = Expression<Bool>("shared")
    private let time = Expression<String>("time")
    private let method = Expression<String>("method")
    private let entity = Expression<String>("entity")

    public var fileRootURL: URL
    

    public var db: Connection?
    
    private init(memory: Bool = false) {
        isMemory = memory
        let subDirectory = isMemory ? "MyMusicServerMemoryFiles" : "MyMusicServerFiles"
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let baseURL = homeURL.appendingPathComponent(subDirectory)
        let fm = FileManager()
        if !fm.fileExists(atPath: baseURL.path) {
            try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
        if memory {
            fileRootURL = baseURL
            do {
                db = try Connection(.inMemory)
            } catch {
                db = nil
            }
        } else {
            fileRootURL = baseURL.appendingPathComponent("music")
            let dbURL = baseURL.appendingPathComponent("MyMusic.sqlite")
            do {
                db = try Connection(dbURL.path)
            } catch {
                db = nil
                print("Unable to open database file - \(dbURL.path)")
            }
        }
        try? migrateDb()
    }

    func migrateDb() throws {
        
        guard let db = db else {
            return
        }
        
        let albums = Table("album")
        try db.run(albums.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(json)
        })
        

        let singles = Table("single")
        try db.run(singles.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(json)
        })
            
        let playlists = Table("playlist")
        try db.run(playlists.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(user)
            t.column(shared)
            t.column(json)
        })
        
        let transactions = Table("transaction")
        try db.run(transactions.create(ifNotExists: true) { t in
            t.column(time, primaryKey: true)
            t.column(id)
            t.column(method)           // 'GET', 'POST', 'PUT' or 'DELETE'
            t.column(entity)           // 'album', 'single', or 'playlist'
        })
        
    }

    // MARK: Server functions
    
    func getTransactions(since timestamp: String) throws -> [Transaction] {
        var transactions: [Transaction] = []
        guard let db = db else {
            return []
        }
        let table = Table("transaction")
        for row in try db.prepare(table.filter(time >= timestamp)) {
            let transaction = Transaction(method: row[method], entity: row[entity], id: row[id])
            transactions.append(transaction)
        }
        return transactions
    }
    
    func getLastTransactionTime() -> String? {
        guard let db = db else {
            return nil
        }
        let table = Table("transaction")
        do {
            for row in try db.prepare(table.order(time.desc).limit(1)) {
                return row[time]
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    // MARK: Album functions
    
    func getAlbums(limit: Int, offset: Int, fields: String?) throws -> [Album] {
        var albums: [Album] = []
        guard let db = db else {
            return albums
        }
        let table = Table("album")
        for row in try db.prepare(table.select(json).limit(limit, offset: offset)) {
            if var album = Album.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
                if let fields = fields {
                    let fullAlbum = album
                    album = Album(title: fullAlbum.title)
                    album.id = fullAlbum.id
                    album.addFields(fields, from: fullAlbum)
                }
                albums.append(album)
            }
        }
        return albums
    }
    
    func getAlbumCount() -> Int {
        var count = -1
        guard let db = db else {
            return count
        }
        let table = Table("album")
        do {
            count = try db.scalar(table.count)
        } catch {
        }
        return count
    }

    func albumExists(_ id: String) throws -> Bool {
        var exists = false
        guard let db = db else {
            return exists
        }
        let table = Table("album")
        exists = try db.scalar(table.filter(self.id == id).count) == 1
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
    func getAlbum(_ id: String) throws  -> Album? {
        guard let db = db else {
            return nil
        }
        let table = Table("album")
        for row in try db.prepare(table.select(json).filter(self.id == id)) {
            if let album = Album.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
                return album
            }
            return nil
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
    func postAlbum(_ album: Album) throws -> Transaction {
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("album")
        let transactionTable = Table("transaction")
        let transaction = Transaction(method: "POST", entity: "album", id: album.id)
        if let json = album.json {
            do {
                try db.transaction {
                    try db.run(table.insert(self.id <- album.id, self.json <- json.datatypeValue))
                    try db.run(transactionTable.insert(
                        time <- transaction.time,
                        method <- transaction.method,
                        entity <- transaction.entity,
                        id <- transaction.id))
                }
            } catch let Result.error(_, code, _) where code == SQLITE_CONSTRAINT {
                throw Abort(.found)
            } catch {
                throw Abort(.serviceUnavailable)
            }
        } else {
            throw Abort(.noContent)
        }
        return transaction
    }
    
    func putAlbum(_ album: Album) throws  -> Transaction {
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("album")
        let transactionTable = Table("transaction")
        let transaction = Transaction(method: "PUT", entity: "album", id: album.id)
        if let json = album.json {
            let albumToModify = table.filter(id == album.id)
            do {
                try db.transaction {
                    if try db.run(albumToModify.update(self.json <- json.datatypeValue)) > 0 {
                        try db.run(transactionTable.insert(
                            time <- transaction.time,
                            method <- transaction.method,
                            entity <- transaction.entity,
                            id <- transaction.id))
                    } else {
                        throw Abort(.notFound)
                    }
                }
            } catch {
                throw Abort(.notFound)
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
    func deleteAlbum(_ id: String) throws -> Transaction {
        var directory: String?
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("album")
        let transactionTable =  Table("transaction")
        for row in try db.prepare(table.select(json).filter(self.id == id)) {
            if let album = Album.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
                directory = album.directory
            }
            break
        }
        if let albumDir = directory {
            let fm = FileManager.default

            let dirURL = fileRootURL.appendingPathComponent(albumDir)
            try? fm.removeItem(at: dirURL)
        }
        do {
            let albumToDelete = table.filter(self.id == id)
            let transaction = Transaction(method: "DELETE", entity: "album", id: id)
            try db.transaction {
                if try db.run(albumToDelete.delete()) > 0 {
                    try db.run(transactionTable.insert(
                        time <- transaction.time,
                        method <- transaction.method,
                        entity <- transaction.entity,
                        self.id <- transaction.id))
                } else {
                    throw Abort(.notFound)
                }
            }
            return transaction
        }
    }
    
    private func getAlbumDirectoryURL(_ id: String) -> URL? {
        do {
            if let album = try getAlbum(id),
               let directory = album.directory {
                return fileRootURL.appendingPathComponent(directory)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getAlbumFilePath(_ id: String, filename: String) -> String? {
        if let albumURL = getAlbumDirectoryURL(id) {
            return albumURL.appendingPathComponent(filename).path
        }
        return nil
    }
    
    func getAlbumFile(_ id: String, filename: String) -> Data? {
        if let albumURL = getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            
            let fm = FileManager.default
            return fm.contents(atPath: fileURL.path)
        }
        return nil
    }
    
    func postAlbumFile(_ id: String, filename: String, data: Data) throws {
        if let albumURL = getAlbumDirectoryURL(id) {
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
    
    func putAlbumFile(_ id: String, filename: String, data: Data) throws {
        if let albumURL = getAlbumDirectoryURL(id) {
            let fileURL = albumURL.appendingPathComponent(filename)
            let fm = FileManager.default
            if fm.fileExists(atPath: fileURL.path) {
                try data.write(to: fileURL)
            } else {
                throw Abort(.notFound)
            }
        }
    }
        
    func deleteAlbumFile(_ id: String, filename: String) throws {
        if let albumURL = getAlbumDirectoryURL(id) {
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
        guard let db = db else {
            return singles
        }
        let table = Table("single")
        for row in try db.prepare(table.select(json).limit(limit, offset: offset)) {
            if var single = Single.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
                if let fields = fields {
                    let fullSingle = single
                    single = Single(title: fullSingle.title, filename: "")
                    single.id = fullSingle.id
                    single.addFields(fields, from: fullSingle)
                }
                singles.append(single)
            }
        }
        return singles
    }
    
    func getSingleCount() -> Int {
        var count = -1
        guard let db = db else {
            return count
        }
        let table = Table("single")
        do {
            count = try db.scalar(table.count)
        } catch {
        }
        return count
    }

    func singleExists(_ id: String) throws -> Bool {
        var exists = false
        guard let db = db else {
            return exists
        }
        let table = Table("single")
        exists = try db.scalar(table.filter(self.id == id).count) == 1
        return exists
    }
    
    func getSingle(_ id: String) throws  -> Single? {
        var single: Single? = nil
        guard let db = db else {
            return single
        }
        let table = Table("single")
        for row in try db.prepare(table.select(json).filter(self.id == id)) {
            single = Single.decodeFrom(json: Data.fromDatatypeValue(row[json]))
            return single
        }
        return single
    }
    
    func postSingle(_ single: Single) throws -> Transaction {
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("single")
        let transactionTable = Table("transaction")
        let transaction = Transaction(method: "POST", entity: "single", id: single.id)
        if let json = single.json {
            do {
                try db.transaction {
                    try db.run(table.insert(self.id <- single.id, self.json <- json.datatypeValue))
                    try db.run(transactionTable.insert(
                        time <- transaction.time,
                        method <- transaction.method,
                        entity <- transaction.entity,
                        id <- transaction.id))
                }
            } catch let Result.error(_, code, _) where code == SQLITE_CONSTRAINT {
                throw Abort(.found)
            } catch {
                throw Abort(.serviceUnavailable)
            }
        } else {
            throw Abort(.noContent)
        }
        return transaction
    }
    
    func putSingle(_ single: Single) throws -> Transaction {
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("single")
        let transactionTable = Table("transaction")
        let transaction = Transaction(method: "PUT", entity: "single", id: single.id)
        if let json = single.json {
            let singleToModify = table.filter(id == single.id)
            do {
                try db.transaction {
                    if try db.run(singleToModify.update(self.json <- json.datatypeValue)) > 0 {
                        try db.run(transactionTable.insert(
                            time <- transaction.time,
                            method <- transaction.method,
                            entity <- transaction.entity,
                            id <- transaction.id))
                    } else {
                        throw Abort(.notFound)
                    }
                }
            } catch {
                throw Abort(.notFound)
            }
        }
        return transaction
    }

    func deleteSingle(_ id: String) throws -> Transaction {
        var directory: String?
        var filename: String?
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("single")
        let transactionTable =  Table("transaction")
        for row in try db.prepare(table.select(json).filter(self.id == id)) {
            if let single = Single.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
                directory = single.directory
                filename = single.filename
            }
            break
        }
        if let directory = directory,
           let filename = filename {
            let fm = FileManager.default

            let dirURL = fileRootURL.appendingPathComponent(directory)
            let fileURL = dirURL.appendingPathComponent(filename)
            try? fm.removeItem(at: fileURL)
            if let contents = try? fm.contentsOfDirectory(atPath: dirURL.path), contents.isEmpty {
                try? fm.removeItem(at: dirURL)
            }
        }
        do {
            let singleToDelete = table.filter(self.id == id)
            let transaction = Transaction(method: "DELETE", entity: "single", id: id)
            try db.transaction {
                if try db.run(singleToDelete.delete()) > 0 {
                    try db.run(transactionTable.insert(
                        time <- transaction.time,
                        method <- transaction.method,
                        entity <- transaction.entity,
                        self.id <- transaction.id))
                } else {
                    throw Abort(.notFound)
                }
            }
            return transaction
        }
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
        var playlists: [Playlist] = []
        guard let db = db else {
            return playlists
        }
        let table = Table("playlist")
        for row in try db.prepare(table.select(json).limit(limit, offset: offset)) {
            if var playlist = Playlist.decodeFrom(json: Data.fromDatatypeValue(row[json])) {
                if let fields = fields {
                    let fullSingle = playlist
                    playlist = Playlist(fullSingle.title)
                    playlist.id = fullSingle.id
                    playlist.addFields(fields, from: fullSingle)
                }
                playlists.append(playlist)
            }
        }
        return playlists
    }
    
    func getPlaylistCount() -> Int {
        var count = -1
        guard let db = db else {
            return count
        }
        let table = Table("playlist")
        do {
            count = try db.scalar(table.count)
        } catch {
        }
        return count
    }
    
    func playlistExists(_ id: String) throws -> Bool {
        var exists = false
        guard let db = db else {
            return exists
        }
        let table = Table("playlist")
        exists = try db.scalar(table.filter(self.id == id).count) == 1
        return exists
    }
    
    func getPlaylist(_ id: String) throws -> Playlist?  {
        var playlist: Playlist? = nil
        guard let db = db else {
            return playlist
        }
        let table = Table("playlist")
        for row in try db.prepare(table.select(json).filter(self.id == id)) {
            playlist = Playlist.decodeFrom(json: Data.fromDatatypeValue(row[json]))
            return playlist
        }
        return playlist
    }
    
    func postPlaylist(_ playlist: Playlist) throws -> Transaction  {
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("playlist")
        let transactionTable = Table("transaction")
        let transaction = Transaction(method: "POST", entity: "playlist", id: playlist.id)
        if let json = playlist.json {
            do {
                try db.transaction {
                    if let user = playlist.user {
                        try db.run(table.insert(self.id <- playlist.id, self.user <- user, shared <- playlist.shared, self.json <- json.datatypeValue))
                    } else {
                        try db.run(table.insert(self.id <- playlist.id, shared <- playlist.shared, self.json <- json.datatypeValue))
                    }
                    try db.run(transactionTable.insert(
                        time <- transaction.time,
                        method <- transaction.method,
                        entity <- transaction.entity,
                        id <- transaction.id))
                }
            } catch let Result.error(a, code, b) where code == SQLITE_CONSTRAINT {
                print(a)
                print(b)
                throw Abort(.found)
            } catch {
                throw Abort(.serviceUnavailable)
            }
        } else {
            throw Abort(.noContent)
        }
        return transaction
    }
    
    func putPlaylist(_ playlist: Playlist) throws -> Transaction {
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("playlist")
        let transactionTable = Table("transaction")
        let transaction = Transaction(method: "PUT", entity: "playlist", id: playlist.id)
        if let json = playlist.json {
            let playlistToModify = table.filter(id == playlist.id)
            do {
                try db.transaction {
                    var count = 0
                    if let user = playlist.user {
                        count = try db.run(playlistToModify.update(self.user <- user, shared <- playlist.shared, self.json <- json.datatypeValue))
                    } else {
                        count = try db.run(playlistToModify.update(shared <- playlist.shared, self.json <- json.datatypeValue))
                    }
                    if count > 0 {
                        try db.run(transactionTable.insert(
                            time <- transaction.time,
                            method <- transaction.method,
                            entity <- transaction.entity,
                            id <- transaction.id))
                    } else {
                        throw Abort(.notFound)
                    }
                }
            } catch {
                throw Abort(.notFound)
            }
        }
        return transaction
    }
    
    func deletePlaylist(_ id: String) throws -> Transaction {
        guard let db = db else {
            throw Abort(.serviceUnavailable)
        }
        let table = Table("playlist")
        let transactionTable = Table("transaction")
        do {
            let playlistToDelete = table.filter(self.id == id)
            let transaction = Transaction(method: "DELETE", entity: "playlist", id: id)
            try db.transaction {
                if try db.run(playlistToDelete.delete()) > 0 {
                    try db.run(transactionTable.insert(
                        time <- transaction.time,
                        method <- transaction.method,
                        entity <- transaction.entity,
                        self.id <- transaction.id))
                } else {
                    throw Abort(.notFound)
                }
            }
            return transaction
        }
    }
}
