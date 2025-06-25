import SwiftUI

struct InterestsView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddInterest = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBlack.ignoresSafeArea()
                
                VStack {
                    if taskManager.interests.isEmpty {
                        Text("Nessun interesse aggiunto")
                            .foregroundColor(.appBeige)
                            .padding()
                    } else {
                        ScrollView {
                            ForEach(taskManager.interests) { interest in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(interest.name)
                                        .font(.headline)
                                        .foregroundColor(.appLightBlue)
                                    Text("Durata: \(Int(interest.duration / 60)) min | Preferenza: \(interest.preferenceLevel) | Fascia: \(interest.timeSlot)")
                                        .font(.subheadline)
                                        .foregroundColor(.appBeige)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue.opacity(0.3)))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        taskManager.removeInterest(interest)
                                    } label: {
                                        Label("Rimuovi", systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Aggiungi interessi") {
                        showingAddInterest = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue))
                    .foregroundColor(.appBeige)
                    .padding()
                }
            }
            .navigationTitle("Seleziona Interessi")
            .sheet(isPresented: $showingAddInterest) {
                AddInterestView()
                    .environmentObject(taskManager)
            }
        }
    }
}