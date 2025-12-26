//
//  Stay_TunedTests.swift
//  Stay TunedTests
//
//  Main test file for Stay Tuned app.
//  See individual test files for specific test categories:
//  - ChromaticNoteTests.swift: Chromatic note detection
//  - TuningTests.swift: Tuning and GuitarString models
//  - AudioTests.swift: Pitch detection and spectrum analyzer
//  - TunerViewModelTests.swift: ViewModel business logic
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Testing
@testable import Stay_Tuned

struct Stay_TunedTests {

    @Test("App module can be imported")
    func testModuleImport() {
        // This test ensures the module is properly configured for testing
        #expect(true)
    }
}
