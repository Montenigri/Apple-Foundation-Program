//
//  OnboardingView.swift
//  MyTime
//
//  Created by angelo galante on 27/06/25.
//

import SwiftUI
import WebKit

// 1. Struct usata nei dati della View
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

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    let onboardingPages = [
        OnboardingPage(
            title: "Welcome in MyTime",
            description: "Take back control of your time and optimize your free moments during the day according to your interests.",
            imageName: "logoCless", // Ora userà l'immagine da Assets
            gifName: nil,
            isWelcome: true
        ),
        OnboardingPage(
            title: "Organize your time",
            description: "In the MyTime screen, you will find the configured tasks and the suggested ones.",
            imageName: "calendar",
            gifName: "mytime"
        ),
        OnboardingPage(
            title: "Add new task",
            description: "Tap the '+' button at the top right to add new tasks.",
            imageName: "plus.circle.fill",
            gifName: "addTaskGif"
        ),

        OnboardingPage(
            title: "Track your progress",
            description: "Tap the icon at the top right in the MyTimeView to track your monthly and weekly progress.",
            imageName: "person.circle.fill",
            gifName: "progressGif"
        ),

        OnboardingPage(
            title: "Manage interests",
            description: "View, add, or remove saved interests",
            imageName: "list.bullet.circle.fill",
            gifName: "interestGif"
        )
    ]

    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        hasSeenOnboarding = true
                    }) {
                        HStack(spacing: 4) {
                            Text("Skip")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.appBeige)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.appBlack.opacity(0.9))
                        .cornerRadius(20)
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }

                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .padding(.top, 30)

                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.appBeige)
                    }

                    Spacer()

                    Button(action: {
                        if currentPage < onboardingPages.count - 1 {
                            currentPage += 1
                        } else {
                            hasSeenOnboarding = true
                        }
                    }) {
                        Text(currentPage < onboardingPages.count - 1 ? "Next" : "Start")
                            .font(.headline)
                            .foregroundColor(.appBlack)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: currentPage < onboardingPages.count - 1
                                                       ? [Color.appBeige, Color.appBeige.opacity(0.8)]
                                                       : [Color.appBeigeStrong, Color.appBeigeStrong.opacity(0.9)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            )
                    }

                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Spazio iniziale ridotto
                Spacer()
                    .frame(height: 20)
                
                // Titolo e descrizione in alto
                VStack(spacing: 15) {
                    Text(page.title)
                        .font(.largeTitle) // Font più grande per maggiore impatto
                        .fontWeight(.bold)
                        .foregroundColor(.appBeige)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 25)

                    Text(page.description)
                        .font(.title2) // Font grande e leggibile
                        .fontWeight(.medium)
                        .foregroundColor(.appBeige)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 20)
                }
                
                // Contenuto multimediale (GIF o immagine)
                Group {
                    if let gifName = page.gifName {
                        GifImageView(gifName: gifName)
                            .frame(height: 280) // Altezza ridotta per lasciare spazio ai testi
                            .cornerRadius(20)
                            .padding(.horizontal, 25)
                    } else {
                        // Controlla se è un SF Symbol o un'immagine custom
                        if page.imageName.contains(".") {
                            // SF Symbol (contiene un punto come "clock.fill")
                            Image(systemName: page.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.appLightBlue)
                        } else {
                            // Immagine da Assets
                            Image(page.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                        }
                    }
                }
                .padding(.top, 10)

                // Features se presenti
                if let features = page.features {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.self) { feature in
                            Text("• \(feature)")
                                .font(.body)
                                .foregroundColor(.appLightBlue)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                }
                
                // Spazio finale per evitare sovrapposizioni con i bottoni
                Spacer()
                    .frame(height: 60)
            }
        }
        .scrollIndicators(.hidden) // Nasconde gli indicatori di scroll per un look più pulito
    }
}

struct GifImageView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let gifPath = Bundle.main.path(forResource: gifName, ofType: "gif"),
              let gifData = NSData(contentsOfFile: gifPath) else {
            loadFallbackContent(in: uiView)
            return
        }

        uiView.load(gifData as Data,
                    mimeType: "image/gif",
                    characterEncodingName: "",
                    baseURL: URL(fileURLWithPath: gifPath))
    }

    private func loadFallbackContent(in webView: WKWebView) {
        let html = """
        <html>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
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
