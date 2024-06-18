import Vapor
import Logging
import NIOCore
import NIOPosix

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)

        // This attempts to install NIO as the Swift Concurrency global executor.
        // You should not call any async functions before this point.
        let executorTakeoverSuccess = NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        app.logger.debug("Running with \(executorTakeoverSuccess ? "SwiftNIO" : "standard") Swift Concurrency default executor")
        
        do {
            try await configure(app)
            
            /*let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                    performPing()
                }
            // Make sure the timer fires even when the run loop is busy
            RunLoop.current.add(timer, forMode: .common)

            // This line ensures that the timer is running even when the application is idle
            timer.tolerance = 1.0

            // Start the run loop
            RunLoop.current.run()*/
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.execute()
        try await app.asyncShutdown()
        
    }
}
