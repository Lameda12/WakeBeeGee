import Foundation
import Testing
@testable import WakeBeeCore

@Suite struct SystemSleepStateTests {
    @Test func readsExplicitKernelBooleans() throws {
        #expect(try SystemSleepState.decode(kCFBooleanFalse) == false)
        #expect(try SystemSleepState.decode(kCFBooleanTrue) == true)
    }

    @Test func missingOrMalformedValuesCannotAuthorizeSleepChanges() {
        let invalid: [CFTypeRef?] = [nil, "0" as CFString, "1" as CFString,
                                    NSNumber(value: 0), NSNumber(value: 1), NSNull()]
        for value in invalid {
            #expect(throws: SystemSleepState.ReadError.self) { try SystemSleepState.decode(value) }
        }
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["WAKEBEE_TEST_POWER_REGISTRY"] == "1"))
    func readsTheLiveMacWithoutChangingPowerSettings() throws {
        let disabled = try SystemSleepState.readDisabled()
        print("Live kernel SleepDisabled: \(disabled)")
    }
}
