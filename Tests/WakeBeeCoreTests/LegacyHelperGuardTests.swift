import Testing
@testable import WakeBeeCore

@Suite struct LegacyHelperGuardTests {
    @Test func absentOldServiceAndJournalPermitSetup() throws {
        try LegacyHelperGuard.checkResult(exitStatus: 113, hasRecovery: false)
    }

    @Test(arguments: [(Int32(0), false), (Int32(113), true), (Int32(1), false), (Int32(9), false)])
    func activeOrUncertainLegacyStateNeverPermitsTakeover(_ state: (Int32, Bool)) {
        #expect(throws: LegacyHelperGuard.Failure.self) {
            try LegacyHelperGuard.checkResult(exitStatus: state.0, hasRecovery: state.1)
        }
    }
}
