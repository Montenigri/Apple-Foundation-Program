//
//  OnboardingView.swift
//  Mytime
//
//  Created by angelo galante on 27/06/25.
//

import SwiftUI
import WebKit

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    
    let onboardingPages = [
        OnboardingPage(
            title: "Benvenuto in MyTime",
            description: "Recupera il controllo del tuo tempo e ottimizza gli slot liberi della giornata in base ai tuoi interessi.",
            imageName: "clock.fill",
            gifName: nil,
            isWelcome: true
        ),
        OnboardingPage(
            title: "La tua programmazione",
            description: "Nella schermata MyTime vedrai tutti i tuoi task programmati. Swipe da destra a sinistra per completare, da sinistra a destra per eliminare.",
            imageName: "calendar",
            gifName: "prova"
        ),
        OnboardingPage(
            title: "Aggiungi nuovi task",
            description: "Tocca il pulsante '+' in alto a destra nella MyTimeView per aggiungere nuovi task alla tua programmazione.",
            imageName: "plus.circle.fill",
            gifName: "add_task_demo"
        ),
        OnboardingPage(
            title: "Configura i dettagli",
            description: "Nell'AddTaskView potrai configurare tutti i dettagli del tuo nuovo task: nome, descrizione, durata e luogo.",
            imageName: "square.and.pencil",
            gifName: "task_details_demo"
        ),
        OnboardingPage(
            title: "I tuoi progressi",
            description: "Tocca l'icona profilo in alto a destra nella MyTimeView per monitorare i tuoi progressi e gestire le impostazioni.",
            imageName: "person.circle.fill",
            gifName: "profile_demo"
        ),
        OnboardingPage(
            title: "Dettagli del task",
            description: "Tocca qualsiasi task nella programmazione per visualizzarne i dettagli completi e gestirne lo stato.",
            imageName: "info.circle.fill",
            gifName: "task_detail_view_demo"
        ),
        OnboardingPage(
            title: "I tuoi interessi",
            description: "Nel ProfileView potrai aggiungere i tuoi interessi. L'app li userà per suggerirti attività durante i momenti liberi della giornata.",
            imageName: "heart.fill",
            gifName: "interests_demo"
        ),
        OnboardingPage(
            title: "Gestisci interessi",
            description: "Nella InterestsView vedrai tutti i tuoi interessi salvati. Potrai aggiungerli, modificarli o rimuoverli facilmente.",
            imageName: "list.bullet.circle.fill",
            gifName: "interests_list_demo"
        ),
        OnboardingPage(
            title: "Configura interesse",
            description: "Quando aggiungi un nuovo interesse, potrai configurarne nome, durata, grado di preferenza e fascia oraria preferita.",
            imageName: "gearshape.fill",
            gifName: "add_interest_demo"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.appDarkBlue.ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            
            VStack {
                Spacer()
                
                HStack {
                    if currentPage > 0 {
                        Button("Indietro") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.appLightBlue)
                    }
                    
                    Spacer()
                    
                    if currentPage < onboardingPages.count - 1 {
                        Button("Avanti") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.appLightBlue)
                    } else {
                        Button("Inizia") {
                            hasSeenOnboarding = true
                        }
                        .font(.headline)
                        .foregroundColor(.appBeige)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.appDarkBlue)
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let gifName: String?
    let features: [String]?
    let isWelcome: Bool
    
    init(title: String, description: String, imageName: String, gifName: String? = nil, features: [String]? = nil, isWelcome: Bool = false) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.gifName = gifName
        self.features = features
        self.isWelcome = isWelcome
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if page.isWelcome {
                // Welcome screen with special styling
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(.appLightBlue)
                    .padding(.bottom, 20)
                
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.appBeige)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.title3)
                    .foregroundColor(.appBeige.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 30)
                
            } else {
                // GIF preview
                if let gifName = page.gifName {
                    GifImageView(gifName: gifName)
                        .frame(height: 300)
                        .cornerRadius(20)
                        .padding(.horizontal, 30)
                } else {
                    // Fallback to icon placeholder
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appDarkBlue.opacity(0.3))
                        .frame(height: 250)
                        .overlay(
                            VStack {
                                Image(systemName: page.imageName)
                                    .font(.system(size: 50))
                                    .foregroundColor(.appLightBlue)
                                
                                Text("Demo Preview")
                                    .font(.caption)
                                    .foregroundColor(.appBeige.opacity(0.6))
                                    .padding(.top, 10)
                            }
                        )
                        .padding(.horizontal, 30)
                }
                
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appBeige)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.appBeige.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 30)
                
                if let features = page.features {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(features, id: \.self) { feature in
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.appLightBlue)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 50)
    }
}

// MARK: - GIF Image View
struct GifImageView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let gifPath = Bundle.main.path(forResource: gifName, ofType: "gif"),
              let gifData = NSData(contentsOfFile: gifPath) else {
            print("GIF file not found: \(gifName).gif")
            loadFallbackContent(in: uiView)
            return
        }
        
        uiView.load(gifData as Data, mimeType: "image/gif", characterEncodingName: "", baseURL: URL(fileURLWithPath: gifPath))
    }
    
    private func loadFallbackContent(in webView: WKWebView) {
        let html = """
        <html>
        <body style="margin:0; padding:20px; background-color:transparent; display:flex; justify-content:center; align-items:center; height:100vh;">
            <div style="text-align:center; color:#999;">
                <div style="font-size:48px;">📱</div>
                <div style="margin-top:10px; font-size:14px;">Demo non disponibile</div>
            </div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
