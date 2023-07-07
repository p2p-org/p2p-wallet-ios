import XCTest
import KeyAppStateMachine

class StateTests: XCTestCase {
    
    func testModifiedState() {
        // Create an initial state
        let initialState = RecruitmentState.initial
        
        // Modify the state using the `modified` method
        let modifiedState = initialState.modified { state in
            state.applicantName = "John Doe"
        }
        
        // Verify the modified state
        XCTAssertEqual(modifiedState.applicantName, "John Doe")
        
        // Verify the initial state remains unchanged
        XCTAssertEqual(initialState.applicantName, "")
    }
    
    func testModifiedStateMultipleTimes() {
        // Create an initial state
        let initialState = RecruitmentState.initial
        
        // Modify the state multiple times using the `modified` method
        let modifiedState = initialState.modified { state in
            state.applicantName = "Long"
        }.modified { state in
            state.applicantName = "Sth"
        }.modified { state in
            state.applicantName = "Alice Johnson"
        }
        
        // Verify the modified state
        XCTAssertEqual(modifiedState.applicantName, "Alice Johnson")
        
        // Verify the initial state remains unchanged
        XCTAssertEqual(initialState.applicantName, "")
    }
    
    func testModifiedStateNoChanges() {
        // Create an initial state
        let initialState = RecruitmentState.initial
        
        // Modify the state using the `modified` method without making any changes
        let modifiedState = initialState.modified { _ in
            // No changes made
        }
        
        // Verify the modified state is the same as the initial state
        XCTAssertEqual(modifiedState, initialState)
    }
}
