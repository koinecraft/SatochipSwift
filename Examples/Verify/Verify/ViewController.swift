import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.systemBackground
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8.0
        textView.isEditable = false
        textView.text = "Ready to verify...\n"
        return textView
    }()
    
    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Verify", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8.0
        button.addTarget(self, action: #selector(verifyButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        title = "Verify"
        
        view.addSubview(textView)
        view.addSubview(verifyButton)
        
        NSLayoutConstraint.activate([
            // Text view constraints
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: verifyButton.topAnchor, constant: -20),
            
            // Button constraints
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            verifyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            verifyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Actions
    @objc private func verifyButtonTapped() {
        logMessage("Verified")
    }
    
    // MARK: - Logging
    private func logMessage(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let logEntry = "\(timestamp) - \(message)\n"
        
        // Append the message to the text view
        textView.text += logEntry
        
        // Scroll to the bottom to show the most recent message
        let bottom = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(bottom)
    }
}
