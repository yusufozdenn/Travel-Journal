import UIKit
import CoreData
import Firebase

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var userEmailArray = [String]()
    var userNameArray = [String]()
    var likeArray = [Int]()
    var commentArray = [String]()
    var userImageArray = [String]()
    var documentIdArray = [String]()
    
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedPicture = ""
    var selectedPictureId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        tableView.delegate = self
        tableView.dataSource = self
      
        
       // sağ üste + (ekle) butonunu ayarlama
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action:#selector(addButtonClicked))
        getData()
    }
    
        
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newData"), object: nil)
       
       
        
    }
    
    func getDataFromFirestore(){
        let fireStoreDB = Firestore.firestore()
        fireStoreDB.collection("Posts").order(by: "date", descending: true).addSnapshotListener { snapShot, error in
            if error != nil{
                print(error?.localizedDescription)
                
            }else{
                if snapShot?.isEmpty != true {
                    self.userImageArray.removeAll(keepingCapacity: false)
                    self.userEmailArray.removeAll(keepingCapacity: false)
                    self.userNameArray.removeAll(keepingCapacity: false)
                    self.likeArray.removeAll(keepingCapacity: false)
                    self.documentIdArray.removeAll(keepingCapacity: false)
                    
                    for document in snapShot!.documents {
                        let documentId = document.documentID
                        self.documentIdArray.append(documentId)
                       
                        
                        if let postedby =  document.get("postedBy") as? String {
                            self.userEmailArray.append(postedby)
                        }
                        if let name = document.get("name") as? String{
                            self.userNameArray.append(name)
                        }
                        if let comment = document.get("comment") as? String{
                            self.commentArray.append(comment)
                        }
                        if let imageurl = document.get("imageUrl") as? String{
                            self.userImageArray.append(imageurl)
                        }
                    }
                    self.tableView.reloadData()
                }
               
            }
                
        }
    }
    
    @objc func getData(){
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pictures") //buralar önemli
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0{
                for result in results as! [NSManagedObject] {
                    if let name =  result.value(forKey: "name") as? String {
                        self.nameArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        self.idArray.append(id)
                    }
                    self.tableView.reloadData()
                }
            }
            
        } catch {
            print("error")
        }
    }
    
   /* func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = userNameArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }*/
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = nameArray[indexPath.row] // userNameArray içindeki veriyi kullan
        cell.contentConfiguration = content
        return cell
    }

    
  /*  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }*/
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    
    @objc func addButtonClicked(){
        selectedPicture = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC"{
            let destinationVc = segue.destination as! detailsVC
            destinationVc.chosenPicture = selectedPicture
            destinationVc.chosenPictureId = selectedPictureId
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPicture = nameArray[indexPath.row]
        selectedPictureId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender:nil )
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let idString = idArray[indexPath.row].uuidString
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pictures")
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0{
                    
                    for result in results as! [NSManagedObject]{
                        if let id = result.value(forKey: "id") as? UUID{
                            if id == idArray[indexPath.row]{
                                context.delete(result)
                                nameArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                
                                do {
                                    try context.save()
                                }
                                break
                            }
                        }
                    }
                }
                
            }catch{
                print("error")
            }
        }
        
    }
}
