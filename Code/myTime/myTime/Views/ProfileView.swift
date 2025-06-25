import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingInterests = false
    
    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 15) {
                        Text("Progressi")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                        
                       
                    }
                    
                    // Progress section
                    VStack(spacing: 15) {
                        Text("I tuoi progressi")
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        HStack {
                            VStack {
                                Text("\(taskManager.profile.completedTasks)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appLightBlue)
                                Text("Task completati")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text(String(format: "%.1f", taskManager.profile.totalHours))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appLightBlue)
                                Text("Ore totali")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appDarkBlue.opacity(0.3))
                        )
                    }
                    
                    // Sleep section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sezione Sonno")
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Inizio")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.sleepStart, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Fine")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.sleepEnd, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appDarkBlue.opacity(0.3))
                    )
                    
                    // Work section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sezione Lavoro")
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Inizio")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.workStart, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Fine")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.workEnd, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appDarkBlue.opacity(0.3))
                    )
                    
                    // Interests button
                    Button("Seleziona Interessi") {
                        showingInterests = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appDarkBlue)
                    )
                    .foregroundColor(.appBeige)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingInterests) {
            InterestsView()
                .environmentObject(taskManager)
        }
    }
}
