/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
@testable import Datadog

class URLSessionInterceptorMock: URLSessionInterceptorType {
    var modifiedRequest: URLRequest?

    var onRequestModified: ((URLRequest, URLSession?) -> Void)?
    var onTaskCreated: ((URLSessionTask, URLSession?) -> Void)?
    var onTaskCompleted: ((URLSessionTask, Error?) -> Void)?
    var onTaskMetricsCollected: ((URLSessionTask, URLSessionTaskMetrics) -> Void)?

    var tasksCreated: [URLSessionTask] = []
    var tasksCompleted: [(task: URLSessionTask, error: Error?)] = []
    var taskMetrics: [(task: URLSessionTask, metrics: URLSessionTaskMetrics)] = []

    func modify(request: URLRequest, session: URLSession?) -> URLRequest {
        onRequestModified?(request, session)
        return modifiedRequest ?? request
    }

    func taskCreated(task: URLSessionTask, session: URLSession?) {
        tasksCreated.append(task)
        onTaskCreated?(task, session)
    }

    func taskCompleted(task: URLSessionTask, error: Error?) {
        tasksCompleted.append((task: task, error: error))
        onTaskCompleted?(task, error)
    }

    func taskMetricsCollected(task: URLSessionTask, metrics: URLSessionTaskMetrics) {
        taskMetrics.append((task: task, metrics: metrics))
        onTaskMetricsCollected?(task, metrics)
    }
}

extension ResourceCompletion {
    static func mockAny() -> Self {
        return mockWith()
    }

    static func mockWith(
        response: URLResponse? = .mockAny(),
        error: Error? = nil
    ) -> Self {
        return ResourceCompletion(response: response, error: error)
    }
}

extension ResourceMetrics {
    static func mockAny() -> Self {
        return mockWith()
    }

    static func mockWith(
        fetch: DateInterval = .init(start: Date(), end: Date(timeIntervalSinceNow: 1)),
        redirection: DateInterval? = nil,
        dns: DateInterval? = nil,
        connect: DateInterval? = nil,
        ssl: DateInterval? = nil,
        firstByte: DateInterval? = nil,
        download: DateInterval? = nil,
        responseSize: Int64? = nil
    ) -> Self {
        return .init(
            fetch: fetch,
            redirection: redirection,
            dns: dns,
            connect: connect,
            ssl: ssl,
            firstByte: firstByte,
            download: download,
            responseSize: responseSize
        )
    }
}
