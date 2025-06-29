import SwiftUI

struct AddInterestView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var durationMinutes: Int = 30
    @State private var preferenceLevel: Int = 3
    @State private var selectedTimeSlot: String = "Mattina"  // valore di default

    let timeSlots = ["Mattina", "Pomeriggio", "Sera"]

    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header con pulsante chiudi
                    headerSection
                    
                    // Titolo
                    titleSection
                    
                    // Form content
                    formContent
                    
                    // Pulsante salva interesse con stesso stile e posizionamento di ProfileView
                    Spacer(minLength: 20)
                    saveButton
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.appBeige)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.appBeige)
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
        }
        .zIndex(1)
    }
    
    private var titleSection: some View {
        VStack(spacing: 15) {
            Text("Nuovo Interesse")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.appBeige)
        }
    }
    
    private var formContent: some View {
        VStack(spacing: 20) {
            // Nome interesse
            nameSection
            
            // Durata
            durationSection
            
            // Grado di preferenza
            preferenceSection
            
            // Fascia oraria
            timeSlotSection
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nome interesse")
                .font(.headline)
                .foregroundColor(.appBeige)
            
            TextField("Es. Lettura, Meditazione", text: $name)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.appBeige.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(.appBeige)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkBlue.opacity(0.3))
        )
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Durata (minuti)")
                .font(.headline)
                .foregroundColor(.appBeige)
            
            HStack {
                Button(action: {
                    if durationMinutes > 5 {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            durationMinutes -= 5
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appBeige)
                        .scaleEffect(durationMinutes > 5 ? 1.0 : 0.8)
                        .opacity(durationMinutes > 5 ? 1.0 : 0.5)
                }
                .animation(.easeInOut(duration: 0.2), value: durationMinutes)
                
                Spacer()
                
                Text("\(durationMinutes) minuti")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.appBeige)
                    .animation(.easeInOut(duration: 0.2), value: durationMinutes)
                
                Spacer()
                
                Button(action: {
                    if durationMinutes < 180 {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            durationMinutes += 5
                        }
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appBeige)
                        .scaleEffect(durationMinutes < 180 ? 1.0 : 0.8)
                        .opacity(durationMinutes < 180 ? 1.0 : 0.5)
                }
                .animation(.easeInOut(duration: 0.2), value: durationMinutes)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkBlue.opacity(0.3))
        )
    }
    
    private var preferenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Grado di preferenza")
                .font(.headline)
                .foregroundColor(.appBeige)
            
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            preferenceLevel = level
                        }
                    }) {
                        Text("⭐️ \(level)")
                            .font(.caption)
                            .foregroundColor(preferenceLevel == level ? .appBlack : .appBeige)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(preferenceLevel == level ? Color.appBeige : Color.clear)
                            )
                            .scaleEffect(preferenceLevel == level ? 1.05 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut(duration: 0.2), value: preferenceLevel)
                    
                    if level < 5 {
                        Divider()
                            .background(Color.appBeige.opacity(0.3))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appBeige.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkBlue.opacity(0.3))
        )
    }
    
    private var timeSlotSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fascia oraria")
                .font(.headline)
                .foregroundColor(.appBeige)
            
            HStack(spacing: 0) {
                ForEach(timeSlots, id: \.self) { slot in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTimeSlot = slot
                        }
                    }) {
                        Text(slot)
                            .font(.caption)
                            .foregroundColor(selectedTimeSlot == slot ? .appBlack : .appBeige)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedTimeSlot == slot ? Color.appBeige : Color.clear)
                            )
                            .scaleEffect(selectedTimeSlot == slot ? 1.05 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut(duration: 0.2), value: selectedTimeSlot)
                    
                    if slot != timeSlots.last {
                        Divider()
                            .background(Color.appBeige.opacity(0.3))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appBeige.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkBlue.opacity(0.3))
        )
    }
    
    private var saveButton: some View {
        Button(action: {
            let interest = Interest(
                name: name,
                duration: TimeInterval(durationMinutes * 60),
                preferenceLevel: preferenceLevel,
                timeSlot: selectedTimeSlot
            )
            taskManager.addInterest(interest)
            dismiss()
        }) {
            Text("Salva interesse")
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue))
                .foregroundColor(.appBeige)
        }
        .disabled(name.isEmpty)
        .padding() // Padding esterno, come nel bottone "Seleziona Interessi" di ProfileView
    }
}
