import Cocoa
import Foundation

class DockerEngine: Service {
    override var maxWait: DispatchTimeInterval { DispatchTimeInterval.seconds(180) }
    override var checkEverySeconds: Double { 2.0 }
    override var defaultError: String { "Cannot start Docker engine." }

    override func run() {
        let candidateBundleIDs = [
            "dev.kdrag0n.MacVirt",   // OrbStack
            AppConstants.Docker.bundleID // Docker Desktop ("com.docker.docker")
        ]
        for bundleID in candidateBundleIDs
            where NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil {
            _ = Process.runCommand("open", "-b", bundleID, "--hide", "--background")
            return
        }
        _ = Process.runCommand("open", "-b", AppConstants.Docker.bundleID, "--hide", "--background")
    }

    override func hasRunSuccesfully() -> Bool {
        let process = Process.runCommand("docker", "ps")
        return process.terminationStatus == 0
    }
}
