import XCTest
import KeyAppStateMachine

final class StateMachineTests: XCTestCase {
    
    var stateMachine: StateMachine<RecruitmentState, RecruitmentAction, RecruitmentDispatcher>!
    var dispatcher: RecruitmentDispatcher!

    override func setUpWithError() throws {
        dispatcher = .init()
        stateMachine = .init(dispatcher: dispatcher, verbose: true)
    }

    override func tearDownWithError() throws {
        stateMachine = nil
        dispatcher = nil
    }

    func testAcceptAnAction_ShouldReturnExpectedState() async throws {
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        
        // listen
        let stream = stateMachine.statePublisher
            .prefix(4) // initialState + actionWillBeginDispatchingState + dispatchState + actionDidEndDispatchingState
            .asyncStream()
        
        // Print timer ticks to the console.
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
        
        // Print when the for loop completes
        print("Completed.")
    }
    
    func testAcceptAnAction() async throws {
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The First"))
        await stateMachine.accept(action: .submitApplication(applicantName: "Napoleon The Second"))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
