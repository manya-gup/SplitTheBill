import SwiftUI

struct NewWindowView: View {
    
    @Binding var isPresented: Bool
    @Binding var inputInfos: [FoodItem]
    
    @State private var text1: String = ""
    @State private var text2: String = ""
    @State private var selectedNumber: Int = 1
    @State private var addedPersons: [ContactInfo] = []
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Item")
                .font(.headline)
            
            TextField("Enter item", text: $text1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Text("Price")
                .font(.headline)
            
            TextField("Enter price", text: $text2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Text("Quantity")
                .font(.headline)
            
            Picker("Quantity", selection: $selectedNumber) {
                ForEach(1..<101) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding(.horizontal)
            
            Button("Add") {
                let newInfo = FoodItem(text1: text1, text2: text2, selectedNumber: selectedNumber, addedPersons: addedPersons)
                inputInfos.append(newInfo)
                isPresented = false
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarTitle("Add Item", displayMode: .inline)
    }
}


struct EditableFoodItemView: View {
    @Binding var foodItem: FoodItem
    @Binding var pickedContacts: [ContactInfo]
    @Binding var isPersonSelected: [Bool]
    
    @State private var isEditing = false
    var onDelete: (() -> Void)?
    @State private var nobodySelectedAlert = false

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(foodItem.text1)
                    .font(.headline)
                Text("Price: $\(foodItem.text2)")
                    .font(.subheadline)
                Text("Quantity: \(foodItem.selectedNumber)")
                    .font(.subheadline)
                Text("People: ")
                    .font(.subheadline)
                HStack {
                    if foodItem.addedPersons.count == pickedContacts.count {
                        Text("Everyone")
                        .font(.subheadline)
                    } else {
                        ForEach(foodItem.addedPersons) { person in
                            Text(person.firstName)
                                .font(.subheadline)
                            }
                        }
                    }
                
            }
            Spacer()
            Button(action: {
                isEditing.toggle()
            }) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.blue)
            }
            .buttonStyle(BorderlessButtonStyle())
            .sheet(isPresented: $isEditing) {
                EditFoodItemView(foodItem: $foodItem, isPresented: $isEditing)
            }
            Button(action: {
                onDelete?()
            }) {
                Image(systemName: "trash.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 5)
        .onTapGesture {
            var selected: Bool = false
                        for (index, isSelected) in isPersonSelected.enumerated() {
                            if isSelected {
                                selected = true
                                let selectedPerson = pickedContacts[index]
                                if let existingIndex = foodItem.addedPersons.firstIndex(where: { $0.id == selectedPerson.id }) {
                                    foodItem.addedPersons.remove(at: existingIndex)
                                } else {
                                    foodItem.addedPersons.append(selectedPerson)
                                }
                                print(selectedPerson)
                            }
                        }
            if !selected {
                nobodySelectedAlert = true
            }
            
        }
        .alert(isPresented: $nobodySelectedAlert) {
            Alert(title: Text("Selection Needed"), message: Text("Select someone to add them to this item"), dismissButton: .default(Text("OK")))
        }
    }
}


struct EditFoodItemView: View {
    @Binding var foodItem: FoodItem
    @Binding var isPresented: Bool
    @State private var editedText1: String
    @State private var editedText2: String
    @State private var editedSelectedNumber: Int

    init(foodItem: Binding<FoodItem>, isPresented: Binding<Bool>) {
        _foodItem = foodItem
        _isPresented = isPresented
        _editedText1 = State(initialValue: foodItem.wrappedValue.text1)
        _editedText2 = State(initialValue: foodItem.wrappedValue.text2)
        _editedSelectedNumber = State(initialValue: foodItem.wrappedValue.selectedNumber)
    }

    var body: some View {
        VStack {
            Text("Item")
                .font(.headline)
            
            TextField("Item", text: $editedText1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Text("Price")
                .font(.headline)
            
            TextField("Price", text: $editedText2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Text("Quantity")
                .font(.headline)
            
            Picker("Quantity", selection: $editedSelectedNumber) {
                ForEach(1..<101) {
                    Text("\($0)").tag($0)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
            Button("Save") {
                foodItem.text1 = editedText1
                foodItem.text2 = editedText2
                foodItem.selectedNumber = editedSelectedNumber
                isPresented = false
            }
            .padding()
        }
        .navigationBarTitle("Edit Item", displayMode: .inline)
    }
}





struct NewWindowView_Previews: PreviewProvider {
    static var previews: some View {
        NewWindowView(isPresented: .constant(true), inputInfos: .constant([]))
    }
}
