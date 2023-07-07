import XCTest
import KeyAppStateMachine
import Combine

private let fakeNetworkDelayInMilliseconds: Int = 300

final class StateMachineTests: XCTestCase {
    
    var stateMachine: StateMachine<RecruitmentState, RecruitmentAction, RecruitmentDispatcher>!
    var dispatcher: RecruitmentDispatcher = .init(
        delayInMilliseconds: UInt64(fakeNetworkDelayInMilliseconds)
    )

    override func setUpWithError() throws {
        stateMachine = .init(dispatcher: dispatcher, verbose: true)
    }

    override func tearDownWithError() throws {
        stateMachine = nil
    }

    func testAcceptAnAction_ShouldReturnExpectedState() async throws {
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        
        // listen
        let stream = stateMachine.statePublisher
            .completeIfNoEventEmitedWithinSchedulerTime(
                .milliseconds(2 * fakeNetworkDelayInMilliseconds + 50)
            )
        
        // get last state
        var lastState: RecruitmentState!
        for try await state in stream {
            lastState = state
        }
        
        XCTAssertEqual(lastState, .init(
            applicantName: "Napoleon The First",
            isApplicationSubmitted: true,
            isApplicationReviewed: false,
            isInterviewScheduled: false
        ))
    }
    
    func testAcceptAnAction_WaitForItToFinish_AcceptSecondAction_ShouldReturnFirstStateThenSecondState() async throws {
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        
        // listen
        let stream = stateMachine.statePublisher
            .completeIfNoEventEmitedWithinSchedulerTime(
                .milliseconds(2 * fakeNetworkDelayInMilliseconds + 50)
            )
        
        // get last state
        var lastState: RecruitmentState!
        for try await state in stream {
            lastState = state
        }
        
        XCTAssertEqual(lastState, .init(
            applicantName: "Napoleon The First",
            isApplicationSubmitted: true,
            isApplicationReviewed: false,
            isInterviewScheduled: false
        ))
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
        
        // listen
        let stream2 = stateMachine.statePublisher
            .completeIfNoEventEmitedWithinSchedulerTime(
                .milliseconds(2 * fakeNetworkDelayInMilliseconds + 50)
            )
        
        // get last state
        for try await state in stream2 {
            lastState = state
        }
        
        XCTAssertEqual(lastState, .init(
            applicantName: "Napoleon The Second",
            isApplicationSubmitted: true,
            isApplicationReviewed: false,
            isInterviewScheduled: false
        ))
    }
    
    func testAcceptNewAction_WaitForPreviousActionToComplete_ShouldReturnBothStates() async throws {
        
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
        
        // listen
        let stream = stateMachine.statePublisher
            .completeIfNoEventEmitedWithinSchedulerTime(
                .milliseconds(2 * fakeNetworkDelayInMilliseconds + 50)
            )
        
        // get last state
        var lastState: RecruitmentState!
        for try await state in stream {
            lastState = state
        }
        
        XCTAssertEqual(lastState, .init(
            applicantName: "Napoleon The Second",
            isApplicationSubmitted: true,
            isApplicationReviewed: false,
            isInterviewScheduled: false
        ))
    }
    
    func testAcceptNewAction_CancelingPreviousActionImmediately_ShouldReturnSecondState() async throws {
        // modify dispatcher
        dispatcher.newActionShouldCancelPreviousAction = true
        
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
        
        // listen
        let stream = stateMachine.statePublisher
            .completeIfNoEventEmitedWithinSchedulerTime(
                .milliseconds(2 * fakeNetworkDelayInMilliseconds + 50)
            )
        
        // get last state
        var lastState: RecruitmentState!
        for try await state in stream {
            lastState = state
        }
        
        XCTAssertEqual(lastState, .init(
            applicantName: "Napoleon The Second",
            isApplicationSubmitted: true,
            isApplicationReviewed: false,
            isInterviewScheduled: false
        ))
    }
}

// MARK: - Helpers

private extension Publisher {
    func completeIfNoEventEmitedWithinSchedulerTime(
        _ time: DispatchQueue.SchedulerTimeType.Stride
    ) -> CombineAsyncStream<Publishers.Timeout<Self, DispatchQueue>> {
        let timeOutPublisher = timeout(time, scheduler: DispatchQueue.main, options: nil, customError: nil)
        return CombineAsyncStream(timeOutPublisher)
    }
}
