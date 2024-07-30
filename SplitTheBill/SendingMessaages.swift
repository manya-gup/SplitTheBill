import SwiftUI
import MessageUI

struct MessageView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    let pickedContacts: [ContactInfo]
    let messageBody: String

    func makeUIViewController(context: Context) -> UINavigationController {
        guard MFMessageComposeViewController.canSendText() else {
            print("Device cannot send messages")
            return UINavigationController()
        }

        let recipients = pickedContacts.map { $0.phoneNumber }

        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.recipients = recipients
        messageComposeVC.body = messageBody
        messageComposeVC.messageComposeDelegate = context.coordinator

        let navigationController = UINavigationController(rootViewController: messageComposeVC)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}
