import UIKit
import CoreData
import MapKit
import CoreLocation
import Firebase
import FirebaseStorage
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
//place yazan şeyleri comment'e çevirecez!!!

class detailsVC: UIViewController , UIImagePickerControllerDelegate,UINavigationControllerDelegate,MKMapViewDelegate,CLLocationManagerDelegate {

    @IBOutlet weak var mapKitView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var chosenPicture = ""
    var chosenPictureId : UUID?
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    var annotationName = ""
    var annotatitonComment = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapKitView.isZoomEnabled = true
        mapKitView.isScrollEnabled = true
        mapKitView.isPitchEnabled = true
        mapKitView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let pinGesture = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(pinGesture: )))
        pinGesture.minimumPressDuration = 2
        mapKitView.addGestureRecognizer(pinGesture)
        
        if chosenPicture != "" {
            saveButton.isEnabled = false
            
            //core data
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pictures")
            let idString = chosenPictureId?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
             let results =   try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "name") as? String {
                            annotationName = name
                            if let comment = result.value(forKey: "comment") as? String {
                                annotatitonComment = comment
                                if let year = result.value(forKey: "year") as? Int{
                                   
                                    if let imageData = result.value(forKey: "image") as? Data {
                                        let image = UIImage(data: imageData)
                                        imageView.image = image
                                        if let latitude = result.value(forKey: "latitude") as? Double{
                                            annotationLatitude = latitude
                                            if let longitude = result.value(forKey: "longitude") as? Double {
                                                    annotationLongitude = longitude
                                                // her şey okey oldugunda annotation'u oluşturuyoruz :
                                                // yukarda "do" içinde yaptıgımız veri çekme işlemi sayesinde yeni annotation'a önceden kaydettiğimiz verileri kopyaladık:
                                                let annotation = MKPointAnnotation()
                                                annotation.title = annotationName
                                                annotation.subtitle = annotatitonComment
                                              let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                                annotation.coordinate = coordinate
                                                
                                                mapKitView.addAnnotation(annotation)
                                                nameText.text = annotationName
                                                commentText.text = annotatitonComment
                                                
                                                locationManager.stopUpdatingLocation()
                                                let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                                let region = MKCoordinateRegion(center: coordinate, span: span)
                                                mapKitView.setRegion(region, animated: true)
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                       
                       
                       
                       
                    }
                }
            } catch{
                print("error")
            }
           }
        else {
            saveButton.isEnabled = false
            nameText.text = ""
           
            locationManager.stopUpdatingLocation()
        }
            
        
        //klavyeyi gizlemek için recognizer
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        //resim seçmek için recognizer
        imageView.isUserInteractionEnabled = true
        let imageTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(imageTapRecognizer)
    }
   
    @objc func chooseLocation(pinGesture : UILongPressGestureRecognizer  ){
        if pinGesture.state == .began{
            // pin eklemek için dokundugum konumu kaydetme :
            let touchedPoint = pinGesture.location(in: self.mapKitView)
            let touchedCoordinates = self.mapKitView.convert(touchedPoint, toCoordinateFrom: mapKitView)
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            //pin olusturma ve koordinata ekleme :
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapKitView.addAnnotation(annotation)
       
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if chosenPicture == "" {
            let locations = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude , longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: locations, span: span)
            mapKitView.setRegion(region, animated: true)
        }
    }
    
    // info tuşunu ve maps'de açmayı aktif etme
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
       
        if chosenPicture != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                //closure veya call back func. oluyor yukardaki placemarks,errorlu kısım
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationName
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
               
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
       
        if annotation is MKUserLocation{
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKMarkerAnnotationView
       
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
    
    @objc func selectImage() {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.imageView.image = info[.editedImage] as? UIImage
        saveButton.isEnabled = true
        self.dismiss(animated: true)
    }
    
    func MakeAlert(titleInput : String,messageInput : String){
        let alert = UIAlertController(title: titleInput, message: messageInput, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        alert.addAction(okButton)
        self.present(alert, animated: true)
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let mediaFolder = storageRef.child("media")
        
        if let data = imageView.image?.jpegData(compressionQuality: 0.5) {
            let uuid = UUID()
            let imageRef = mediaFolder.child("\(uuid).jpg")
            imageRef.putData(data, metadata: nil) { metadata, error in
                if error != nil {
                    self.MakeAlert(titleInput: "Error occured", messageInput: error?.localizedDescription ?? "Error")
                }else{
                    imageRef.downloadURL { url, error in
                        if error == nil {
                            let imageUrl = url?.absoluteString
                            //database
                            let firestoreDB = Firestore.firestore()
                            var firestoreRef : DocumentReference? = nil
                            
                            let firestorePost = ["imageUrl": imageUrl! , "postedBy" : Auth.auth().currentUser!.email!,"name" : self.nameText.text! , "date" : FieldValue.serverTimestamp(), "comment" : self.commentText.text!] as [String : Any]
                            
                            firestoreRef = firestoreDB.collection("Posts").addDocument(data: firestorePost, completion: { error in
                                if error != nil{
                                    
                                    self.MakeAlert(titleInput: "Error", messageInput: error?.localizedDescription ?? "Error")
                                    
                                    
                                } else{
                                    self.imageView.image = UIImage(systemName: "photo.stack")
                                    self.nameText.text = ""
                                    self.tabBarController?.selectedIndex = 0
                                }
                            })
                         
                        }
                    }
                }
            }
        }
        
       
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPicture = NSEntityDescription.insertNewObject(forEntityName: "Pictures", into: context)
        
        //attributes
        newPicture.setValue(nameText.text, forKey: "name")
        newPicture.setValue(commentText.text, forKey: "comment")
        newPicture.setValue(chosenLatitude, forKey: "latitude")
        newPicture.setValue(chosenLongitude, forKey: "longitude")
        
      
        
        newPicture.setValue(UUID(), forKey: "id")
        
        let data = imageView.image?.jpegData(compressionQuality: 0.5)
        newPicture.setValue(data, forKey: "image")
        
        do {
            try context.save()
            print("succes")
        } catch{
            print("error")
        }
    
        
        
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
    }
 
}
