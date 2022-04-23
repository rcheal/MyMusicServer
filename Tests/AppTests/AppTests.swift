@testable import App
import XCTVapor
import MusicMetadata

let albumsEndpoint = "v1/albums"
let singlesEndpoint = "v1/singles"
let playlistsEndpoint = "v1/playlists"
let transactionsEndpoint = "v1/transactions"

struct Resource {
    let url: URL
    let baseURL: URL
    
    init(relativePath: String, sourceFile: StaticString = #file) throws {
        
        let testCaseURL = URL(fileURLWithPath: "\(sourceFile)", isDirectory: false)
        let testFolderURL = testCaseURL.deletingLastPathComponent()
        baseURL = testFolderURL.deletingLastPathComponent().appendingPathComponent("Resources", isDirectory: true)
        
        self.url = URL(fileURLWithPath: relativePath, relativeTo: baseURL)
    }
}


final class AppTests: XCTestCase {
    
    override func setUpWithError() throws {
//        Datastore.sharedInstance = nil
//        let ds = Datastore.create(memory: true)
//        
//        let musicDir = ds.fileRootURL.path
//        let fm = FileManager()
//        if fm.fileExists(atPath: musicDir) {
//            try! fm.removeItem(atPath: musicDir)
//        }
    }

    func createMixedAlbum() -> Album {
        var album = Album(title: "Test Album")
        let single1 = Single(title: "Song1", filename: "song1.mp3", track: 1)
        let single2 = Single(title: "Song2", filename: "song2.mp3", track: 2)
        let single3 = Single(title: "Song3", filename: "song3.mp3", track: 6)
        let single4 = Single(title: "Song4", filename: "song4.mp3", track: 1, disk: 2)
        let single5 = Single(title: "Song5", filename: "song5.mp3", track: 5, disk: 2)
        let single6 = Single(title: "Song6", filename: "song6.mp3", track: 6, disk: 2)

        var composition1 = Composition(title: "Composition1", track: 3)
        var composition2 = Composition(title: "Composition2", track: 2, disk: 2)
        
        let movement1 = Movement(title: "Movement1", filename: "file1.mp3", track: 3)
        let movement2 = Movement(title: "Movement2", filename: "file2.mp3", track: 4)
        let movement3 = Movement(title: "Movement3", filename: "file3.mp3", track: 5)
        composition1.addMovement(movement1)
        composition1.addMovement(movement2)
        composition1.addMovement(movement3)
                
        let movement4 = Movement(title: "Movement1", filename: "file4.mp3", track: 2, disk: 2)
        let movement5 = Movement(title: "Movement2", filename: "file5.mp3", track: 3, disk: 2)
        let movement6 = Movement(title: "Movement3", filename: "file6.mp3", track: 4, disk: 2)
        
        composition2.addMovement(movement4)
        composition2.addMovement(movement5)
        composition2.addMovement(movement6)
        
        album.addSingle(single1)
        album.addSingle(single2)
        album.addComposition(composition1)
        album.addSingle(single3)
        album.addSingle(single4)
        album.addComposition(composition2)
        album.addSingle(single5)
        album.addSingle(single6)

        return album
    }
    
    func createSibeliusAlbum() -> Album {
        var album = Album(title: "Jean Sibelius: Finlandia - Valse triste - Tapiola")
        album.subtitle = "Berliner Philharmoniker"
        album.artist = "Krystian Zimmerman"
        album.composer = "Jean Sibelius"
        album.conductor = "Herbert von Karajon"
        album.orchestra = "Berliner Philharmoniker"
        album.publisher = "Deutsche Grammophon"
        album.genre = "Classical"
        album.copyright = "1984 Deutsche Grammophon"
        album.encodedBy = "Created by RCheal"
        album.encoderSettings = "16 bit, 44100 samples per second"
        album.recordingYear = 1984
        album.addArt(AlbumArtRef(type: .front, format: .jpg))
        album.directory = "sebelius/finlania"
        
        album.duration = 1500
        
        return album
    }
    
    func createLisztAlbum() -> Album {
        var album = Album(title: "Liszt Piano Concertos 1 & 2")
        album.subtitle = "Totentanz"
        album.artist = "Krystian Zimmerman"
        album.composer = "Franz Liszt (1811-1886)"
        album.conductor = "Seiji Ozawa"
        album.orchestra = "Boston Symphony Orchestra"
        album.publisher = "Deutsche Grammophon"
        album.genre = "Classical"
        album.copyright = "1988 Deutsche Grammophon"
        album.encodedBy = "Created by Grip"
        album.recordingYear = 1988
        album.addArt(AlbumArtRef(type: .front, format: .jpg))
        album.directory = "liszt_piano_concertos_no1_2"
        
        var composition = Composition(title: "Piano Concerto No. 1 in E flat major", track: 1)
        composition.albumId = album.id

        var movement = Movement(title: "I. Allegro maestoso",
                                filename: "1__i_allegro_maestoso.m4a",
                                track: 1)
        movement.albumId = album.id
        movement.duration = 332
        composition.addMovement(movement)

        movement = Movement(title: "II. Quasi adagio - Alegretto vivace - Allegro animato",
                            filename: "1__ii_quasi_adagio__alegretto_vivace__allegro_animato.m4a",
                            track: 2)
        movement.albumId = album.id
        movement.duration = 534
        composition.addMovement(movement)

        movement = Movement(title: "III. Allegro marziale animato - Presto",
                            filename: "1__iii_allegro_marziale_animato__presto.m4a",
                            track: 3)
        movement.albumId = album.id
        movement.duration = 248
        composition.addMovement(movement)
        album.addComposition(composition)

        composition = Composition(title: "Piano Concerto No. 2 in A major", track: 4)
        composition.albumId = album.id

        movement = Movement(title: "I. Adagio sostenuto assai - Allegro agitato assai",
                            filename: "2__i_adagio_sostenuto_assai__allegro_agitato_assai.m4a",
                            track: 4)
        movement.albumId = album.id
        movement.duration = 446
        composition.addMovement(movement)

        movement = Movement(title: "II. Allegro moderato - Allegro deciso",
                            filename: "2__ii_allegro_moderato__allegro_deciso.m4a",
                            track: 5)
        movement.albumId = album.id
        movement.duration = 499
        composition.addMovement(movement)

        movement = Movement(title: "III. Marziale un poco meno allegro",
                            filename: "2__iii_marziale_un_poco_meno_allegro.m4a",
                            track: 6)
        movement.albumId = album.id
        movement.duration = 262
        composition.addMovement(movement)

        movement = Movement(title: "IV. Allegro animator - Stretto (molto accelerando)",
                            filename: "2__iv_allegro_animato__stretto_molto_accelerando.m4a",
                            track: 7)
        movement.albumId = album.id
        movement.duration = 111
        composition.addMovement(movement)

        album.addComposition(composition)

        var single = Single(title: "Totentanz (Danse macabre)",
                            filename: "totentanz_danse_macabre_paraphrase_on_dies_irae.m4a",
                            track: 8)
        single.albumId = album.id
        single.duration = 912
        
        album.addSingle(single)
        return album
    }
    
    func createLisztSingle() -> Single {
        var single = Single(title: "Totentanz (Danse macabre)",
                            filename: "totentanz_danse_macabre_paraphrase_on_dies_irae.m4a",
                            track: 1)
        single.artist = "Krystian Zimmerman"
        single.composer = "Franz Liszt (1811-1886)"
        single.conductor = "Seiji Ozawa"
        single.orchestra = "Boston Symphony Orchestra"
        single.publisher = "Deutsche Grammophon"
        single.genre = "Classical"
        single.copyright = "1988 Deutsche Grammophon"
        single.encodedBy = "Created by Grip"
        single.recordingYear = 1988
        single.directory = "liszt_totentanz"
 
        single.duration = 912
        return single
    }
    
    func createSingle(title: String, filename: String, track: Int) -> Single {
        var single = Single(title: title, filename: filename, track: track)
        single.disk = 1
        single.sortTitle = "SortTitle"
        single.subtitle = "SubTitle"
        single.artist = "Artist"
        single.sortArtist = "SortArtist"
        single.supportingArtists = "Artist1;Artist2;Artist3"
        single.composer = "Composer"
        single.sortComposer = "SortComposer"
        single.conductor = "Conductor"
        single.orchestra = "Orchestra"
        single.lyricist = "Lyricist"
        single.genre = "Genre"
        single.publisher = "Publisher"
        single.copyright = "Copyright"
        single.encodedBy = "EncodedBy"
        single.encoderSettings = "EncoderSettings"
        single.recordingYear = 2020
        single.duration = 1800

        return single
    }

    func populateDB(_ app: Application) throws {
        let album = createLisztAlbum()
        let newAlbum = createSibeliusAlbum()

        let albumBuf = ByteBuffer(data: album.json ?? Data())
        let newAlbumBuf = ByteBuffer(data: newAlbum.json ?? Data())
        
        try app.test(.POST, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try app.test(.POST, "\(albumsEndpoint)/\(newAlbum.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newAlbumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        let single = createLisztSingle()
        var newSingle = single
        newSingle.id = UUID().uuidString
        newSingle.title = "Second Single"
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        let newSingleBuf = ByteBuffer(data: newSingle.json ?? Data())
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.POST, "\(singlesEndpoint)/\(newSingle.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newSingleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
    }
    
    func testServerStatus() throws {
        // Given
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let expectedMinimumTimeStamp = formatter.string(from: Date())

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try populateDB(app)
        
        // Then
        try app.test(.GET, "", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            let serverStatus = try res.content.decode(APIServerStatus.self)
            
            XCTAssertEqual(serverStatus.version,myMusicServerVersion)
            XCTAssertEqual(serverStatus.apiVersions,myMusicApiVersions)
            XCTAssertEqual(serverStatus.name, "Robert’s Mac Studio")
            XCTAssertEqual(serverStatus.address, "127.0.0.1:8888")
            XCTAssertEqual(serverStatus.albumCount, 2)
            XCTAssertEqual(serverStatus.singleCount, 2)
            XCTAssertEqual(serverStatus.playlistCount, 0)

            XCTAssertLessThan(serverStatus.upTime ?? 0, 10)
            XCTAssertGreaterThan(serverStatus.lastTransactionTime!, expectedMinimumTimeStamp)
            
        })
    }
    
    func testGetAlbumNotFound() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "\(albumsEndpoint)/\(album.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })
    }
    
    func testPutAlbumNotFound() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.PUT, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
        try app.test(.GET, "\(albumsEndpoint)/\(album.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })

    }
    
    func testPostPutAlbum() throws {
        let album = createMixedAlbum()
        var newAlbum = album
        newAlbum.title = "New title"
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)


        if let jsonp = album.jsonp {
            print(String(decoding: jsonp, as: UTF8.self))
        }
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        let newAlbumBuf = ByteBuffer(data: newAlbum.json ?? Data())
        
        try app.test(.POST, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.PUT, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newAlbumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(albumsEndpoint)/\(album.id)", afterResponse:  { res in
            let newAlbum = try res.content.decode(Album.self)
            XCTAssertEqual(album.id, newAlbum.id)
            XCTAssertEqual(newAlbum.title, "New title")
            
        })
    }
    
    func testPostGetAlbum() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.POST, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(albumsEndpoint)/\(album.id)", afterResponse:  { res in
            let newAlbum = try res.content.decode(Album.self)
            XCTAssertEqual(album.id, newAlbum.id)
            XCTAssertEqual(album.title, newAlbum.title)
            XCTAssertEqual(album.subtitle, newAlbum.subtitle)
            XCTAssertEqual(album.artist, newAlbum.artist)
            XCTAssertEqual(album.composer, newAlbum.composer)
            XCTAssertEqual(album.conductor, newAlbum.conductor)
            XCTAssertEqual(album.lyricist, newAlbum.lyricist)
            
        })
    }
    
    func testPostDeleteAlbum() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.POST, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try app.test(.DELETE, "\(albumsEndpoint)/\(album.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(albumsEndpoint)/\(album.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testDeleteAlbumNotFound() throws {
        let album = createMixedAlbum()
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.DELETE, "\(albumsEndpoint)/\(album.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
    }

    func testGetSingleNotFound() throws {
        let single = createSingle(title: "Body and Soul", filename: "body&soul.mp3", track: 1)
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "\(singlesEndpoint)/\(single.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })
    }
    
    func testPostSingleFound() throws {
        let single = createSingle(title: "Body and Soul", filename: "body&soul.mp3", track: 1)

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            let transaction = try res.content.decode(Transaction.self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(transaction.id, single.id)
            XCTAssertEqual(transaction.method, "POST")
            XCTAssertEqual(transaction.entity, "single")
        })
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .conflict)
        })
        

    }
    
    func testPutSingleNotFound() throws {
        let single = createSingle(title: "Body and Soul", filename: "body&soul.mp3", track: 1)

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.PUT, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
        try app.test(.GET, "\(singlesEndpoint)/\(single.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })

    }
    
    func testPostPutSingle() throws {
        let single = createSingle(title: "Body and Soul", filename: "body&soul.mp3", track: 1)
        var newSingle = single
        newSingle.title = "New title"
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        let newSingleBuf = ByteBuffer(data: newSingle.json ?? Data())
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            let transaction = try res.content.decode(Transaction.self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(transaction.id, single.id)
            XCTAssertEqual(transaction.method, "POST")
            XCTAssertEqual(transaction.entity, "single")
        })
        
        try app.test(.PUT, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newSingleBuf, afterResponse: { res in
            let transaction = try res.content.decode(Transaction.self)
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(transaction.id, single.id)
            XCTAssertEqual(transaction.method, "PUT")
            XCTAssertEqual(transaction.entity, "single")
        })
        
        try app.test(.GET, "\(singlesEndpoint)/\(single.id)", afterResponse:  { res in
            let newSingle = try res.content.decode(Single.self)
            XCTAssertEqual(single.id, newSingle.id)
            XCTAssertEqual(newSingle.title, "New title")
            
        })
    }
    
    func testPostGetSingle() throws {
        let single = createSingle(title: "Body and Soul", filename: "body&soul.mp3", track: 1)

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(singlesEndpoint)/\(single.id)", afterResponse:  { res in
            let newSingle = try res.content.decode(Single.self)
            XCTAssertEqual(single.id, newSingle.id)
            XCTAssertEqual(single.title, newSingle.title)
            XCTAssertEqual(single.subtitle, newSingle.subtitle)
            XCTAssertEqual(single.artist, newSingle.artist)
            XCTAssertEqual(single.composer, newSingle.composer)
            XCTAssertEqual(single.conductor, newSingle.conductor)
            XCTAssertEqual(single.lyricist, newSingle.lyricist)
            
        })
    }
    
    func testPostDeleteSingle() throws {
        let single = createSingle(title: "Body and Soul", filename: "body&soul.mp3", track: 1)

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try app.test(.DELETE, "\(singlesEndpoint)/\(single.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(singlesEndpoint)/\(single.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testDeleteSingleNotFound() throws {
        let single = createSingle(title: "Body and Soul", filename: "body&soul.mp3", track: 1)

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.DELETE, "\(singlesEndpoint)/\(single.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
    }
    
    func testPostGetAlbumFiles() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        // POST Liszt album
        let album = createLisztAlbum()
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        
        try app.test(.POST, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        
        // POST album files
        if let directory = album.directory {
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
            // POST artwork
            let frontFilename = album.frontArtRef()?.filename ?? "front.jpg"
            let fileURL = dirURL.appendingPathComponent(frontFilename)
            let fm = FileManager.default
            let data = fm.contents(atPath: fileURL.path)
            let dataBuf = ByteBuffer(data: data ?? Data())

            try app.test(.POST, "\(albumsEndpoint)/\(album.id)/\(frontFilename)",
                         headers: HTTPHeaders([("Content-Type", "application/jpeg")]),
                         body: dataBuf, afterResponse: { res in
                            XCTAssertEqual(res.status, .ok)
                         })
            
            for content in album.contents {
                if let single = content.single {
                    // post single audio file
                    let audiofileName = single.filename
                        let fileURL = dirURL.appendingPathComponent(audiofileName)
                        let data = fm.contents(atPath: fileURL.path)
                        let dataBuf = ByteBuffer(data: data ?? Data())
                        
                        try app.test(.POST, "\(albumsEndpoint)/\(album.id)/\(audiofileName)",
                                     headers: HTTPHeaders([("Content-Type", "application/m4a")]),
                                     body: dataBuf, afterResponse: { res in
                                        XCTAssertEqual(res.status, .ok)
                                     })
                    
                } else if let composition = content.composition {
                    for movement in composition.movements {
                        // post movement audio file
                        let fileURL = dirURL.appendingPathComponent(movement.filename)
                        let data = fm.contents(atPath: fileURL.path)
                        let dataBuf = ByteBuffer(data: data ?? Data())
                        
                        try app.test(.POST, "\(albumsEndpoint)/\(album.id)/\(movement.filename)",
                                     headers: HTTPHeaders([("Content-Type", "application/m4a")]),
                                     body: dataBuf, afterResponse: { res in
                                        XCTAssertEqual(res.status, .ok)
                                     })
                    }
                }
            }

        }

        // GET and verify album
        try app.test(.GET, "\(albumsEndpoint)/\(album.id)", afterResponse:  { res in
            let newAlbum = try res.content.decode(Album.self)
            XCTAssertEqual(album.id, newAlbum.id)
            XCTAssertEqual(album.title, newAlbum.title)
            XCTAssertEqual(album.subtitle, newAlbum.subtitle)
            XCTAssertEqual(album.artist, newAlbum.artist)
            XCTAssertEqual(album.composer, newAlbum.composer)
            XCTAssertEqual(album.conductor, newAlbum.conductor)
            XCTAssertEqual(album.orchestra, newAlbum.orchestra)
            XCTAssertEqual(album.lyricist, newAlbum.lyricist)
            XCTAssertEqual(album.publisher, newAlbum.publisher)
            XCTAssertEqual(album.genre, newAlbum.genre)
            XCTAssertEqual(album.copyright, newAlbum.copyright)
            XCTAssertEqual(album.encodedBy, newAlbum.encodedBy)
            XCTAssertEqual(album.encoderSettings, newAlbum.encoderSettings)
            XCTAssertEqual(album.recordingYear, newAlbum.recordingYear)
            XCTAssertEqual(album.directory, newAlbum.directory)
            XCTAssertEqual(album.frontArtRef(), newAlbum.frontArtRef())
            XCTAssertEqual(album.contents.count, newAlbum.contents.count)
            for index in 0..<album.contents.count {
                XCTAssertEqual(album.contents[index].id, newAlbum.contents[index].id)
                XCTAssertEqual(album.contents[index].disk, newAlbum.contents[index].disk)
                XCTAssertEqual(album.contents[index].track, newAlbum.contents[index].track)
                if let comp1 = album.contents[index].composition,
                   let comp2 = newAlbum.contents[index].composition {
                    XCTAssertEqual(comp1.id, comp2.id)
                    XCTAssertEqual(comp1.startTrack, comp2.startTrack)
                    XCTAssertEqual(comp1.title, comp2.title)
                }

            }
        })

        // GET and verify related files
        if let directory = album.directory {
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
            // post artwork
            let frontFilename = album.frontArtRef()?.filename ?? "front.jpg"
            let fileURL = dirURL.appendingPathComponent(frontFilename)
            let fm = FileManager.default
            let data = fm.contents(atPath: fileURL.path) ?? Data()
            let dataBuf = ByteBuffer(data: data)

            try app.test(.GET, "\(albumsEndpoint)/\(album.id)/\(frontFilename)", afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(res.body, dataBuf)
            })
            
            for content in album.contents {
                if let single = content.single {
                    let audioFilename = single.filename
                    let fileURL = dirURL.appendingPathComponent(audioFilename)
                    let data = fm.contents(atPath: fileURL.path) ?? Data()
                    let dataBuf = ByteBuffer(data: data)
                    
                    try app.test(.GET, "\(albumsEndpoint)/\(album.id)/\(audioFilename)", afterResponse: { res in
                        XCTAssertEqual(res.status, .ok)
                        XCTAssertEqual(res.body, dataBuf)
                    })
                } else if let composition = content.composition {
                    for movement in composition.movements {
                        let filename = movement.filename
                        let fileURL = dirURL.appendingPathComponent(filename)
                        let data = fm.contents(atPath: fileURL.path) ?? Data()
                        let dataBuf = ByteBuffer(data: data)
                        
                        try app.test(.GET, "\(albumsEndpoint)/\(album.id)/\(filename)", afterResponse: { res in
                            XCTAssertEqual(res.status, .ok)
                            XCTAssertEqual(res.body, dataBuf)
                        })
                    }
                }
            }

        }
    }

    func testPostGetSingleFiles() throws {
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        // POST Liszt single
        let single = createLisztSingle()
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        
        // POST single audio file
        if let directory = single.directory {
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
            
            let fm = FileManager.default

            // post single audio file
            let audiofileName = single.filename
                let fileURL = dirURL.appendingPathComponent(audiofileName)
                let data = fm.contents(atPath: fileURL.path)
                let dataBuf = ByteBuffer(data: data ?? Data())
                
                try app.test(.POST, "\(singlesEndpoint)/\(single.id)/\(audiofileName)",
                             headers: HTTPHeaders([("Content-Type", "application/m4a")]),
                             body: dataBuf, afterResponse: { res in
                                XCTAssertEqual(res.status, .ok)
                             })
            
        }

        // GET and verify single
        try app.test(.GET, "\(singlesEndpoint)/\(single.id)", afterResponse:  { res in
            let newSingle = try res.content.decode(Single.self)
            XCTAssertEqual(single.id, newSingle.id)
            XCTAssertEqual(single.title, newSingle.title)
            XCTAssertEqual(single.subtitle, newSingle.subtitle)
            XCTAssertEqual(single.artist, newSingle.artist)
            XCTAssertEqual(single.composer, newSingle.composer)
            XCTAssertEqual(single.conductor, newSingle.conductor)
            XCTAssertEqual(single.orchestra, newSingle.orchestra)
            XCTAssertEqual(single.lyricist, newSingle.lyricist)
            XCTAssertEqual(single.publisher, newSingle.publisher)
            XCTAssertEqual(single.genre, newSingle.genre)
            XCTAssertEqual(single.copyright, newSingle.copyright)
            XCTAssertEqual(single.encodedBy, newSingle.encodedBy)
            XCTAssertEqual(single.encoderSettings, newSingle.encoderSettings)
            XCTAssertEqual(single.recordingYear, newSingle.recordingYear)
            XCTAssertEqual(single.directory, newSingle.directory)
        })

        // GET and verify audio file
        if let directory = single.directory {
            let fm = FileManager.default
            let resourceURL = try Resource(relativePath: directory)
            let dirURL = resourceURL.url
                let audioFilename = single.filename
                let fileURL = dirURL.appendingPathComponent(audioFilename)
                let data = fm.contents(atPath: fileURL.path) ?? Data()
                let dataBuf = ByteBuffer(data: data)
                
                try app.test(.GET, "\(singlesEndpoint)/\(single.id)/\(audioFilename)", afterResponse: { res in
                    XCTAssertEqual(res.status, .ok)
                    XCTAssertEqual(res.body, dataBuf)
                })

        }
    }

    func testAlbumList() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try populateDB(app)
        
        try app.test(.GET, "\(albumsEndpoint)") { res in
            let result = try res.content.decode(APIAlbums.self)
            XCTAssertEqual(result.albums.count, 2)
            for index in result.albums.indices {
                let album = result.albums[index]
                switch index {
                case 0:
                    XCTAssertEqual(album.title,"Liszt Piano Concertos 1 & 2")
                    XCTAssertEqual(album.artist, "Krystian Zimmerman")
                    XCTAssertNil(album.supportingArtists)
                    XCTAssertEqual(album.composer, "Franz Liszt (1811-1886)")
                    XCTAssertEqual(album.conductor, "Seiji Ozawa")
                    XCTAssertEqual(album.orchestra, "Boston Symphony Orchestra")
                    XCTAssertNil(album.lyricist)
                    XCTAssertEqual(album.genre, "Classical")
                    XCTAssertEqual(album.publisher, "Deutsche Grammophon")
                    XCTAssertEqual(album.copyright, "1988 Deutsche Grammophon")
                    XCTAssertEqual(album.encodedBy, "Created by Grip")
                    XCTAssertNil(album.encoderSettings)
                    XCTAssertEqual(album.recordingYear, 1988)
                    XCTAssertEqual(album.duration, 3344)
                    XCTAssertEqual(album.directory, "liszt_piano_concertos_no1_2")
                    XCTAssertEqual(album.artworkCount(), 1)
                case 1:
                    XCTAssertEqual(album.title,"Jean Sibelius: Finlandia - Valse triste - Tapiola")
                    XCTAssertEqual(album.artist, "Krystian Zimmerman")
                    XCTAssertNil(album.supportingArtists)
                    XCTAssertEqual(album.composer, "Jean Sibelius")
                    XCTAssertEqual(album.conductor, "Herbert von Karajon")
                    XCTAssertEqual(album.orchestra, "Berliner Philharmoniker")
                    XCTAssertNil(album.lyricist)
                    XCTAssertEqual(album.genre, "Classical")
                    XCTAssertEqual(album.publisher, "Deutsche Grammophon")
                    XCTAssertEqual(album.copyright, "1984 Deutsche Grammophon")
                    XCTAssertEqual(album.encodedBy, "Created by RCheal")
                    XCTAssertEqual(album.encoderSettings, "16 bit, 44100 samples per second")
                    XCTAssertEqual(album.recordingYear, 1984)
                    XCTAssertEqual(album.duration, 1500)
                    XCTAssertEqual(album.directory, "sebelius/finlania")
                    XCTAssertEqual(album.artworkCount(), 1)
                default:
                    break
                }
            }
        }
    }
    
    func testAlbumList2() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try populateDB(app)
        
        try app.test(.GET, albumsEndpoint, beforeRequest: { req in
            try req.query.encode(["limit" : "1", "offset" : "1",
                                  "fields" : "artist,composer,genre,recordingYear,directory,frontArt"])
        }, afterResponse: { res in
            let result = try res.content.decode(APIAlbums.self)
            XCTAssertEqual(result.albums.count, 1)
            if let album = result.albums.first {
                XCTAssertEqual(album.title,"Jean Sibelius: Finlandia - Valse triste - Tapiola")
                XCTAssertEqual(album.artist, "Krystian Zimmerman")
                XCTAssertNil(album.supportingArtists)
                XCTAssertEqual(album.composer, "Jean Sibelius")
                XCTAssertNil(album.conductor)
                XCTAssertNil(album.orchestra)
                XCTAssertNil(album.lyricist)
                XCTAssertEqual(album.genre, "Classical")
                XCTAssertNil(album.publisher)
                XCTAssertNil(album.copyright)
                XCTAssertNil(album.encodedBy)
                XCTAssertNil(album.encoderSettings)
                XCTAssertEqual(album.recordingYear, 1984)
                XCTAssertEqual(album.duration, 0)
                XCTAssertEqual(album.directory, "sebelius/finlania")
                XCTAssertEqual(album.artworkCount(), 1)
                XCTAssertEqual(album.frontArtRef()?.filename, "front.jpg")
            }
        })
    }
    
    func testSingleList() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try populateDB(app)
        
        try app.test(.GET, "\(singlesEndpoint)") { res in
            let result = try res.content.decode(APISingles.self)
            XCTAssertEqual(result.singles.count, 2)
            for index in result.singles.indices {
                let single = result.singles[index]
                if index == 0 {
                    XCTAssertEqual(single.title, "Totentanz (Danse macabre)")
                } else {
                    XCTAssertEqual(single.title, "Second Single")
                }
                XCTAssertNil(single.subtitle)
                XCTAssertEqual(single.artist, "Krystian Zimmerman")
                XCTAssertNil(single.supportingArtists)
                XCTAssertEqual(single.composer, "Franz Liszt (1811-1886)")
                XCTAssertEqual(single.conductor, "Seiji Ozawa")
                XCTAssertEqual(single.orchestra, "Boston Symphony Orchestra")
                XCTAssertNil(single.lyricist)
                XCTAssertEqual(single.genre, "Classical")
                XCTAssertEqual(single.publisher, "Deutsche Grammophon")
                XCTAssertEqual(single.copyright, "1988 Deutsche Grammophon")
                XCTAssertEqual(single.encodedBy, "Created by Grip")
                XCTAssertNil(single.encoderSettings)
                XCTAssertEqual(single.recordingYear, 1988)
                XCTAssertEqual(single.duration, 912)
                XCTAssertEqual(single.directory, "liszt_totentanz")
                XCTAssertNil(single.sortTitle)
                XCTAssertNil(single.sortArtist)
                XCTAssertNil(single.sortComposer)
                XCTAssertEqual(single.filename, "totentanz_danse_macabre_paraphrase_on_dies_irae.m4a")
            }
        }
    }
    
    func testSingleList2() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try populateDB(app)
        
        try app.test(.GET, singlesEndpoint, beforeRequest: { req in
            try req.query.encode(["limit" : "1", "offset" : "1",
                                  "fields" : "artist,composer,genre,recordingYear"])
        }, afterResponse: { res in
            let result = try res.content.decode(APISingles.self)
            XCTAssertEqual(result.singles.count, 1)
            if let single = result.singles.first {
                XCTAssertEqual(single.title, "Second Single")
                XCTAssertEqual(single.artist, "Krystian Zimmerman")
                XCTAssertNil(single.supportingArtists)
                XCTAssertEqual(single.composer, "Franz Liszt (1811-1886)")
                XCTAssertNil(single.conductor)
                XCTAssertNil(single.orchestra)
                XCTAssertNil(single.lyricist)
                XCTAssertEqual(single.genre, "Classical")
                XCTAssertNil(single.publisher)
                XCTAssertNil(single.copyright)
                XCTAssertNil(single.encodedBy)
                XCTAssertNil(single.encoderSettings)
                XCTAssertEqual(single.recordingYear, 1988)
                XCTAssertEqual(single.duration, 0)
                XCTAssertNil(single.directory)
                XCTAssertNil(single.sortTitle)
                XCTAssertNil(single.sortArtist)
                XCTAssertNil(single.sortComposer)
                XCTAssertEqual(single.filename, "")
            }
        })
    }
    
    func testVerifyAlbumTransactions() throws {
        let album = createMixedAlbum()
        var newAlbum = album
        newAlbum.title = "New title"

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let albumBuf = ByteBuffer(data: album.json ?? Data())
        let newAlbumBuf = ByteBuffer(data: newAlbum.json ?? Data())
        
        try app.test(.POST, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: albumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.PUT, "\(albumsEndpoint)/\(album.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newAlbumBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.DELETE, "\(albumsEndpoint)/\(album.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(transactionsEndpoint)", beforeRequest: { req in
            try req.query.encode(["startTime" : "0"])
        }, afterResponse:  { res in
            let result = try res.content.decode(APITransactions.self)
            XCTAssertEqual(result.transactions.count, 3)
            
            for index in result.transactions.indices {
                let transaction = result.transactions[index]
                switch index {
                case 0:
                    XCTAssertEqual(transaction.method, "POST")
                    XCTAssertEqual(transaction.entity, "album")
                    XCTAssertEqual(transaction.id, album.id)
//                    print(transaction.time)
                case 1:
                    XCTAssertEqual(transaction.method, "PUT")
                    XCTAssertEqual(transaction.entity, "album")
                    XCTAssertEqual(transaction.id, album.id)
//                    print(transaction.time)
                case 2:
                    XCTAssertEqual(transaction.method, "DELETE")
                    XCTAssertEqual(transaction.entity, "album")
                    XCTAssertEqual(transaction.id, album.id)
//                    print(transaction.time)
                default:
                    break
                }

            }
            
        })

    }

    func testVerifySingleTransactions() throws {
        let single = createLisztSingle()
        var newSingle = single
        newSingle.title = "New title"

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let singleBuf = ByteBuffer(data: single.json ?? Data())
        let nwSingleBuf = ByteBuffer(data: newSingle.json ?? Data())
        
        try app.test(.POST, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: singleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.PUT, "\(singlesEndpoint)/\(single.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: nwSingleBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.DELETE, "\(singlesEndpoint)/\(single.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(transactionsEndpoint)", beforeRequest: { req in
            try req.query.encode(["startTime" : "0"])
        }, afterResponse:  { res in
            let result = try res.content.decode(APITransactions.self)
            XCTAssertEqual(result.transactions.count, 3)
            
            for index in result.transactions.indices {
                let transaction = result.transactions[index]
                switch index {
                case 0:
                    XCTAssertEqual(transaction.method, "POST")
                    XCTAssertEqual(transaction.entity, "single")
                    XCTAssertEqual(transaction.id, single.id)
//                    print(transaction.time)
                case 1:
                    XCTAssertEqual(transaction.method, "PUT")
                    XCTAssertEqual(transaction.entity, "single")
                    XCTAssertEqual(transaction.id, single.id)
//                    print(transaction.time)
                case 2:
                    XCTAssertEqual(transaction.method, "DELETE")
                    XCTAssertEqual(transaction.entity, "single")
                    XCTAssertEqual(transaction.id, single.id)
//                    print(transaction.time)
                default:
                    break
                }

            }
            
        })

    }

    func testGetPlaylistNotFound() throws {
        let playlist = Playlist("New Playlist")
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "\(playlistsEndpoint)/\(playlist.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })
    }

    func testPutPlaylistNotFound() throws {
        let playlist = Playlist("Playlist1")

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        let playlistBuf = ByteBuffer(data: playlist.json ?? Data())
        
        try app.test(.PUT, "\(playlistsEndpoint)/\(playlist.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: playlistBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
        try app.test(.GET, "\(playlistsEndpoint)/\(playlist.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)

        })

    }
    
    func testPostPutPlaylist() throws {
        let playlist = Playlist("Playlist1", shared: true)
        var newPlaylist = playlist
        newPlaylist.title = "New title"
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let playlistBuf = ByteBuffer(data: playlist.json ?? Data())
        let newPlaylistBuf = ByteBuffer(data: newPlaylist.json ?? Data())
        
        try app.test(.POST, "\(playlistsEndpoint)/\(playlist.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: playlistBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.PUT, "\(playlistsEndpoint)/\(playlist.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: newPlaylistBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(playlistsEndpoint)/\(playlist.id)", afterResponse:  { res in
            let newPlaylist = try res.content.decode(Playlist.self)
            XCTAssertEqual(playlist.id, newPlaylist.id)
            XCTAssertEqual(newPlaylist.title, "New title")
            
        })
    }
    
    func testPostGetPlaylist() throws {
        var playlist = Playlist("Playlist1", shared: true)
        playlist.user = "Bob"

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let playlistBuf = ByteBuffer(data: playlist.json ?? Data())
        
        try app.test(.POST, "\(playlistsEndpoint)/\(playlist.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: playlistBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(playlistsEndpoint)/\(playlist.id)", afterResponse:  { res in
            let newPlaylist = try res.content.decode(Playlist.self)
            XCTAssertEqual(playlist.id, newPlaylist.id)
            XCTAssertEqual(playlist.title, newPlaylist.title)
            XCTAssertEqual(playlist.user, newPlaylist.user)
            
        })
    }

    func testPostDeletePlaylist() throws {
        let playlist = Playlist("Blues guitar", shared: false)

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let playlistBuf = ByteBuffer(data: playlist.json ?? Data())
        
        try app.test(.POST, "\(playlistsEndpoint)/\(playlist.id)", headers: HTTPHeaders([("Content-Type", "application/json")]), body: playlistBuf, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        try app.test(.DELETE, "\(playlistsEndpoint)/\(playlist.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
        
        try app.test(.GET, "\(playlistsEndpoint)/\(playlist.id)", afterResponse:  { res in
            XCTAssertEqual(res.status, .notFound)
        })
    }
    
    func testDeletePlaylistNotFound() throws {
        let playlist = Playlist("Playlist1")

        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        try app.test(.DELETE, "\(playlistsEndpoint)/\(playlist.id)", afterResponse: { res in
            XCTAssertEqual(res.status, .notFound)
        })
        
    }
    

}

