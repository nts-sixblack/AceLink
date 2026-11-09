import Foundation
import os

private struct GetPlaylistResponse: Decodable {
    let result: Result

    struct Result: Decodable {
        let playlist: [Playlist]
    }

    struct Playlist: Decodable {
        let title: String
    }
}

class AceStreamPlaylist: Service {
    let aceStreamEngine: AceStreamEngine
    let stream: StreamFile
    private let accessToken: String
    var title: String?

    override var defaultError: String { "Cannot get stream title." }

    init(aceStreamEngine: AceStreamEngine, stream: StreamFile) {
        self.aceStreamEngine = aceStreamEngine
        self.stream = stream
        // The engine only reports ready once it has an access token.
        accessToken = aceStreamEngine.accessToken ?? ""

        super.init()

        os_log("Getting stream title for %s=%s…", stream.param, stream.hash)

        let url = AppConstants.Docker.baseURL.appendingPathComponent("/server/api")
            .appendingQuery("method", "playlist_add_item")
            .appendingQuery("token", accessToken)
            .appendingQuery(stream.param, stream.hash)

        urlSession.dataTask(with: url).resume()
    }

    override func check() {
        let url = AppConstants.Docker.baseURL.appendingPathComponent("/server/api")
            .appendingQuery("method", "playlist_get")
            .appendingQuery("token", accessToken)

        urlSession.jsonDataTask(with: url, decodable: GetPlaylistResponse.self) { data in
            if let playlist = data?.result.playlist.first {
                os_log("Got title: %s", playlist.title)
                self.title = playlist.title
                self.callbackInMainThread()
                return
            }
            self.scheduleCheck()
        }.resume()
    }
}
