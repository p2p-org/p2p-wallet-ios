import XCTest
import KeyAppStateMachine

class StateTests: XCTestCase {
    
    func testModifiedState() {
        // Create an initial state
        let initialState = RecruitmentState.initial
        
        // Modify the state using the `modified` method
        let modifiedState = initialState.modified { state in
            state.applicantName = "John Doe"
            state.isApplicationSubmitted = true
            state.isApplicationReviewed = true
            state.isInterviewScheduled = true
        }
        
        // Verify the modified state
        XCTAssertEqual(modifiedState.applicantName, "John Doe")
        XCTAssertTrue(modifiedState.isApplicationSubmitted)
        XCTAssertTrue(modifiedState.isApplicationReviewed)
        XCTAssertTrue(modifiedState.isInterviewScheduled)
        
        // Verify the initial state remains unchanged
        XCTAssertEqual(initialState.applicantName, "")
        XCTAssertFalse(initialState.isApplicationSubmitted)
        XCTAssertFalse(initialState.isApplicationReviewed)
        XCTAssertFalse(initialState.isInterviewScheduled)
    }
    
    func testModifiedStateMultipleTimes() {
        // Create an initial state
        let initialState = RecruitmentState.initial
        
        // Modify the state multiple times using the `modified` method
        let modifiedState = initialState.modified { state in
            state.isApplicationSubmitted = true
            state.isApplicationReviewed = true
        }.modified { state in
            state.isInterviewScheduled = true
        }.modified { state in
            state.applicantName = "Alice Johnson"
        }
        
        // Verify the modified state
        XCTAssertEqual(modifiedState.applicantName, "Alice Johnson")
        XCTAssertTrue(modifiedState.isApplicationSubmitted)
        XCTAssertTrue(modifiedState.isApplicationReviewed)
        XCTAssertTrue(modifiedState.isInterviewScheduled)
        
        // Verify the initial state remains unchanged
        XCTAssertEqual(initialState.applicantName, "")
        XCTAssertFalse(initialState.isApplicationSubmitted)
        XCTAssertFalse(initialState.isApplicationReviewed)
        XCTAssertFalse(initialState.isInterviewScheduled)
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
