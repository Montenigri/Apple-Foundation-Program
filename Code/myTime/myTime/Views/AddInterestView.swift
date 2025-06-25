import SwiftUI

struct AddInterestView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var durationMinutes: Int = 30
    @State private var preferenceLevel: Int = 3
    @State private var selectedTimeSlot: String = "Mattina"  // valore di default

    let timeSlots = ["Mattina", "Pomeriggio", "Sera"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nome interesse").foregroundColor(.appBeige)) {
                    TextField("Es. Lettura, Meditazione", text: $name)
                }

                Section(header: Text("Durata (minuti)").foregroundColor(.appBeige)) {
                    Stepper("\(durationMinutes) minuti", value: $durationMinutes, in: 5...180, step: 5)
                }

                Section(header: Text("Grado di preferenza").foregroundColor(.appBeige)) {
                    Picker("Preferenza", selection: $preferenceLevel) {
                        ForEach(1...5, id: \.self) { level in
                            Text("⭐️ \(level)").tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Fascia oraria").foregroundColor(.appBeige)) {
                    Picker("Fascia oraria", selection: $selectedTimeSlot) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Text(slot)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Button("Salva interesse") {
                        let interest = Interest(
                            name: name,
                            duration: TimeInterval(durationMinutes * 60),
                            preferenceLevel: preferenceLevel,
                            timeSlot: selectedTimeSlot
                        )
                        taskManager.addInterest(interest)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.appBeige)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue))
                }
            }
            .foregroundColor(.black)
            .background(Color.appBlack.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle("Aggiungi Interesse")
        }
    }
}