import Cocoa
import Foundation
import os

private struct GetStreamInfoResponse: Decodable {
    let response: StreamInfoResponse?
    let error: String?
}

private struct StreamInfoResponse: Decodable {
    let statURLString: String
    enum CodingKeys: String, CodingKey {
        case statURLString = "stat_url"
    }
}

struct StreamFile {
    var hash: String
    var type: AppConstants.StreamType
    var title: String = "Unknown stream"
    var playlistURL = URL(string: "http://127.0.0.1:\(AppConstants.Docker.proxyPort)/acelink.m3u8")!

    var param: String {
        switch type {
        case AppConstants.StreamType.magnet:
            return "infohash"
        default:
            return "id"
        }
    }

    var streamURL: URL {
        AppConstants.Docker.baseURL
            .appendingPathComponent("/ace/getstream")
            .appendingQuery(param, hash)
    }

    // Title with line breaks and other control characters removed, so it cannot add lines to
    // the playlist.
    var safeTitle: String {
        title.components(separatedBy: .controlCharacters).joined(separator: " ")
    }

    // File name for the history entry; path separators and leading dots are removed so the
    // file always lands inside the streams directory.
    var historyFileName: String {
        var name = safeTitle
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespaces)
        while name.hasPrefix(".") {
            name.removeFirst()
        }
        if name.isEmpty {
            name = "Unknown stream"
        }
        return String(name.prefix(200)) + ".m3u8"
    }

    var m3uData: String {
        "#EXTM3U\n#EXTINF:0, Ace Link - \(safeTitle)\n\(streamURL.absoluteString)"
    }

    func addToHistory() {
        let dir = AppConfig.streamsDir
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            let file = dir.appendingPathComponent(historyFileName)
            os_log("Writing data file to %{public}s to maintain history.", file.path)
            try m3uData.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            os_log("Writing data file failed: %{public}@", error.localizedDescription)
        }
    }

    func waitForPeers(callback: @escaping (AppError?) -> Void) {
        getStreamInfo { streamInfo in
            guard let statURLString = streamInfo?.response?.statURLString,
                  let statURL = URL(string: statURLString) else {
                let message = streamInfo?.error ?? "Cannot get stream info."
                DispatchQueue.main.async {
                    callback(AppError(message))
                }
                return
            }
            StreamPeers(statURL: statURL).task { result in
                callback(result)
            }
        }
    }

    func getURLForBundleType(_ bundle: Bundle) -> URL {
        if bundle.isBrowser {
            return AppConstants.Docker.baseURL.appendingPathComponent("/webui/player/\(hash)")
        } else {
            return playlistURL
        }
    }

    private func getStreamInfo(callback: @escaping (GetStreamInfoResponse?) -> Void) {
        os_log("Getting stream session urls…")
        let urlSession = URLSession(configuration: .ephemeral)
        let url = streamURL.appendingQuery("format", "json")
        urlSession.jsonDataTask(with: url, decodable: GetStreamInfoResponse.self) { streamInfo in
            callback(streamInfo)
        }.resume()
    }
}
