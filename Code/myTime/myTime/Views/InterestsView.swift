import SwiftUI

struct InterestsView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddInterest = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBlack.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header con pulsante chiudi
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
                    
                    // Titolo centrato
                    VStack(spacing: 15) {
                        Text("Seleziona Interessi")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                    }

                    if taskManager.interests.isEmpty {
                        Spacer()
                        Text("Clicca sul pulsante per aggiungere un task da suggerire")
                            .foregroundColor(.appBeige)
                            .padding()
                        Spacer()
                    } else {
                        // Lista con sfondo appBlack e riquadri appDarkBlue (come nell'immagine)
                        List {
                            ForEach(taskManager.interests) { interest in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(interest.name)
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.appBeige)
                                    Text("Durata: \(Int(interest.duration / 60)) min | Preferenza: \(interest.preferenceLevel) | Fascia: \(interest.timeSlot)")
                                        .font(.subheadline)
                                        .foregroundColor(.appLightBlue)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.appDarkBlue.opacity(0.3))
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        taskManager.removeInterest(interest)
                                    } label: {
                                        Label("Rimuovi", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.appBlack)
                        .scrollContentBackground(.hidden)
                    }

                    // Pulsante completamente cliccabile
                    Button(action: {
                        showingAddInterest = true
                    }) {
                        Text("Aggiungi interessi")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue))
                            .foregroundColor(.appBeige)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddInterest) {
                AddInterestView()
                    .environmentObject(taskManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
