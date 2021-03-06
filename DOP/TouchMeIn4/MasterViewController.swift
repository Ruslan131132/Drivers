import UIKit
import CoreData

class MasterViewController: UIViewController, UITableViewDelegate {

  @IBOutlet var tableView: UITableView!
  var detailViewController: DetailViewController?
  var managedObjectContext: NSManagedObjectContext?
  var isAuthenticated = false
  var didReturnFromBackground = false
  var _fetchedResultsController: NSFetchedResultsController<Note>?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
//    navigationItem.leftBarButtonItem = editButtonItem

//    let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
//    navigationItem.rightBarButtonItem = addButton
//    if let split = splitViewController {
//      let controllers = split.viewControllers
//      detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
//    }
    
    NotificationCenter.default.addObserver(self, selector: #selector(MasterViewController.appWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(MasterViewController.appDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    
    view.alpha = 0
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
    isAuthenticated = true
    view.alpha = 1.0
  }

  
  func showLoginView() {
    if !isAuthenticated {
      performSegue(withIdentifier: "loginView", sender: self)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(false)
    showLoginView()
  }
  
  @objc func appWillResignActive(_ notification : Notification) {
    view.alpha = 0
    isAuthenticated = false
    didReturnFromBackground = true
  }
  
  @objc func appDidBecomeActive(_ notification : Notification) {
    if didReturnFromBackground {
      showLoginView()
      view.alpha = 1
    }
  }

  @objc
  func insertNewObject(_ sender: Any) {
    let context = self.fetchedResultsController.managedObjectContext
    let newNote = Note(context: context)

    // If appropriate, configure the new managed object.
    newNote.date = Date()
    newNote.setValue("New Note", forKey: "noteText")

    // Save the context.
    do {
      try context.save()
    } catch {
      // Replace this implementation with code to handle the error appropriately.
      // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }
  
  @IBAction func logoutAction(_ sender: Any) {
    isAuthenticated = false
    performSegue(withIdentifier: "loginView", sender: self)
  }

  // MARK: - Segues

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      if let indexPath = tableView.indexPathForSelectedRow {
        let object = fetchedResultsController.object(at: indexPath)
        (segue.destination as! DetailViewController).detailItem = object
      }
    }
  }

  func configureCell(_ cell: UITableViewCell, withNote note: Note) {
    cell.textLabel?.text = note.noteText
  }
}

// MARK: - UITableViewDataSource
extension MasterViewController: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    return fetchedResultsController.sections?.count ?? 0
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = fetchedResultsController.sections![section]
    return sectionInfo.numberOfObjects
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    let note = fetchedResultsController.object(at: indexPath)
    configureCell(cell, withNote: note)
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let context = fetchedResultsController.managedObjectContext
      context.delete(fetchedResultsController.object(at: indexPath))

      do {
        try context.save()
      } catch let error as NSError {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
  }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MasterViewController: NSFetchedResultsControllerDelegate {

  var fetchedResultsController: NSFetchedResultsController<Note> {
    if _fetchedResultsController != nil {
      return _fetchedResultsController!
    }

    let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()

    // Set the batch size to a suitable number.
    fetchRequest.fetchBatchSize = 20

    // Edit the sort key as appropriate.
    let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)

    fetchRequest.sortDescriptors = [sortDescriptor]

    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
    aFetchedResultsController.delegate = self
    _fetchedResultsController = aFetchedResultsController

    do {
      try _fetchedResultsController!.performFetch()
    } catch let error as NSError {
      fatalError("Unresolved error \(error), \(error.userInfo)")
    }

    return _fetchedResultsController!
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    switch type {
    case .insert:
      tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
    case .delete:
      tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
    default:
      return
    }
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
      tableView.insertRows(at: [newIndexPath!], with: .fade)
    case .delete:
      tableView.deleteRows(at: [indexPath!], with: .fade)
    case .update:
      configureCell(tableView.cellForRow(at: indexPath!)!, withNote: anObject as! Note)
    case .move:
      configureCell(tableView.cellForRow(at: indexPath!)!, withNote: anObject as! Note)
      tableView.moveRow(at: indexPath!, to: newIndexPath!)
    }
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
}
