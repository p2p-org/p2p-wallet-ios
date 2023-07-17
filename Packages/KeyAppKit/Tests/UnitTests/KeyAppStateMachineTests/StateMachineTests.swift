import XCTest
import KeyAppStateMachine
import Combine

private let fakeNetworkDelayInMilliseconds: Int = 300

final class StateMachineTests: XCTestCase {
    
    var apiClient: APIClient = MockAPIClient(delayInMilliseconds: UInt64(fakeNetworkDelayInMilliseconds))
    var dispatcher: RecruitmentDispatcher!
    var stateMachine: StateMachine<RecruitmentState, RecruitmentAction, RecruitmentDispatcher>!

    override func setUpWithError() throws {
        dispatcher = .init(apiClient: apiClient)
        stateMachine = .init(dispatcher: dispatcher, verbose: true)
    }

    override func tearDownWithError() throws {
        stateMachine = nil
        dispatcher = nil
    }

    func testAcceptAnAction_ShouldReturnExpectedState() async throws {
        // accept an action
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        }
        
        let states = try await collectResult(finishWhenReceiving: .init(
            applicantName: "Napoleon The First",
            sendingStatus: .completed
        ))
        
        XCTAssertEqual(states.count, 3)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .completed
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
        
        let states = try await collectResult(finishWhenReceiving: .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
        
        XCTAssertEqual(states.count, 5)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .completed
        ))
        XCTAssertEqual(states[3], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[4], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
    }
    
    func testAcceptNewAction_WaitForPreviousActionToComplete_ShouldReturnBothStates() async throws {
        // accept an action
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
        }
        
        let states = try await collectResult(finishWhenReceiving: .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
        
        XCTAssertEqual(states.count, 5)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .completed
        ))
        XCTAssertEqual(states[3], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[4], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
    }
    
    func testAccept3Actions_WaitForEachPreviousActionToComplete_ShouldReturnAllStates() async throws {
        // accept actions
        Task.detached {
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Third"))
        }
        
        let states = try await collectResult(finishWhenReceiving: .init(
            applicantName: "Napoleon The Third",
            sendingStatus: .completed
        ))
        
        XCTAssertEqual(states.count, 7)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .completed
        ))
        XCTAssertEqual(states[3], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[4], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
        XCTAssertEqual(states[5], .init(
            applicantName: "Napoleon The Third",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[6], .init(
            applicantName: "Napoleon The Third",
            sendingStatus: .completed
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
        
        
        let states = try await collectResult(finishWhenReceiving: .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
        
        XCTAssertEqual(states.count, 4)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[3], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
    }

    func testAcceptNewActions_CancelingPreviousActionOrWaiting_ShouldPerformActionsCorrectly() async throws {
        
        // Accept an action and then immediately accept multiple new actions
        Task.detached {
            // first action
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
            
            // second action, should cancel first action
            self.dispatcher.newActionShouldCancelPreviousAction = true
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
            
            // third action, should not cancel second action
            self.dispatcher.newActionShouldCancelPreviousAction = false
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Third"))
            
            // forth action, should cancel third action
            self.dispatcher.newActionShouldCancelPreviousAction = true
            await self.stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Fourth"))
        }
        
        let states = try await collectResult(finishWhenReceiving: .init(
            applicantName: "Napoleon The Fourth",
            sendingStatus: .completed
        ))
        
        // Verify the states are as expected
        XCTAssertEqual(states.count, 7)
        XCTAssertEqual(states[0], .initial)
        XCTAssertEqual(states[1], .init(
            applicantName: "Napoleon The First",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[2], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[3], .init(
            applicantName: "Napoleon The Second",
            sendingStatus: .completed
        ))
        XCTAssertEqual(states[4], .init(
            applicantName: "Napoleon The Third",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[5], .init(
            applicantName: "Napoleon The Fourth",
            sendingStatus: .sending
        ))
        XCTAssertEqual(states[6], .init(
            applicantName: "Napoleon The Fourth",
            sendingStatus: .completed
        ))
    }

    
    // MARK: - Helpers

    private func collectResult(finishWhenReceiving state: RecruitmentState) async throws -> [RecruitmentState] {
        // prepare stream
        let stream = stateMachine.statePublisher
            .prefix(while: { $0 != state })
            .append(state)
            .timeout(.seconds(5), scheduler: DispatchQueue.main, options: nil, customError: nil)
            .asyncStream()

        
        // listen
        var states = [RecruitmentState]()
        for try await state in stream {
            states.append(state)
        }
        
        return states
    }
}
