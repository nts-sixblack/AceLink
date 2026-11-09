import Foundation
import os

class Service {
    private let started = DispatchTime.now()
    private let finishedLock = NSLock()
    private var finished = false
    let urlSession = URLSession(configuration: .ephemeral)

    // True once the callback has been scheduled; further checks and callbacks are ignored.
    var isFinished: Bool {
        finishedLock.lock()
        defer { finishedLock.unlock() }
        return finished
    }

    var callback: (AppError?) -> Void = { _ in }
    var error: () -> Void = {}
    var maxWait: DispatchTimeInterval { DispatchTimeInterval.seconds(30) }
    var checkEverySeconds: Double { 0.5 }
    var defaultError: String { "Timed out" }

    func hasRunSuccesfully() -> Bool { false }
    func run() {}

    init() {}

    func task(_ callback: @escaping (AppError?) -> Void) {
        self.callback = callback
        DispatchQueue.global().async {
            if self.hasRunSuccesfully() {
                self.callbackInMainThread()
            } else {
                self.run()
                if !self.isFinished {
                    self.check()
                }
            }
        }
    }

    func scheduleCheck() {
        if isFinished {
            return
        }
        if DispatchTime.now() >= started + maxWait {
            callbackInMainThread(AppError(defaultError))
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + checkEverySeconds) {
                self.check()
            }
        }
    }

    func check() {
        if hasRunSuccesfully() {
            callbackInMainThread()
            return
        }
        scheduleCheck()
    }

    func callbackInMainThread(_ error: AppError? = nil) {
        finishedLock.lock()
        let alreadyFinished = finished
        finished = true
        finishedLock.unlock()
        if alreadyFinished {
            return
        }
        DispatchQueue.main.async {
            self.callback(error)
        }
    }
}
