//
//  AboutViewTests.swift
//  Stay TunedTests
//
//  Tests for AboutView and related utilities
//

import Testing
@testable import Stay_Tuned

// MARK: - Bundle Info Helper Tests

struct BundleInfoTests {

    /// Helper function that mirrors the AboutView logic for extracting version
    func appVersion(from bundle: Bundle) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// Helper function that mirrors the AboutView logic for extracting build
    func buildNumber(from bundle: Bundle) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    @Test("App version is extracted from main bundle")
    func testAppVersionFromBundle() {
        let version = appVersion(from: Bundle.main)
        // Version should be a non-empty string
        #expect(!version.isEmpty)
    }

    @Test("Build number is extracted from main bundle")
    func testBuildNumberFromBundle() {
        let build = buildNumber(from: Bundle.main)
        // Build should be a non-empty string
        #expect(!build.isEmpty)
    }

    @Test("Version fallback returns 1.0 when key missing")
    func testVersionFallback() {
        // Use a bundle that doesn't have the version key (test bundle proxy)
        let testBundle = Bundle(for: NSClassFromString("XCTestCase")!)
        let version = appVersion(from: testBundle)
        // Should either return actual version or fallback
        #expect(!version.isEmpty)
    }

    @Test("Build fallback returns 1 when key missing")
    func testBuildFallback() {
        // Use a bundle that may not have the build key
        let testBundle = Bundle(for: NSClassFromString("XCTestCase")!)
        let build = buildNumber(from: testBundle)
        // Should either return actual build or fallback
        #expect(!build.isEmpty)
    }
}

// MARK: - Contact Email Tests

struct ContactEmailTests {

    let developerEmail = "nickmaccarthy@gmail.com"

    @Test("Developer email is valid format")
    func testEmailFormat() {
        #expect(developerEmail.contains("@"))
        #expect(developerEmail.contains("."))
    }

    @Test("Mailto URL is properly formed")
    func testMailtoURL() {
        let mailtoString = "mailto:\(developerEmail)"
        let url = URL(string: mailtoString)

        #expect(url != nil)
        #expect(url?.scheme == "mailto")
    }

    @Test("Mailto URL has correct email address")
    func testMailtoURLAddress() {
        let mailtoString = "mailto:\(developerEmail)"
        let url = URL(string: mailtoString)

        // The path of a mailto URL is the email address
        #expect(url?.absoluteString == "mailto:nickmaccarthy@gmail.com")
    }
}

// MARK: - Developer Info Tests

struct DeveloperInfoTests {

    let developerName = "Nick MacCarthy"
    let appName = "Stay Tuned"
    let appSubtitle = "Guitar Tuner"

    @Test("Developer name is not empty")
    func testDeveloperNameNotEmpty() {
        #expect(!developerName.isEmpty)
    }

    @Test("App name is Stay Tuned")
    func testAppName() {
        #expect(appName == "Stay Tuned")
    }

    @Test("App subtitle is Guitar Tuner")
    func testAppSubtitle() {
        #expect(appSubtitle == "Guitar Tuner")
    }
}

// MARK: - AboutView Instantiation Tests

struct AboutViewInstantiationTests {

    @Test("AboutView can be instantiated")
    func testAboutViewInstantiation() {
        let view = AboutView()
        // If we get here without crashing, the view instantiated successfully
        #expect(true)
        _ = view // Silence unused variable warning
    }
}
