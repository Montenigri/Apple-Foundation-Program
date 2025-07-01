# Documentazione Tecnica - MyTime

## Descrizione Generale
MyTime è un'applicazione SwiftUI per la pianificazione giornaliera e settimanale, che integra task utente e suggerimenti automatici basati su preferenze, slot liberi, sonno e lavoro.

---

## Architettura Principale

- **MVVM (Model-View-ViewModel)**: Separazione tra logica dati (Model), logica di presentazione (ViewModel) e interfaccia utente (View).
- **Persistenza**: UserDefaults per task, interessi e profilo utente.
- **Notifiche**: Utilizzo di UserNotifications per reminder pre e post task.

---

## Componenti Principali

### Models
- **Task**: Rappresenta un'attività (nome, descrizione, durata, orario, luogo, flag suggerito, completato).
- **Interest**: Preferenze utente per suggerimenti (nome, durata, fascia oraria, livello preferenza).
- **UserProfile**: Dati utente (orari sonno/lavoro, task completati, ore totali).

### ViewModels
- **TaskManager**: Gestisce task, suggerimenti, interessi e profilo. Si occupa di:
  - Generazione suggerimenti per slot liberi (tra sonno, lavoro e altri task) nei prossimi 3 giorni.
  - Aggiornamento suggerimenti solo per il giorno modificato quando si aggiunge/rimuove un task.
  - Persistenza dati e gestione notifiche.

### Views
- **MyTimeView**: Mostra la pianificazione giornaliera/settimanale, con header dinamici e gestione scroll.
- **AddTaskView**: Form per aggiunta task, con validazione conflitti e selezione durata.
- **TaskDetailView**: Dettaglio e completamento task.
- **Altre View**: Gestione interessi, profilo, slider custom, ecc.

---

## Logica Suggerimenti

- Gli slot liberi vengono calcolati escludendo periodi di sonno, lavoro e altri task utente.
- I suggerimenti vengono generati in base a:
  - Preferenza utente (ordinamento decrescente)
  - Fascia oraria (morning, afternoon, evening)
  - Durata compatibile con lo slot
- Quando si aggiunge/rimuove un task, solo i suggerimenti del giorno interessato vengono ricalcolati.
- I suggerimenti riempiono tutti gli slot liberi, anche se ci sono già task utente.

---

## Persistenza Dati

- **UserDefaults**: Serializzazione JSON di task, interessi e profilo.
- **Caricamento**: All'avvio, i dati vengono caricati e pubblicati tramite @Published.

---

## Notifiche

- Reminder 5 minuti prima dell'inizio di ogni task.
- Reminder 10 minuti dopo la fine per confermare il completamento.

---

## UI/UX

- **Font**: SF Pro (di sistema)
- **Colori**: Palette custom tramite estensione Color+Hex
- **Layout**: Lista giorni sempre visibile, header mese dinamico, task list espansa senza scroll interno, barra orizzontale spessa tra orario e task.

---

## Estendibilità

- Possibilità di aggiungere nuove fasce orarie, logiche di suggerimento, font, temi e sistemi di persistenza più avanzati (CoreData, CloudKit).

---

## File Principali
- `TaskManager.swift`: Logica centrale di gestione task e suggerimenti
- `Task.swift`, `Interest.swift`, `UserProfile.swift`: Modelli dati
- `MyTimeView.swift`, `AddTaskView.swift`, `TaskDetailView.swift`: Interfaccia utente
- `Color+Hex.swift`: Estensione colori custom

---

## Autori
- Gabriele Musso
- Angelo Galante
- Flavia La Mantia
- Marialessandra Picone

---

## Ultimo Aggiornamento
Luglio 2025
