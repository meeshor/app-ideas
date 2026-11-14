import SwiftUI
import WristKit

/// Ekran debug czujników: połączenie, podgląd na żywo, nagrania, opóźnienie.
struct SensorLabView: View {
    @Bindable var model: SensorLabModel

    var body: some View {
        List {
            connectionSection
            liveSection
            recordingSection
            latencySection
            recordingsSection
        }
        .navigationTitle("Czujniki")
        .onAppear { model.activate() }
    }

    // MARK: - Sekcje

    private var connectionSection: some View {
        Section("Połączenie") {
            LabeledContent("Zegarek sparowany", value: model.isPaired ? "tak" : "nie")
            LabeledContent("Apka na zegarku", value: model.isWatchAppInstalled ? "zainstalowana" : "brak")
            LabeledContent("Osiągalny", value: model.isReachable ? "tak" : "nie")
            if let status = model.watchStatus {
                LabeledContent("Nadgarstek", value: status.wrist == .left ? "lewy" : "prawy")
                LabeledContent("Sesja treningu", value: status.workoutActive ? "aktywna" : "nie")
                if let error = status.lastError {
                    Text("Zegarek: \(error)").font(.caption).foregroundStyle(.red)
                }
            }
            if let error = model.errorMessage {
                Text(error).font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private var liveSection: some View {
        Section("Podgląd na żywo (25 Hz)") {
            Button(model.isStreaming ? "Zatrzymaj podgląd" : "Start podglądu") {
                model.toggleStreaming()
            }
            if !model.live.isEmpty {
                let samples = model.live.elements
                MotionChart(samples: samples, series: MotionSeries.magnitudes, relativeToEnd: true)
                MotionChart(samples: samples, series: MotionSeries.attitude, relativeToEnd: true)
            }
        }
    }

    private var recordingSection: some View {
        Section {
            TextField("Etykieta, np. flick_center_01", text: $model.recordingLabel)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            let isRecording = model.watchStatus?.isRecording ?? false
            Button(isRecording ? "Zatrzymaj nagrywanie" : "Nagrywaj na zegarku") {
                model.toggleRecording()
            }
            .tint(isRecording ? .red : .accentColor)
            if let status = model.watchStatus, status.isRecording {
                Text("\(status.sampleCount) próbek · \(status.recordingDuration, format: .number.precision(.fractionLength(1))) s")
                    .font(.caption.monospacedDigit())
            }
        } header: {
            Text("Nagrywanie")
        } footer: {
            Text("Nagranie zapisuje się na zegarku i samo przesyła na telefon (lista niżej).")
        }
    }

    private var latencySection: some View {
        Section {
            Button(model.isMeasuring ? "Mierzę…" : "Zmierz opóźnienie (30 pingów)") {
                Task { await model.measureLatency() }
            }
            .disabled(model.isMeasuring)
            latencyRow("RTT ping-pong", model.rttSummary)
            latencyRow("Transport", model.transportSummary)
            latencyRow("Wiek próbki", model.sampleAgeSummary)
            LabeledContent("Wiadomości / zgubione", value: "\(model.receivedMessages) / \(model.lostMessages)")
            HStack {
                Button("Kopiuj raport") { model.copyLatencyReport() }
                Spacer()
                Button("Wyzeruj", role: .destructive) { model.resetLatency() }
            }
            .buttonStyle(.borderless)
        } header: {
            Text("Opóźnienie")
        } footer: {
            Text("Najpierw zmierz RTT (synchronizacja zegarów), potem włącz podgląd: wtedy liczy się też transport w jedną stronę.")
        }
    }

    private var recordingsSection: some View {
        Section("Nagrania (\(model.recordings.count))") {
            ForEach(model.recordings) { entry in
                NavigationLink {
                    RecordingDetailView(entry: entry, recording: model.load(entry))
                } label: {
                    VStack(alignment: .leading) {
                        Text(entry.name).font(.subheadline)
                        Text("\(entry.modified.formatted(date: .abbreviated, time: .shortened)) · \(entry.size / 1024) KB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                model.delete(offsets.map { model.recordings[$0] })
            }
        }
    }

    private func latencyRow(_ title: String, _ summary: LatencySummary?) -> some View {
        LabeledContent(title) {
            if let summary {
                Text("med \(Int(summary.median * 1000)) ms · p90 \(Int(summary.p90 * 1000)) ms · n=\(summary.count)")
                    .font(.caption.monospacedDigit())
            } else {
                Text("—")
            }
        }
    }
}

/// Szczegóły nagrania: wykresy i eksport.
struct RecordingDetailView: View {
    let entry: RecordingStore.Entry
    let recording: MotionRecording?

    var body: some View {
        List {
            if let recording {
                Section("Metadane") {
                    LabeledContent("Etykieta", value: recording.metadata.label)
                    LabeledContent("Próbki", value: "\(recording.samples.count)")
                    LabeledContent("Czas", value: "\(String(format: "%.2f", recording.duration)) s")
                    LabeledContent("Nadgarstek", value: recording.metadata.wrist == .left ? "lewy" : "prawy")
                    LabeledContent("Urządzenie", value: recording.metadata.device)
                }
                Section("Moduły") {
                    MotionChart(samples: recording.samples, series: MotionSeries.magnitudes)
                }
                Section("Prędkość kątowa (osie)") {
                    MotionChart(samples: recording.samples, series: MotionSeries.rotationAxes)
                }
                Section("Orientacja") {
                    MotionChart(samples: recording.samples, series: MotionSeries.attitude)
                }
            } else {
                Text("Nie udało się wczytać nagrania.").foregroundStyle(.red)
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(item: entry.url) {
                Label("Eksportuj", systemImage: "square.and.arrow.up")
            }
        }
    }
}
