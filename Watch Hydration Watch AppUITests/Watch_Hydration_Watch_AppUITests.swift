//
//  Watch_Hydration_Watch_AppUITests.swift
//  Watch Hydration Watch AppUITests
//
//  Created by Thomas Chatting on 03/05/2025.
//

import XCTest

final class Watch_Hydration_Watch_AppUITests: XCTestCase {
    
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testInitialState() throws {
        app.launch()

        let drinkButton = app.buttons["DrinkButton"]
        XCTAssertTrue(drinkButton.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["+"].exists)
        XCTAssertTrue(app.buttons["-"].exists)
        XCTAssertEqual(app.textFields.count, 1)
        XCTAssertTrue(app.textFields.element(boundBy: 0).exists)
    }

    func testIncrementDecrementButtons() throws {
        app.launch()

        let increment = app.buttons["IncrementButton"]
        let decrement = app.buttons["DecrementButton"]

        XCTAssertTrue(increment.exists)
        XCTAssertTrue(decrement.exists)

        increment.tap()
        increment.tap()
        decrement.tap()

        let drinkButton = app.buttons["DrinkButton"]
        XCTAssertTrue(drinkButton.waitForExistence(timeout: 10))
        
        XCTAssertTrue(drinkButton.isEnabled)
    }

    func testChooseLiquid() throws {
        app.launch()

        let cupTapArea = app.otherElements["CupTapArea"]
        XCTAssertTrue(cupTapArea.waitForExistence(timeout: 10))
        cupTapArea.tap()
        
        // Select "Coffee"
        let coffeeButton = app.buttons["Liquid_Coffee"]
        XCTAssertTrue(coffeeButton.waitForExistence(timeout: 10))
        coffeeButton.tap()

        // Drink button should now say "Drink Coffee"
        let drinkButton = app.buttons["DrinkButton"]
        XCTAssertTrue(drinkButton.label == "Drink Coffee")
    }

    func testDrinkButtonDisabledWhenAmountZero() throws {
        app.launch()

        let drinkButton = app.buttons["DrinkButton"]
        XCTAssertTrue(drinkButton.waitForExistence(timeout: 10))
        XCTAssertFalse(drinkButton.isEnabled)

        app.buttons["IncrementButton"].tap()
        XCTAssertTrue(drinkButton.isEnabled)

        app.buttons["DecrementButton"].tap()
        XCTAssertFalse(drinkButton.isEnabled)
    }
}
