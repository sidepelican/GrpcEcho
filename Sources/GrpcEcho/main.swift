import Logging
import GRPC
import NIO
import NIOHPACK

class LoggingInterceptor<Request, Response>: ServerInterceptor<Request, Response> {
    override func receive(
        _ part: GRPCServerRequestPart<Request>,
        context: ServerInterceptorContext<Request, Response>
    ) {
        switch part {
        case .metadata:
            context.logger.info("Called", metadata: ["path": "\(context.path)"])
        case .message:
            break
        case .end:
            break
        }
        context.receive(part)
    }
}

class EchoProvider: Echo_EchoAsyncProvider {
    struct Interceptors: Echo_EchoServerInterceptorFactoryProtocol {
        func makeGreetingInterceptors() -> [ServerInterceptor<Echo_GreetingRequest, Echo_GreetingResponse>] {
            [LoggingInterceptor()]
        }
        func makeHelloInterceptors() -> [ServerInterceptor<Echo_HelloRequest, Echo_HelloResponse>] {
            [LoggingInterceptor()]
        }
    }
    let interceptors: Echo_EchoServerInterceptorFactoryProtocol? = Interceptors()

    func greeting(request: Echo_GreetingRequest, context: GRPCAsyncServerCallContext) async throws -> Echo_GreetingResponse {
        .with {
            $0.message = "Hello World"
        }
    }

    func hello(request: Echo_HelloRequest, context: GRPCAsyncServerCallContext) async throws -> Echo_HelloResponse {
        return Echo_HelloResponse.with {
            $0.message = "Hello, \(request.name)"
        }
    }
}

class ErrorDelegate: ServerErrorDelegate {
    func observeLibraryError(_ error: Error) {
        print("\(error)")
    }
    func observeRequestHandlerError(_ error: Error, headers: HPACKHeaders) {
        print("\(error)")
    }
}

LoggingSystem.bootstrap { label in
    StreamLogHandler.standardOutput(label: label)
}

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try! group.syncShutdownGracefully()
}

let server = try Server.insecure(group: group)
    .withServiceProviders([
        EchoProvider(),
    ])
    .withLogger(Logger(label: "io.grpc"))
    .withErrorDelegate(ErrorDelegate())
    .bind(host: "localhost", port: 8080)
    .wait()

print("started server: \(server.channel.localAddress!)")

try server.onClose.wait()
