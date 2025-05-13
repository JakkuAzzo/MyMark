import SwiftUI
import PhotosUI
import AVFoundation
import UserNotifications

struct ContentView: View {
    @State private var loggedIn = false
    @State private var showSignUp = false
    @State private var loggedInUsername: String = ""

    var body: some View {
        ZStack {
            Color(.systemGray5).ignoresSafeArea()
            GeometryReader { geo in
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(geo.size.width, geo.size.height) * 0.7)
                    .opacity(0.10)
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                    .ignoresSafeArea() // Ensure background image is always visible
            }
            if loggedIn {
                TabView {
                    StatsView()
                        .tabItem {
                            Label("Stats", systemImage: "cube.fill")
                        }
                    MatchesCarouselView(username: loggedInUsername)
                        .tabItem {
                            Label("Matches", systemImage: "cube.transparent.fill")
                        }
                    UploadView()
                        .tabItem {
                            Label("Upload", systemImage: "square.and.arrow.up.fill")
                        }
                }
                .accentColor(.blue)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Logout") { loggedIn = false }
                    }
                }
            } else {
                GeometryReader { geo in
                    VStack {
                        Spacer()
                        Group {
                            if showSignUp {
                                SignUpView(
                                    onSignUp: { username in
                                        loggedInUsername = username
                                        loggedIn = true
                                    },
                                    onSwitchToLogin: { showSignUp = false }
                                )
                            } else {
                                LoginView(
                                    onLogin: { username in
                                        loggedInUsername = username
                                        loggedIn = true
                                    },
                                    onSwitchToSignUp: { showSignUp = true }
                                )
                            }
                        }
                        .frame(maxWidth: 400)
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color(.darkGray), lineWidth: 4)
                                )
                        )
                        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
}

// MARK: - LoginView

struct LoginView: View {
    var onLogin: (String)->Void
    var onSwitchToSignUp: ()->Void
    @State private var username = ""
    @State private var faceImage: UIImage?
    @State private var catchphraseURL: URL?
    @State private var catchphraseName: String = ""
    @State private var error: String?
    @State private var loading = false
    @FocusState private var focusedField: Field?
    @State private var showImagePicker = false
    @State private var showAudioRecorder = false

    enum Field {
        case username
    }

    var body: some View {
        VStack(spacing: 22) {
            Text("Login to MyMark")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .padding(.bottom, 2)

            CubicTextField("Username", text: $username)
                .focused($focusedField, equals: .username)
                .submitLabel(.go)
                .onSubmit { login() }

            CubicImageButton(
                image: faceImage,
                label: faceImage == nil ? "Select Face Image" : "Face Image Selected",
                icon: faceImage == nil ? "faceid" : "checkmark.seal.fill",
                onTap: { showImagePicker = true }
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $faceImage)
            }

            CubicAudioButton(
                url: $catchphraseURL,
                name: $catchphraseName,
                label: "Catchphrase (optional)",
                onTap: { showAudioRecorder = true }
            )
            .sheet(isPresented: $showAudioRecorder) {
                AudioRecorderModal(url: $catchphraseURL, name: $catchphraseName)
            }

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }
            Button("Login") {
                login()
            }
            .buttonStyle(CubicButtonStyle())
            .disabled(loading || username.isEmpty || faceImage == nil)
            if loading { ProgressView() }
            Button("Don't have an account? Sign Up") {
                onSwitchToSignUp()
            }
            .foregroundColor(.gray)
            .font(.callout)
            .padding(.top, 6)
        }
        .padding(.horizontal, 8)
        .onAppear { focusedField = .username }
    }

    private func login() {
        guard let faceImage = faceImage else {
            error = "Please select a face image"
            return
        }
        loading = true; error = nil
        // Demo: check local user store
        if DemoUserStore.shared.userExists(username: username, faceImage: faceImage) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loading = false
                onLogin(username)
            }
            return
        }
        // ...existing code for backend login (optional)...
        /*
        let faceBase64 = faceImage.jpegData(compressionQuality: 0.8)?.base64EncodedString() ?? ""
        var catchphraseData: String? = nil
        if let url = catchphraseURL, let data = try? Data(contentsOf: url) {
            catchphraseData = data.base64EncodedString()
        }
        guard let url = URL(string: "http://localhost:5000/api/login") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "username": username,
            "face": faceBase64
        ]
        if let catchphraseData = catchphraseData {
            body["catchphrase"] = catchphraseData
        }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, _, err in
            DispatchQueue.main.async {
                loading = false
                if let err = err { error = err.localizedDescription; return }
                guard let data = data,
                      let resp = try? JSONDecoder().decode(LoginResponse.self, from: data),
                      resp.success else {
                    error = "Invalid credentials or face"
                    return
                }
                onLogin(username)
            }
        }.resume()
        */
    }
}

// MARK: - SignUpView

struct SignUpView: View {
    var onSignUp: (String)->Void
    var onSwitchToLogin: ()->Void
    @State private var username = ""
    @State private var userIDImage: UIImage?
    @State private var faceImage: UIImage?
    @State private var catchphraseWords: [String] = []
    @State private var catchphraseRecordings: [URL?] = [nil, nil]
    @State private var catchphraseNames: [String] = ["", ""]
    @State private var error: String?
    @State private var loading = false
    @FocusState private var focusedField: Field?
    @State private var showIDPicker = false
    @State private var showFacePicker = false
    @State private var showAudioRecorderIndex: Int? = nil

    enum Field {
        case username
    }

    var body: some View {
        VStack(spacing: 28) {
            Text("Sign Up for MyMark")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.bottom, 2)

            CubicTextField("Username", text: $username)
                .focused($focusedField, equals: .username)
                .submitLabel(.go)
                .onSubmit { signUp() }

            CubicImageButton(
                image: userIDImage,
                label: userIDImage == nil ? "Select Image of ID" : "ID Image Selected",
                icon: userIDImage == nil ? "rectangle.and.photo" : "checkmark.seal.fill",
                onTap: { showIDPicker = true }
            )
            .sheet(isPresented: $showIDPicker) {
                ImagePicker(image: $userIDImage, allowCamera: false)
            }

            CubicImageButton(
                image: faceImage,
                label: faceImage == nil ? "Select Face Image" : "Face Image Selected",
                icon: faceImage == nil ? "faceid" : "checkmark.seal.fill",
                onTap: { showFacePicker = true }
            )
            .sheet(isPresented: $showFacePicker) {
                ImagePicker(image: $faceImage)
            }

            // Catchphrase: now optional
            VStack(spacing: 10) {
                HStack {
                    Text("Catchphrase (optional)").font(.headline)
                    Spacer()
                }
                if catchphraseWords.isEmpty {
                    Button("Generate Catchphrase") {
                        catchphraseWords = Self.generateCatchphrase()
                    }
                    .buttonStyle(CubicButtonStyle())
                } else {
                    Text(catchphraseWords.joined(separator: " "))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                    ForEach(0..<2, id: \.self) { idx in
                        CubicAudioButton(
                            url: $catchphraseRecordings[idx],
                            name: $catchphraseNames[idx],
                            label: "Record Catchphrase (\(idx+1)/2)",
                            onTap: { showAudioRecorderIndex = idx }
                        )
                        .sheet(isPresented: Binding(
                            get: { showAudioRecorderIndex == idx },
                            set: { newValue in if !newValue { showAudioRecorderIndex = nil } }
                        )) {
                            AudioRecorderModal(
                                url: Binding(
                                    get: { catchphraseRecordings[idx] },
                                    set: { catchphraseRecordings[idx] = $0 }
                                ),
                                name: Binding(
                                    get: { catchphraseNames[idx] },
                                    set: { catchphraseNames[idx] = $0 }
                                ),
                                words: catchphraseWords
                            )
                        }
                    }
                }
            }
            .padding(.top, 8)

            if let error = error {
                Text(error).foregroundColor(.red).font(.caption)
            }
            Button("Sign Up") {
                signUp()
            }
            .buttonStyle(CubicButtonStyle())
            .disabled(
                loading ||
                username.isEmpty ||
                userIDImage == nil ||
                faceImage == nil
            )
            if loading { ProgressView() }
            Button("Already have an account? Login") {
                onSwitchToLogin()
            }
            .foregroundColor(.gray)
            .font(.callout)
            .padding(.top, 6)
        }
        .padding(.horizontal, 8)
        .onAppear {
            focusedField = .username
            if catchphraseWords.isEmpty {
                catchphraseWords = []
                catchphraseRecordings = [nil, nil]
                catchphraseNames = ["", ""]
            }
        }
    }

    private func signUp() {
        guard let faceImage = faceImage else {
            error = "Please select a face image"
            return
        }
        // Remove unused variable userIDImage if not used elsewhere
        if userIDImage == nil {
            error = "Please select an image of your ID"
            return
        }
        // Catchphrase is now optional, so no check for catchphraseWords or recordings
        loading = true; error = nil
        DemoUserStore.shared.saveUser(username: username, faceImage: faceImage)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loading = false
            onSignUp(username)
        }
    }

    static func generateCatchphrase() -> [String] {
        let words = [
            "apple", "river", "mask", "cube", "future", "shadow", "light", "echo", "storm", "cloud",
            "stone", "mirror", "pulse", "signal", "dream", "night", "code", "spark", "wave", "core"
        ]
        return (0..<3).map { _ in words.randomElement()! }
    }
}

// MARK: - Cubic Components

struct CubicTextField: View {
    let placeholder: String
    @Binding var text: String
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray3), lineWidth: 2))
            .font(.system(size: 18, weight: .medium, design: .rounded))
    }
}

struct CubicImageButton: View {
    let image: UIImage?
    let label: String
    let icon: String
    let onTap: ()->Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(image == nil ? .gray : .green)
                Text(label)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray3), lineWidth: 2))
            .font(.system(size: 18, weight: .medium, design: .rounded))
        }
    }
}

struct CubicAudioButton: View {
    @Binding var url: URL?
    @Binding var name: String
    let label: String
    let onTap: ()->Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: url == nil ? "waveform.circle" : "checkmark.seal.fill")
                    .foregroundColor(url == nil ? .gray : .green)
                Text(url == nil ? label : (name.isEmpty ? "Audio Selected" : name))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray3), lineWidth: 2))
            .font(.system(size: 18, weight: .medium, design: .rounded))
        }
    }
}

// MARK: - Cubic Button Style

struct CubicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color(.darkGray) : Color.black)
            .foregroundColor(.white)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var allowCamera: Bool = false
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIViewController {
        if allowCamera, UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            picker.mediaTypes = ["public.image"]
            return picker
        } else {
            var config = PHPickerConfiguration()
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    class Coordinator: NSObject, PHPickerViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async { self.parent.image = image as? UIImage }
            }
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let img = info[.originalImage] as? UIImage {
                self.parent.image = img
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Audio Recorder Modal (with playback)

struct AudioRecorderModal: View {
    @Environment(\.dismiss) var dismiss
    @Binding var url: URL?
    @Binding var name: String
    var words: [String] = []

    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var audioPlayerDelegate: AudioRecorderModalDelegate?

    var body: some View {
        VStack(spacing: 24) {
            Text("Record Catchphrase")
                .font(.title2).bold()
            if !words.isEmpty {
                Text(words.joined(separator: " "))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            if isRecording {
                Text("Recording...").foregroundColor(.red)
            }
            Button(isRecording ? "Stop Recording" : "Start Recording") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
            .buttonStyle(CubicButtonStyle())
            if url != nil {
                Text("Audio ready: \(name)").font(.caption)
                HStack(spacing: 16) {
                    Button(isPlaying ? "Stop Playback" : "Play Recording") {
                        if isPlaying {
                            stopPlayback()
                        } else {
                            playRecording()
                        }
                    }
                    .buttonStyle(CubicButtonStyle())
                }
                Button("Use This Audio") {
                    stopPlayback()
                    dismiss()
                }
                .buttonStyle(CubicButtonStyle())
            }
            Button("Cancel") {
                stopPlayback()
                dismiss()
            }
            .foregroundColor(.gray)
        }
        .padding()
        .onDisappear {
            if isRecording { stopRecording() }
            stopPlayback()
        }
    }

    private func startRecording() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            url = audioFilename
            name = audioFilename.lastPathComponent
        } catch {
            isRecording = false
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
    }

    private func playRecording() {
        guard let url = url else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            let delegate = AudioRecorderModalDelegate { isPlaying = false }
            audioPlayer?.delegate = delegate
            audioPlayerDelegate = delegate // retain delegate
            audioPlayer?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        audioPlayerDelegate = nil
    }
}

// Replace AVPlayerDelegateBridge with a class that is retained:

class AudioRecorderModalDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: - Demo User Storage

struct DemoUser: Codable, Equatable {
    let username: String
    let faceImageHash: String
}

class DemoUserStore {
    static let shared = DemoUserStore()
    private let fileURL: URL

    private init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = dir.appendingPathComponent("demo_users.json")
    }

    func saveUser(username: String, faceImage: UIImage) {
        var users = loadUsers()
        let hash = Self.imageHash(faceImage)
        let user = DemoUser(username: username, faceImageHash: hash)
        if !users.contains(user) {
            users.append(user)
            if let data = try? JSONEncoder().encode(users) {
                try? data.write(to: fileURL)
            }
        }
    }

    func userExists(username: String, faceImage: UIImage) -> Bool {
        let users = loadUsers()
        let hash = Self.imageHash(faceImage)
        return users.contains(where: { $0.username == username && $0.faceImageHash == hash })
    }

    private func loadUsers() -> [DemoUser] {
        guard let data = try? Data(contentsOf: fileURL),
              let users = try? JSONDecoder().decode([DemoUser].self, from: data) else {
            return []
        }
        return users
    }

    private static func imageHash(_ image: UIImage) -> String {
        // Simple hash: base64 of jpeg data (truncated)
        let data = image.jpegData(compressionQuality: 0.7) ?? Data()
        return data.base64EncodedString().prefix(32).description
    }
}

struct LoginResponse: Decodable {
    let success: Bool
}
