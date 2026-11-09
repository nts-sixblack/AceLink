import Foundation

// QuickTime and Safari cannot play streams when loaded from a m3u8 file from the local filesystem.
class PlaylistServer: Service {
    private let engine: AceStreamEngine
    private let stream: StreamFile
    override var defaultError: String { "Cannot launch Python server." }

    init(engine: AceStreamEngine, stream: StreamFile) {
        self.engine = engine
        self.stream = stream
        super.init()
    }

    override func run() {
        guard let containerID = engine.containerID else {
            callbackInMainThread(AppError(defaultError))
            return
        }
        // The playlist contents (which include the stream title, controlled by the stream
        // publisher) are passed as an environment variable, never interpolated into the shell
        // command, so they cannot inject commands.
        let cmdInContainer = "printf '%s\\n' \"$ACELINK_M3U\" > acelink.m3u8;" +
            "exec python3 -m http.server \(AppConstants.Docker.proxyPort)"
        _ = Process.runCommand(
            "docker", "exec", "--detach", "--workdir=/acelink",
            "--env", "ACELINK_M3U=\(stream.m3uData)",
            containerID,
            "sh", "-c", cmdInContainer
        )
    }

    override func check() {
        urlSession.dataTask(with: stream.playlistURL) { _, response, _ in
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.callbackInMainThread()
                    return
                }
            }
            self.scheduleCheck()
        }.resume()
    }
}
