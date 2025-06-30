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
            title: "Benvenuto in MyTime",
            description: "Recupera il controllo del tuo tempo e ottimizza i momenti liberi della giornata in base ai tuoi interessi.",
            imageName: "logoCless", // Ora userà l'immagine da Assets
            gifName: nil,
            isWelcome: true
        ),
        OnboardingPage(
            title: "Organizza il tuo tempo",
            description: "Nella schermata MyTime troverai i task configurati e quelli suggeriti.",
            imageName: "calendar",
            gifName: "mytime"
        ),
        OnboardingPage(
            title: "Aggiungi nuovi task",
            description: "Tocca il pulsante '+' in alto a destra per aggiungere nuovi task.",
            imageName: "plus.circle.fill",
            gifName: "addTaskGif"
        ),

        OnboardingPage(
            title: "Monitora i tuoi progressi",
            description: "Tocca l'icona in alto a destra nella MyTimeView per monitorare i progressi mensili e settimanali.",
            imageName: "person.circle.fill",
            gifName: "progressGif"
        ),

        OnboardingPage(
            title: "Gestisci interessi",
            description: "Visualizza, aggiungi o rimuovi interessi registrati",
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
                            Text("Salta")
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
                        Button("Indietro") {
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
                        Text(currentPage < onboardingPages.count - 1 ? "Avanti" : "Inizia")
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
        VStack {
            Spacer(minLength: 40)

            Group {
                if let gifName = page.gifName {
                    GifImageView(gifName: gifName)
                        .frame(height: 250)
                        .cornerRadius(20)
                        .padding(.horizontal, 30)
                } else {
                    // Controlla se è un SF Symbol o un'immagine custom
                    if page.imageName.contains(".") {
                        // SF Symbol (contiene un punto come "clock.fill")
                        Image(systemName: page.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.appLightBlue)
                            .padding(.bottom, 10)
                    } else {
                        // Immagine da Assets (senza punto come "logo")
                        Image(page.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding(.bottom, 10)
                    }
                }
            }

            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.appBeige)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 30)

            Text(page.description)
                .font(.body)
                .foregroundColor(.appBeige.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 30)

            if let features = page.features {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        Text("• \(feature)")
                            .font(.subheadline)
                            .foregroundColor(.appLightBlue)
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 30)
            }

            Spacer()
        }
        .padding(.vertical, 30)
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
