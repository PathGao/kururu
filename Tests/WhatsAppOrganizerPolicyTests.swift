import Foundation

enum WhatsAppOrganizerPolicyTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(WhatsAppOrganizerPolicy.allowsRun(manual: true, automaticEnabled: false, accessConfirmed: true),
               "manual organization remains available after turning automation off")
        expect(!WhatsAppOrganizerPolicy.allowsRun(manual: false, automaticEnabled: false, accessConfirmed: true),
               "queued automatic runs cannot process files after automation is turned off")
        expect(WhatsAppOrganizerPolicy.allowsRun(manual: false, automaticEnabled: true, accessConfirmed: true),
               "enabled automation can still process eligible files")
        expect(!WhatsAppOrganizerPolicy.allowsRun(manual: true, automaticEnabled: false, accessConfirmed: false),
               "manual organization still requires confirmed Downloads access")
        expect(!WhatsAppOrganizerPolicy.allowsRun(manual: false, automaticEnabled: true, accessConfirmed: false),
               "automatic organization still requires confirmed Downloads access")
    }
}
