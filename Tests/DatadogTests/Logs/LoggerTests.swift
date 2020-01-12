import XCTest
@testable import Datadog

// swiftlint:disable multiline_arguments_brackets
class LoggerTests: XCTestCase {
    /// Provides consecutive dates for send with `Logger`.
    private var logDatesProvider: DateProvider {
        let provider = DateProviderMock()
        provider.currentDates = [
            .mockDecember15th2019At10AMUTC(addingTimeInterval: -5),
            .mockDecember15th2019At10AMUTC(addingTimeInterval: -4),
            .mockDecember15th2019At10AMUTC(addingTimeInterval: -3),
            .mockDecember15th2019At10AMUTC(addingTimeInterval: -2),
            .mockDecember15th2019At10AMUTC(addingTimeInterval: -1),
            .mockDecember15th2019At10AMUTC(addingTimeInterval: 0),
        ]
        return provider
    }

    override func setUp() {
        super.setUp()
        XCTAssertNil(Datadog.instance)
        temporaryDirectory.create()
    }

    override func tearDown() {
        XCTAssertNil(Datadog.instance)
        temporaryDirectory.delete()
        super.tearDown()
    }

    func testSendingLogsWithDefaultLogger() throws {
        let requestsRecorder = try setUpDatadogAndRecordSendingOneLogPerRequest(expectedRequestsCount: 6) {
            let logger = Logger.builder.build()

            logger.debug("message")
            logger.info("message")
            logger.notice("message")
            logger.warn("message")
            logger.error("message")
            logger.critical("message")
        }

        let requestsData = requestsRecorder.requestsSent.compactMap { $0.httpBody }
        assertThat(serializedLogData: requestsData[0], fullyMatches: """
        [{
          "status" : "DEBUG",
          "message" : "message",
          "service" : "ios",
          "date" : "2019-12-15T09:59:55Z"
        }]
        """)
        assertThat(serializedLogData: requestsData[1], fullyMatches: """
        [{
          "status" : "INFO",
          "message" : "message",
          "service" : "ios",
          "date" : "2019-12-15T09:59:56Z"
        }]
        """)
        assertThat(serializedLogData: requestsData[2], fullyMatches: """
        [{
          "status" : "NOTICE",
          "message" : "message",
          "service" : "ios",
          "date" : "2019-12-15T09:59:57Z"
        }]
        """)
        assertThat(serializedLogData: requestsData[3], fullyMatches: """
        [{
          "status" : "WARN",
          "message" : "message",
          "service" : "ios",
          "date" : "2019-12-15T09:59:58Z"
        }]
        """)
        assertThat(serializedLogData: requestsData[4], fullyMatches: """
        [{
          "status" : "ERROR",
          "message" : "message",
          "service" : "ios",
          "date" : "2019-12-15T09:59:59Z"
        }]
        """)
        assertThat(serializedLogData: requestsData[5], fullyMatches: """
        [{
          "status" : "CRITICAL",
          "message" : "message",
          "service" : "ios",
          "date" : "2019-12-15T10:00:00Z"
        }]
        """)
    }

    func testSendingLogsWithCustomizedLogger() throws {
        let requestsRecorder = try setUpDatadogAndRecordSendingOneLogPerRequest(expectedRequestsCount: 6) {
            let logger = Logger.builder
                .set(serviceName: "custom-service-name")
                .build()

            logger.debug("message")
            logger.info("message")
            logger.notice("message")
            logger.warn("message")
            logger.error("message")
            logger.critical("message")
        }

        let requestsData = requestsRecorder.requestsSent.compactMap { $0.httpBody }
        requestsData.forEach { requestData in
            assertThat(
                serializedLogData: requestData,
                matchesValue: ["custom-service-name"],
                onKeyPath: "@unionOfObjects.service"
            )
        }
    }

    func testWhenDatadogIsNotInitialized_itThrowsProgrammerError() {
        XCTAssertThrowsError(try Logger.builder.buildOrThrow()) { error in
            XCTAssertEqual(
                (error as? ProgrammerError)?.description,
                "Datadog SDK usage error: `Datadog.initialize()` must be called prior to `Logger.builder.build()`."
            )
        }
    }
}

// MARK: - Helpers for ensuring `Logger` run environment

private extension LoggerTests {
    /// Ensures that `Logger` is accessed within configured `Datadog` environment.
    private func setUpDatadogAndRecordSendingOneLogPerRequest(
        expectedRequestsCount: Int,
        run test: () -> Void
    ) throws -> RequestsRecorder {
        let requestsRecorder = RequestsRecorder()
        let expectation = self.expectation(description: "Send \(expectedRequestsCount) requests")
        expectation.expectedFulfillmentCount = expectedRequestsCount

        // Set up `DateProvider` for creating log files in the past
        let fileCreationDateProvider = DateProviderMock()
        fileCreationDateProvider.currentFileCreationDates = (0..<expectedRequestsCount)
            .map { Date().secondsAgo(Double($0) * 10) } // create file every 10 seconds in the past ...
            .reversed() // ... starting from oldest time

        let logsUploadInterval: TimeInterval = 0.05 // pretty quick 😎

        // Configure `Datadog` instance
        Datadog.instance = .mockSuccessfullySendingOneLogPerRequest(
            logsDirectory: temporaryDirectory,
            logsFileCreationDateProvider: fileCreationDateProvider,
            logsUploadInterval: logsUploadInterval,
            logsTimeProvider: logDatesProvider,
            requestsRecorder: requestsRecorder
        )

        // Fulfill expectation on every request sent
        requestsRecorder.onNewRequest = { _ in expectation.fulfill() }

        // Execute test
        test()

        // Wait for all requests being sent
        let arbitraryEnoughOfTime = logsUploadInterval * Double(expectedRequestsCount) * 3
        waitForExpectations(timeout: arbitraryEnoughOfTime, handler: nil)

        try Datadog.deinitializeOrThrow()

        return requestsRecorder
    }
}
