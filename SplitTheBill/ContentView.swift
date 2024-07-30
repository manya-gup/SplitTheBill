import SwiftUI
import Contacts
import ContactsUI
import Combine

import PythonKit




struct ContentView: View {
    @State var pickedContacts: [ContactInfo] = []
    @State private var inputInfos: [FoodItem] = []
    @StateObject private var coordinator = Coordinator()
    @State private var showingNewWindow = false
    @State private var tip: String = "0.00"
    @State private var tax: String = "0.00"
    @State private var selectedTab: Tab = .plus
    @State var isPersonSelected: [Bool] = []
    @State private var bills: [Bill] = []
    
    @State private var currentDate: String = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: Date())
        }()
    @State private var isEditingDate = false

    @State private var bill = Bill(tip: "", tax: "", pickedContacts: [], inputInfos: [], isPersonSelected: [], title: "")

    @State private var showingDeleteContactAlert = false
    @State private var showingDeleteBillAlert = false
    @State private var contactToDeleteIndex: Int? = nil
    @State private var billToDelete: Bill? = nil
    @State private var totalIsExpanded = false
    @State private var isShowingMessageView = false
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isPhotoActionSheetPresented = false
    
    
    
    
    private let billsKey = "savedBills"

    
    @State private var showingBugReport = false
    
    
    
    
    
    
    
    
      //  @State private var showingFeatureSuggestion = false
        //@State private var showingAboutDeveloper = false


    var subtotal: Double {
        inputInfos.reduce(0.0) { result, item in
            if let price = Double(item.text2) {
                return result + (price * Double(item.selectedNumber))
            }
            return result
        }
    }

    var total: Double {
        if let tipNum = Double(tip), let taxNum = Double(tax) {
            return subtotal + tipNum + taxNum
        }
        return subtotal
    }
    
    
    var taxRate: Double {
        if subtotal != 0 {
            return (total - subtotal) / subtotal
        }
        
        return 0.0
    }


    var body: some View {
        TabView(selection: $selectedTab) {
            
            VStack(spacing: 16) {
                Text("Split/It")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.vertical)

                if bills.isEmpty {
                    Image(systemName: "tray.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                    Text("You have no saved bills.")
                        .font(.title2)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(bills.indices.reversed(), id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(bills[index].title)
                                        .font(.headline)

                                    Text("Split with:")
                                        .font(.subheadline)
                                    HStack {
                                        ForEach(bills[index].pickedContacts.indices, id: \.self) { idx in
                                            Text(bills[index].pickedContacts[idx].firstName)
                                                .font(.body)
                                        }
                                    }

                                    Text("Items:")
                                        .font(.subheadline)
                                    HStack {
                                        ForEach(bills[index].inputInfos, id: \.id) { item in
                                            Text(item.text1)
                                                .font(.body)
                                        }
                                    }

                                    Text("Total: $\(String(format: "%.2f", calculateTotal(bill: bills[index])))")
                                        .font(.headline)
                                        .padding(.top, 4)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.bottom, 8)
                                .frame(maxWidth: .infinity)
                                .onTapGesture {
                                    selectedTab = .plus
                                    bill = bills[index]
                                    pickedContacts = bill.pickedContacts
                                    inputInfos = bill.inputInfos
                                    tip = bill.tip
                                    tax = bill.tax
                                    isPersonSelected = bill.isPersonSelected
                                    currentDate = bill.title
                                }
                                .onLongPressGesture() {
                                    billToDelete = bills[index]
                                    showingDeleteBillAlert = true
                                }
                            }
                            
                        }
                    }
                }
            }
            .padding(.horizontal)

            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(Tab.house)
            .onAppear {
                bills = loadBills()
            }
            .alert(isPresented: $showingDeleteBillAlert) {
                Alert(
                    title: Text("Delete Bill"),
                    message: Text("Are you sure you want to delete this bill?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let bill = billToDelete {
                            deleteBill(bill)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            
            
            // Plus tab code
            
            VStack {
                Text("Split/It")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack {
                    if isEditingDate {
                        TextField("Enter Restaurant", text: $currentDate)
                            .font(.title)
                            .fontWeight(.bold)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.vertical)
                            .multilineTextAlignment(.leading)
                            .frame(width: 300)
                    } else {
                        Text(currentDate)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.vertical)
                    }

                    Button(action: {
                        isEditingDate.toggle()
                    }) {
                        Image(systemName: isEditingDate ? "checkmark" : "pencil.line")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal)

                List {
                    Section(header: HStack {
                        Text("People")
                        Spacer()
                        Button(action: {
                            openContactPicker()
                        }) {
                            Image(systemName: "person.crop.circle.badge.plus")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }) {
                        if pickedContacts.isEmpty {

                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(pickedContacts.indices, id: \.self) { index in
                                        VStack {
                                            Button(action: {
                                                selectContact(at: index)
                                            }) {
                                                Image(systemName: isPersonSelected[index] ? "person.fill" : "person")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 40, height: 40)
                                                    .foregroundColor(.blue)
                                                    .padding(.bottom, 4)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())

                                            VStack(alignment: .center) {
                                                Text(pickedContacts[index].firstName)
                                                    .font(.headline)
                                                    .multilineTextAlignment(.center)
                                                Text(pickedContacts[index].phoneNumber)
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color.clear)
                                        .onLongPressGesture {
                                            contactToDeleteIndex = index
                                            showingDeleteContactAlert = true
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }

                        }
                    }

                    Section(header: HStack {
                        Text("Bill")
                        Spacer()
                        Button(action: {
                            showingNewWindow = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .sheet(isPresented: $showingNewWindow) {
                            NewWindowView(isPresented: $showingNewWindow, inputInfos: $inputInfos)
                        }
                    }) {
                        ForEach(inputInfos.indices, id: \.self) { index in
                            EditableFoodItemView(foodItem: $inputInfos[index], pickedContacts: $pickedContacts, isPersonSelected: $isPersonSelected) {
                                deleteItem(at: index)
                            }
                        }
                        
                    }

                    Section(header: HStack {
                        Text("Subtotal")
                        Spacer()
                        Text("$\(String(format: "%.2f", subtotal))")
                            .font(.headline)
                    }) {
                        EmptyView()
                    }

                    Section(header: Text("Additional Costs")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Tip:")
                                Spacer()
                                TextField("Enter tip", text: Binding(
                                    get: {
                                        self.tip
                                    },
                                    set: { newValue in
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        self.tip = filtered
                                    }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .frame(width: 100)
                            }
                            HStack {
                                Text("Tax:")
                                Spacer()
                                TextField("Enter tax", text: Binding(
                                    get: {
                                        self.tax
                                    },
                                    set: { newValue in
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        self.tax = filtered
                                    }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .frame(width: 100)
                            }
                        }
                    }

                    Section(header: HStack {
                        //Text("Total")
                        //Spacer()
                        //Text("$\(String(format: "%.2f", total))")
                          //  .font(.headline)
                    }) {
                    DisclosureGroup(isExpanded: $totalIsExpanded) {
                        ForEach(pickedContacts) { contact in
                            let amount = splitBill(for: contact, pickedContacts: pickedContacts)
                            HStack {
                                Text(contact.firstName)
                                Spacer()
                                Text("$\(String(format: "%.2f", amount))")
                            }
                        }
                    } label: {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text("$\(String(format: "%.2f", total))")
                                .font(.headline)
                        }
                    }
                    .padding()
                    }
                    .padding(.vertical, 5)
                }

                Spacer()
                HStack {
                    Button(action: {
                        resetAll()
                    }) {
                        Text("Reset")
                            .foregroundColor(.red)
                            .font(.headline)
                            .padding()
                    }
                    Spacer()
                    
                    /*
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    }
                     */
                    
                    Button(action: {
                                    isPhotoActionSheetPresented = true
                                }) {
                                    Image(systemName: "photo.stack")
                                        .padding()
                                }
                                .actionSheet(isPresented: $isPhotoActionSheetPresented) {
                                    ActionSheet(title: Text("Select Photo"), message: Text("Choose a source"), buttons: [
                                        .default(Text("Camera")) {
                                            sourceType = .camera
                                            isImagePickerPresented = true
                                        },
                                        .default(Text("Photo Library")) {
                                            sourceType = .photoLibrary
                                            isImagePickerPresented = true
                                        },
                                        .cancel()
                                    ])
                                }
                    Spacer()

                    Button(action: {
                        saveBill()
                        saveBills(bills)
                        resetAll()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                                    self.isShowingMessageView = true
                                }) {
                                    Text("Forward Bill")
                                        .font(.headline)
                                        .padding()
                                }
                }
                .padding([.leading, .bottom])
                
                
                
                
                
                
            }
            .sheet(isPresented: $isShowingMessageView) {
                MessageView(pickedContacts: pickedContacts, messageBody: "Hello, this is a preloaded message!")
            }
            .sheet(isPresented: $isImagePickerPresented) {
                        ImagePicker(sourceType: sourceType) { image in
                            selectedImage = image
                            saveImageToAppDirectory(image: image)
                        }
                    }
            
            
            
            .tabItem {
                Image(systemName: "plus")
                Text("Plus")
            }
            .tag(Tab.plus)

            
            // Information tab code
            
            
            
            

            
            VStack {
                DisclosureGroup(isExpanded: $showingBugReport) {
                    VStack {
                        
                        
                    }
                } label: {
                    HStack {
                        Text("Report a Bug")
                            .font(.headline)
                    }
                }
                
                
                
                
                
                
                
                
                /*
                Text("Split/It")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.vertical)
                
                Image(systemName: "hammer.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                Text("Working on it.")
                    .font(.title2)
                 
                 
                 */
                 
            }
            .tabItem {
                Image(systemName: "info")
                Text("Information")
            }
            .tag(Tab.info)
            
        }
        .onReceive(coordinator.$pickedContact, perform: { contact in
            if let contact = contact, !pickedContacts.contains(where: { $0.phoneNumber == contact.phoneNumber }) {
                self.pickedContacts.append(contact)
                self.isPersonSelected.append(false)
            }
        })
        .environmentObject(coordinator)
        .alert(isPresented: $showingDeleteContactAlert) {
            Alert(
                title: Text("Delete Contact"),
                message: Text("Are you sure you want to delete this contact?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let index = contactToDeleteIndex {
                        deleteContact(at: index)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    
    func saveBills(_ bills: [Bill]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(bills)
            UserDefaults.standard.set(data, forKey: billsKey)
        } catch {
            print("Error encoding bills: \(error)")
        }
    }
    
    
    func loadBills() -> [Bill] {
        if let data = UserDefaults.standard.data(forKey: billsKey) {
            let decoder = JSONDecoder()
            do {
                let bills = try decoder.decode([Bill].self, from: data)
                return bills
            } catch {
                print("Error decoding bills: \(error)")
            }
        }
        return []
    }
    
    
    
    
    
    
    
    
    
    private func selectContact(at index: Int) {
        if isPersonSelected[index] {
            isPersonSelected[index] = false
        } else {
            for i in isPersonSelected.indices {
                isPersonSelected[i] = false
            }
            isPersonSelected[index] = true
        }
    }

    func saveImageToAppDirectory(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1) else {
            print("Error getting JPEG data from UIImage")
            return
        }
        
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error accessing document directory")
            return
        }
        
        let customFolderURL = directory.appendingPathComponent("MyAppImages")
        if !fileManager.fileExists(atPath: customFolderURL.path) {
            do {
                try fileManager.createDirectory(at: customFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating custom folder: \(error)")
                return
            }
        }
        
        let filename = customFolderURL.appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try data.write(to: filename)
            print("Image saved at: \(filename)")
            
            // Write the file path to a text file
            let filePathText = directory.appendingPathComponent("image_path.txt")
            try filename.path.write(to: filePathText, atomically: true, encoding: .utf8)
            print("File path written to: \(filePathText)")
            
        } catch {
            print("Error saving image: \(error)")
        }
    }

    
    
    func splitBill(for person: ContactInfo, pickedContacts: [ContactInfo]) -> Double {
        var amount: Double = 0.0
            
        inputInfos.forEach { foodItem in
            let participants = foodItem.addedPersons.isEmpty ? pickedContacts : foodItem.addedPersons
        
            if participants.contains(where: { $0.id == person.id }) {
                if let price = Double(foodItem.text2) {
                    amount += price * Double(foodItem.selectedNumber) / Double(participants.count)
                }
            }
        }
        print("Price of food")
        print(amount)
        
        
        let taxAmount = amount * taxRate
        
        
        amount += taxAmount
        
        print("Price after tax")
        
        print(amount)
        
        if let tip_num = Double(tip) {
            print(tip_num / Double(pickedContacts.count))
            amount = amount + (tip_num / Double(pickedContacts.count))
        }
        
        print("Price after tip")
        print(amount)
        
        return amount
    }
    
    func deleteContact(at index: Int) {
        pickedContacts.remove(at: index)
        isPersonSelected.remove(at: index)
    }

    func deleteItem(at index: Int) {
        inputInfos.remove(at: index)
    }

    func resetAll() {
        pickedContacts = []
        inputInfos = []
        tip = ""
        tax = ""
        isPersonSelected = []

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        currentDate = formatter.string(from: Date())
    }

    func saveBill() {
        
        
        
        
        /*
        if let index = bills.firstIndex(where: { $0.id == bill.id }) {
            bills[index] = Bill(id: bill.id, tip: tip, tax: tax, pickedContacts: pickedContacts, inputInfos: inputInfos, isPersonSelected: isPersonSelected, title: currentDate)
        } else {
            let newBill = Bill(tip: tip, tax: tax, pickedContacts: pickedContacts, inputInfos: inputInfos, isPersonSelected: isPersonSelected, title: currentDate)
            bills.append(newBill)
        }
         */
    }
    
    func deleteBill(_ bill: Bill) {
            if let index = bills.firstIndex(where: { $0.id == bill.id }) {
                bills.remove(at: index)
            }
    }


    func calculateTotal(bill: Bill) -> Double {
        var subtotal = bill.inputInfos.reduce(0.0) { result, item in
            if let price = Double(item.text2) {
                return result + (price * Double(item.selectedNumber))
            }
            return result
        }
        
        if let tipAmount = Double(tip) {
            subtotal += tipAmount
        }
        else {
            subtotal += 0
        }
            
        if let taxAmount = Double(tax) {
            subtotal += taxAmount
        }
        else {
            subtotal += 0
        }
    
        return subtotal
    }
    
    
    func openContactPicker() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = coordinator
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        contactPicker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
        contactPicker.predicateForSelectionOfProperty = NSPredicate(format: "key == 'phoneNumbers'")
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.rootViewController?.present(contactPicker, animated: true, completion: nil)
    }
    
    class Coordinator: NSObject, ObservableObject, CNContactPickerDelegate {
        @Published var pickedContact: ContactInfo?

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            self.pickedContact = nil
            if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                handleContact(firstName: contact.givenName, phoneNumber: phoneNumber)
            }
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            if contactProperty.key == CNContactPhoneNumbersKey,
               let phoneNumber = contactProperty.value as? CNPhoneNumber {
                let phoneNumberString = phoneNumber.stringValue
                handleContact(firstName: contactProperty.contact.givenName, phoneNumber: phoneNumberString)
            }
        }

        private func handleContact(firstName: String, phoneNumber: String) {
            let phoneNumberWithoutSpace = phoneNumber.replacingOccurrences(of: " ", with: "")
            let sanitizedPhoneNumber = phoneNumberWithoutSpace.hasPrefix("+") ? String(phoneNumberWithoutSpace.dropFirst()) : phoneNumberWithoutSpace
            DispatchQueue.main.async {
                self.pickedContact = ContactInfo(firstName: firstName, phoneNumber: sanitizedPhoneNumber)
            }
        }
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
