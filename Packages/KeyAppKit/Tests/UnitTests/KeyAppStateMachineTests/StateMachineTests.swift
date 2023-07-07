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

    func testAcceptAnAction() async throws {
        // accept an action
        await stateMachine.accept(action: .submitApplication(applicantName: "Ivan"))
        await stateMachine.accept(action: .submitApplication(applicantName: "Ivan2"))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
