// The MIT License (MIT)
//
// Copyright (c) 2021-2022 Alexander Grebenyuk (github.com/kean).

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol APIInterface {
    func send<T: Decodable>(
        _ request: Request<T>,
        delegate: URLSessionDataDelegate?,
        configure: ((inout URLRequest) throws -> Void)?
    ) async throws -> Response<T>
    
    func send(
        _ request: Request<Void>,
        delegate: URLSessionDataDelegate?,
        configure: ((inout URLRequest) throws -> Void)?
    ) async throws -> Response<Void>
    
    func data<T>(
        for request: Request<T>,
        delegate: URLSessionDataDelegate?,
        configure: ((inout URLRequest) throws -> Void)?
    ) async throws -> Response<Data>
    
#if !os(Linux)
    func download<T>(
       for request: Request<T>,
       delegate: URLSessionDownloadDelegate?,
       configure: ((inout URLRequest) throws -> Void)?
   ) async throws -> Response<URL>
    
    func download(
        resumeFrom resumeData: Data,
        delegate: URLSessionDownloadDelegate?
    ) async throws -> Response<URL>
#endif
}
