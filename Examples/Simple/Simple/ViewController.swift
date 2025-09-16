import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    // MARK: - UI Elements
    let messageInputTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 5.0
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.text = "Enter your message here..." // Placeholder
        textView.textColor = UIColor.lightGray
        textView.tag = 0 // Tag for input
        textView.returnKeyType = .done
        textView.enablesReturnKeyAutomatically = true
        return textView
    }()

    let processedMessageTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 5.0
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        textView.text = "Processed messages will appear here." // Placeholder
        textView.textColor = UIColor.lightGray
        textView.tag = 1 // Tag for output
        return textView
    }()

    let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Clear", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5.0
        return button
    }()

    let signButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5.0
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        messageInputTextView.delegate = self
        setupKeyboardDismissal()
    }

    // MARK: - UI Setup
    func setupUI() {
        view.backgroundColor = .white
        title = "Satochip Signer"

        // Add subviews
        view.addSubview(messageInputTextView)
        view.addSubview(processedMessageTextView)
        view.addSubview(clearButton)
        view.addSubview(signButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Message Input TextView - Fixed height for 2 lines
            messageInputTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            messageInputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageInputTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageInputTextView.heightAnchor.constraint(equalToConstant: 60), // Reduced to ~2 lines

            // Processed Message TextView - Takes remaining space
            processedMessageTextView.topAnchor.constraint(equalTo: messageInputTextView.bottomAnchor, constant: 20),
            processedMessageTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            processedMessageTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            processedMessageTextView.bottomAnchor.constraint(equalTo: clearButton.topAnchor, constant: -20),

            // Clear Button - Fixed at bottom
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            clearButton.widthAnchor.constraint(equalToConstant: 100),
            clearButton.heightAnchor.constraint(equalToConstant: 44),

            // Sign Button - Fixed at bottom
            signButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            signButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            signButton.widthAnchor.constraint(equalToConstant: 100),
            signButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Add button actions
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        signButton.addTarget(self, action: #selector(signButtonTapped), for: .touchUpInside)
    }

    // MARK: - Button Actions
    @objc func clearButtonTapped() {
        messageInputTextView.text = "Enter your message here..."
        messageInputTextView.textColor = UIColor.lightGray
        processedMessageTextView.text = "Processed messages will appear here."
        processedMessageTextView.textColor = UIColor.lightGray
        messageInputTextView.resignFirstResponder() // Dismiss keyboard
    }

    @objc func signButtonTapped() {
        let message = messageInputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if message == "Enter your message here..." || message.isEmpty {
            let alert = UIAlertController(title: "Input Required", message: "Please enter a message to sign.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        // Placeholder for signing logic
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        processedMessageTextView.textColor = .black
        processedMessageTextView.text = "[\(timestamp)] Message: \"\(message)\" signed successfully (placeholder).\n" + processedMessageTextView.text
        messageInputTextView.resignFirstResponder() // Dismiss keyboard
    }

    // MARK: - UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = textView.tag == 0 ? "Enter your message here..." : "Processed messages will appear here."
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Dismiss keyboard when user presses "Done" or "Return"
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    // MARK: - Keyboard Handling
    func setupKeyboardDismissal() {
        // Add tap gesture to dismiss keyboard when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
