import XCTest
import KeyAppStateMachine

class StateTests: XCTestCase {
    
    func testModified_WhenUpdatingNameAndAge_ShouldReturnNewStateWithUpdatedProperties() {
        // Arrange
        let initialState = UserState(name: "John", age: 30)
        
        // Act
        let newState = initialState.modified { state in
            state.name = "Jane"
            state.age = 35
        }
        
        // Assert
        XCTAssertEqual(newState.name, "Jane")
        XCTAssertEqual(newState.age, 35)
        XCTAssertTrue(newState.isAdult)
        XCTAssertEqual(newState.greeting, "Hello, my name is Jane and I'm 35 years old.")
        XCTAssertNotEqual(initialState, newState)
    }
    
    func testModified_WhenIncrementingAge_ShouldReturnNewStateWithUpdatedProperties() {
        // Arrange
        let initialState = UserState(name: "John", age: 17)
        
        // Act
        let newState = initialState.modified { state in
            state.age += 1
        }
        
        // Assert
        XCTAssertEqual(newState.name, "John")
        XCTAssertEqual(newState.age, 18)
        XCTAssertTrue(newState.isAdult)
        XCTAssertEqual(newState.greeting, "Hello, my name is John and I'm 18 years old.")
        XCTAssertNotEqual(initialState, newState)
    }
    
    func testModified_WhenUpdatingName_ShouldReturnNewStateWithUpdatedProperties() {
        // Arrange
        let initialState = UserState(name: "John", age: 30)
        
        // Act
        let newState = initialState.modified { state in
            state.name = "Jane"
        }
        
        // Assert
        XCTAssertEqual(newState.name, "Jane")
        XCTAssertEqual(newState.age, 30)
        XCTAssertTrue(newState.isAdult)
        XCTAssertEqual(newState.greeting, "Hello, my name is Jane and I'm 30 years old.")
        XCTAssertNotEqual(initialState, newState)
    }
    
}
