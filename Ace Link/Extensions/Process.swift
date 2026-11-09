import Foundation
import os

// Weak maps to store additional data for the extension with thread-safe lock.
private let mapLock = NSLock()
private let standardOutputMap = NSMapTable<Process, NSString>.weakToStrongObjects()
private let standardErrorMap = NSMapTable<Process, NSString>.weakToStrongObjects()

extension Process {
    var standardOutContents: String {
        get {
            mapLock.lock()
            defer { mapLock.unlock() }
            return (standardOutputMap.object(forKey: self) as String?) ?? ""
        }
        set {
            mapLock.lock()
            defer { mapLock.unlock() }
            standardOutputMap.setObject(NSString(string: newValue), forKey: self)
        }
    }

    var standardErrorContents: String {
        get {
            mapLock.lock()
            defer { mapLock.unlock() }
            return (standardErrorMap.object(forKey: self) as String?) ?? ""
        }
        set {
            mapLock.lock()
            defer { mapLock.unlock() }
            standardErrorMap.setObject(NSString(string: newValue), forKey: self)
        }
    }

    var userDockerSocket: String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidateSockets = [
            home + "/.docker/run/docker.sock",
            home + "/.orbstack/run/docker.sock",
            home + "/.colima/default/docker.sock",
            "/var/run/docker.sock"
        ]
        for socketPath in candidateSockets {
            if FileManager.default.fileExists(atPath: socketPath) {
                return socketPath
            }
        }
        return nil
    }

    static func runCommand(_ arguments: String...) -> Self {
        let process = Self()

        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        } else {
            process.launchPath = "/usr/bin/env"
        }
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        let existingPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        // Include Apple Silicon Homebrew (/opt/homebrew/bin), Intel Homebrew (/usr/local/bin), etc.
        env["PATH"] = existingPath + ":/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:/usr/local/sbin"
        env["DOCKER_DEFAULT_PLATFORM"] = "linux/amd64"

        // Respect existing DOCKER_HOST if configured, otherwise detect active socket.
        if env["DOCKER_HOST"] == nil || env["DOCKER_HOST"]?.isEmpty == true {
            if let userDockerSocket = process.userDockerSocket {
                env["DOCKER_HOST"] = "unix://" + userDockerSocket
            }
        }
        process.environment = env

        let commandStr = arguments.joined(separator: " ").scrubHashes()
        os_log("Running command: %{public}@", commandStr as NSString)

        let outputPipe = Pipe(), errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            if #available(macOS 10.13, *) {
                try process.run()
            } else {
                process.launch()
            }
        } catch {
            os_log("Process launch failed: %{public}@", error.localizedDescription as NSString)
            return process
        }

        // Drain both pipes while the process runs. Waiting for exit first deadlocks once the
        // output fills the pipe buffer, because the process blocks on write.
        var errorContents = ""
        let errorGroup = DispatchGroup()
        DispatchQueue.global().async(group: errorGroup) {
            errorContents = readPipeToEnd(errorPipe)
        }
        let outputContents = readPipeToEnd(outputPipe)
        errorGroup.wait()
        process.waitUntilExit()

        process.standardOutContents = outputContents
        process.standardErrorContents = errorContents

        let stdOutStr = process.standardOutContents.scrubHashes()
        let stdErrStr = process.standardErrorContents.scrubHashes()
        os_log("StandardOut: %{public}@", stdOutStr as NSString)
        os_log("standardError: %{public}@", stdErrStr as NSString)

        return process
    }

    private static func readPipeToEnd(_ pipe: Pipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let string = String(data: data, encoding: .utf8) {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
}
