// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
import Combine

private struct User: Decodable {}

func usage() async throws {
    let client = APIClient(baseURL: nil)

    let dataTask = await client.dataTask(with: Request<User>(path: "/user"))

    if #available(iOS 15, *) {
        for await progress in dataTask.progress.values {
            print(progress)
        }
    }

    let response = try await dataTask.response.value
    let data = try await dataTask.data
    let string = try await dataTask.string
}

public final class AsyncDataTask<T>: @unchecked Sendable {
    private let task: Task<Response<Data>, Error>

    init(task: Task<Response<Data>, Error>) {
        self.task = task
    }

    public var delegate: URLSessionDataDelegate?

    // TODO: Add a struct to represent progress
    public var progress: some Publisher<Float, Never> { _progress }
    var _progress = CurrentValueSubject<Float, Never>(0.0)

    public var data: Data {
        get async throws {
            fatalError()
        }
    }

    public var string: String {
        get async throws {
            fatalError()
        }
    }

    public var configure: (@Sendable (inout URLRequest) -> Void)?
}

// Pros: this approach will allow users to extend the task with custom decoders

extension AsyncDataTask where T: Decodable {
    public var response: Response<T> {
        get async throws {
            fatalError()
        }
    }
}

extension AsyncDataTask where T == Void {
    public var response: Response<T> {
        get async throws {
            fatalError()
        }
    }
}
