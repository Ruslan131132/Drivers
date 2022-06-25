import UIKit
import CoreData

class DetailViewController: UIViewController {

  // MARK: - Properties
  var managedObjectContext: NSManagedObjectContext?

  var note: Note?

  var detailItem: Any? {
    didSet {
      configureView()
    }
  }

  // MARK: - IBOutlets
  @IBOutlet weak var detailTextView: UITextView!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    configureView()
  }
}

// MARK: - Internal
extension DetailViewController {

  func configureView() {
    guard let detail = self.detailItem as? Note,
      let detailTextView = self.detailTextView else {
        return
    }

    detailTextView.text = detail.noteText
  }
}

// MARK: - UITextViewDelegate
extension DetailViewController: UITextViewDelegate {
  
  func textViewDidEndEditing( _ textView: UITextView) {
    
    if let detail = self.detailItem as? Note,
      let detailTextView = self.detailTextView {
        detail.noteText = detailTextView.text
    }

    do {
      try managedObjectContext?.save()
    } catch {
      print("nothing saved.")
    }
  }
}
