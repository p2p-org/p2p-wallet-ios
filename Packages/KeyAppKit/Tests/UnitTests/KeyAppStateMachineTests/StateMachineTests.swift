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
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        }
        
        let states = try await collectResult()
        
        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states.first, .initial)
        XCTAssertEqual(states.last, .init(
            applicantName: "Napoleon The First"
        ))
    }
    
    func testAcceptAnAction_WaitForItToFinish_AcceptSecondAction_ShouldReturnFirstStateThenSecondState() async throws {
        // accept an action
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
            // wait for first action to complete
            try await Task.sleep(nanoseconds: UInt64(3 * fakeNetworkDelayInMilliseconds * 1_000_000))
            
            // accept an action
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
        }
        
        let states = try await collectResult()
        
        XCTAssertEqual(states.count, 3)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First"
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The Second"
        ))
    }
    
    func testAcceptNewAction_WaitForPreviousActionToComplete_ShouldReturnBothStates() async throws {
        // accept an action
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
        }
        
        let states = try await collectResult()
        
        XCTAssertEqual(states.count, 3)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First"
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The Second"
        ))
    }
    
    func testAccept3Actions_WaitForEachPreviousActionToComplete_ShouldReturnAllStates() async throws {
        // accept actions
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Third"))
        }
        
        let states = try await collectResult()
        
        XCTAssertEqual(states.count, 4)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First"
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The Second"
        ))
        XCTAssertEqual(states[3], .init(
            applicantName: "Napoleon The Third"
        ))
    }
    
    func testAcceptNewAction_CancelingPreviousActionImmediately_ShouldReturnSecondState() async throws {
        // modify dispatcher
        dispatcher.newActionShouldCancelPreviousAction = true
        
        // accept an action
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
        }
        
        
        let states = try await collectResult()
        
        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The Second"
        ))
    }
    
    // MARK: - Helpers

    private func collectResult(delayFactor: Int = 3) async throws -> [RecruitmentState] {
        // prepare stream
        let stream = stateMachine.statePublisher
            .completeIfNoEventEmitedWithinSchedulerTime(
                .milliseconds(delayFactor * fakeNetworkDelayInMilliseconds + 50)
            )
        
        // listen
        var states = [RecruitmentState]()
        for try await state in stream {
            states.append(state)
        }
        
        return states
    }
}

// MARK: - Private extensions

private extension Publisher {
    func completeIfNoEventEmitedWithinSchedulerTime(
        _ time: DispatchQueue.SchedulerTimeType.Stride
    ) -> CombineAsyncStream<Publishers.Timeout<Self, DispatchQueue>> {
        let timeOutPublisher = timeout(time, scheduler: DispatchQueue.main, options: nil, customError: nil)
        return CombineAsyncStream(timeOutPublisher)
    }
}
