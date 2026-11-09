import Cocoa
import Foundation
import os

enum ExtractStream {
    static func from(applicationURL: URL) -> StreamFile? {
        os_log("applicationURL: %{public}s", applicationURL.debugDescription)
        if let components = URLComponents(url: applicationURL, resolvingAgainstBaseURL: true) {
            for scheme in AppConstants.Scheme.allCases where scheme.rawValue == components.scheme {
                return from(unverifiedData: applicationURL.absoluteString)
            }
        }
        return nil
    }

    static func from(unverifiedData: String) -> StreamFile? {
        let hash: String
        let type: AppConstants.StreamType

        if unverifiedData.range(of: AppConstants.Scheme.magnet.rawValue) != nil {
            hash = getMagnetHash(unverifiedData)
            type = AppConstants.StreamType.magnet
        } else {
            hash = getAceStreamHash(unverifiedData)
            type = AppConstants.StreamType.acestream
        }
        if !hash.isEmpty {
            guard isValidHexHash(hash) else {
                return nil
            }
        }
        return StreamFile(hash: hash, type: type)
    }

    static func from(historyURL: URL) -> StreamFile? {
        guard let items = URLComponents(url: historyURL, resolvingAgainstBaseURL: false)?
            .queryItems else {
            return nil
        }
        let idParams = items.filter { $0.name == "id" }
        if let hash = idParams.first?.value {
            guard isValidHexHash(hash) else { return nil }
            return StreamFile(hash: hash, type: AppConstants.StreamType.acestream)
        }
        let infohashParams = items.filter { $0.name == "infohash" }
        if let infohash = infohashParams.first?.value {
            guard isValidHexHash(infohash) else { return nil }
            return StreamFile(hash: infohash, type: AppConstants.StreamType.magnet)
        }
        return nil
    }

    private static func isValidHexHash(_ hash: String) -> Bool {
        hash.matches(for: "^[a-fA-F0-9]{40}$").count == 1
    }

    private static func getAceStreamHash(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
            of: AppConstants.Scheme.acestream.rawValue + "://",
            with: ""
        )
    }

    private static func getMagnetHash(_ string: String) -> String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        // Search for urn:btih:<hash> parameter anywhere in the magnet URI.
        let matches = trimmed.matches(for: "(?i)urn:btih:([a-zA-Z0-9]+)")
        guard let rawHash = matches.first, !rawHash.isEmpty else {
            return "" // Start AceStream engine only
        }

        // 40-char hex (SHA1)
        if rawHash.matches(for: "^[a-fA-F0-9]{40}$").count == 1 {
            return rawHash.lowercased()
        }

        // 32-char Base32 infohash -> convert to 40-char hex
        if rawHash.matches(for: "^[a-zA-Z2-7]{32}$").count == 1,
           let hex = base32ToHex(rawHash) {
            return hex.lowercased()
        }

        return rawHash
    }

    private static func base32ToHex(_ base32: String) -> String? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bits = 0
        var bitCount = 0
        var bytes = [UInt8]()

        for char in base32.uppercased() {
            guard let index = alphabet.firstIndex(of: char) else {
                return nil
            }
            let val = alphabet.distance(from: alphabet.startIndex, to: index)
            bits = (bits << 5) | val
            bitCount += 5
            if bitCount >= 8 {
                bitCount -= 8
                bytes.append(UInt8((bits >> bitCount) & 0xFF))
            }
        }

        guard bytes.count == 20 else { return nil }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}
