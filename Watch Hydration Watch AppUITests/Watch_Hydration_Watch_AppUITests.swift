//
//  Watch_Hydration_Watch_AppUITests.swift
//  Watch Hydration Watch AppUITests
//
//  Created by Thomas Chatting on 03/05/2025.
//

import XCTest

final class Watch_Hydration_Watch_AppUITests: XCTestCase {

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
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testInitialState() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Drink Water"].exists)
        XCTAssertTrue(app.buttons["+"].exists)
        XCTAssertTrue(app.buttons["-"].exists)
        XCTAssertEqual(app.textFields.count, 1)
        XCTAssertTrue(app.textFields.element(boundBy: 0).exists)
    }

    func testIncrementDecrementButtons() throws {
        let app = XCUIApplication()
        app.launch()

        let increment = app.buttons["+"]
        let decrement = app.buttons["-"]

        XCTAssertTrue(increment.exists)
        XCTAssertTrue(decrement.exists)

        increment.tap()
        increment.tap()
        decrement.tap()

        let drinkButton = app.buttons["Drink Water"]
        XCTAssertTrue(drinkButton.exists)
        XCTAssertTrue(drinkButton.isEnabled)
    }

    func testChooseLiquid() throws {
        let app = XCUIApplication()
        app.launch()

        let cupTapArea = app.otherElements["CupTapArea"]
        XCTAssertTrue(cupTapArea.waitForExistence(timeout: 1))
        cupTapArea.tap()
        
        // Select "Coffee"
        let coffeeButton = app.buttons["Liquid_Coffee"]
        XCTAssertTrue(coffeeButton.waitForExistence(timeout: 2))
        coffeeButton.tap()

        // Drink button should now say "Drink Coffee"
        let drinkButton = app.buttons["Drink Coffee"]
        XCTAssertTrue(drinkButton.exists)
    }

    func testDrinkButtonDisabledWhenAmountZero() throws {
        let app = XCUIApplication()
        app.launch()

        let drinkButton = app.buttons["Drink Water"]
        XCTAssertFalse(drinkButton.isEnabled)

        app.buttons["+"].tap()
        XCTAssertTrue(drinkButton.isEnabled)

        app.buttons["-"].tap()
        XCTAssertFalse(drinkButton.isEnabled)
    }
}
