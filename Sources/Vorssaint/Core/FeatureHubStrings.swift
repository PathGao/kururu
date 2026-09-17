// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for the Features hub and its permissions portal. Same contract as
/// the other FeatureStrings structs: memberwise init with labeled arguments
/// in declaration order, one static per language, all in this file.
struct FeatureHubStrings {
    // Page chrome
    var pageTitle: String = "Features"
    var intro: String = "Enable the modules you need. Background behavior and shortcuts follow their saved settings. Enabling a module does not turn on every behavior. Adjust those switches in each module’s settings."
    var tabFeatures: String = "Features"
    var tabPermissions: String = "Permissions"
    var activeCountFormat: String = "%1$d of %2$d modules enabled"      // "%1$d of %2$d features on"
    var monitorAllOffNote: String = "With everything off, the Monitor leaves the panel and the menu bar."
    var titleMouseNavigation: String = "Side buttons"
    // Group headers
    var groupMonitor: String = "System monitor"
    var groupWindowsDesktop: String = "Windows and desktop"
    var groupInputDevices: String = "Input devices"
    var groupGlobalEntry: String = "Global entry points"
    var groupClipboardFiles: String = "Clipboard and files"
    var groupCapture: String = "Capture and content"
    var groupSoundDevices: String = "Sound and devices"
    var groupFocusEnergy: String = "Focus and energy"
    var groupAppManagement: String = "App management"
    // Permissions portal
    var permissionsIntro: String = "What each permission does and which features use it. Other access is requested only when you use it."
    var usedByFormat: String = "Used by %@"           // "Used by %@"
    var usedByNone: String = "Nothing that is on uses this permission right now."
    var unusedBanner: String = "You granted this permission, but nothing that is on needs it. If you like, revoke it in System Settings."
    var statusGranted: String = "Granted"
    var statusMissing: String = "Not granted"
    var statusUnknown: String = "The app can’t check this one"
    var requestButton: String = "Request"
    var openSystemSettings: String = "Open System Settings"
    var permAccessibility: String = "Accessibility"
    var permScreenRecording: String = "Screen Recording"
    var permFullDisk: String = "Full Disk Access"
    var permFilesAndFolders: String = "Files & Folders"
    var permNotifications: String = "Notifications"
    var permAutomationFinder: String = "Finder automation"
    var permAutomationTerminal: String = "Terminal automation"
    var permAudioCapture: String = "App audio"
    var explainAccessibility: String = "Lets features react to clicks and keys, and move windows."
    var explainScreenRecording: String = "Lets features show window thumbnails and read text on screen."
    var explainFullDisk: String = "Lets the cleaner and the uninstaller find leftover files everywhere."
    var explainFilesAndFolders: String = "Lets WhatsApp downloads cleanup and the experimental organizer inspect your Downloads folder."
    var explainNotifications: String = "Lets the app notify you about alerts you turned on."
    var explainAutomationFinder: String = "Lets the app ask Finder to move files for you."
    var explainAutomationTerminal: String = "Lets Homebrew commands open in Terminal."
    var explainAudioCapture: String = "Lets the mixer adjust each app’s volume and screen recordings include the Mac’s sound."
    // One-line feature descriptions
    var descSwitcher: String = "Switch apps and windows with previews"
    var descDockPreview: String = "Window previews when hovering the Dock"
    var descDockClick: String = "Click a Dock icon to minimize or cycle windows"
    var descWindowMaximizer: String = "The green button maximizes instead of full screen"
    var descAutoQuit: String = "Quit apps when their last window closes"
    var descScrollInverter: String = "Invert the mouse wheel direction"
    var descSmoothScroll: String = "Smooth, animated mouse scrolling"
    var descMouseNavigation: String = "Side mouse buttons go back and forward"
    var descMiddleClick: String = "Three finger click acts as a middle click"
    var descKeyboardDebounce: String = "Ignore accidental double key presses"
    var descClipboardHistory: String = "Keep a local history of what you copy"
    var descPastePlain: String = "Paste text without formatting"
    var descFinderCutPaste: String = "Cut and paste files in Finder"
    var descShelf: String = "Drop files on the menu bar to hold them"
    var descURLCleaner: String = "Copied links lose their tracking junk"
    var descMixer: String = "A volume slider for each app"
    var descSoundOutputSwitcher: String = "Cycle sound outputs with a shortcut"
    var descMicMute: String = "Mute the microphone from anywhere"
    var descMusicBlock: String = "Block selected app launches after media keys"
    var descKeepAwake: String = "Keep the Mac awake on demand"
    var descColorPicker: String = "Pick any color on screen"
    var descScreenOCR: String = "Copy text or QR codes from anything on screen"
    var descCleaningMode: String = "Lock keyboard and screen for cleaning"
    var descMediaTools: String = "Convert media and merge PDF files"
    var descCleaner: String = "Clear caches and junk files"
    var descUninstaller: String = "Remove apps and their leftovers"
    var descHomebrew: String = "Keep Homebrew packages up to date"
    var descMonitorCPU: String = "Processor usage and temperature"
    var descMonitorGPU: String = "Graphics usage and temperature"
    var descMonitorMemory: String = "Memory use and pressure"
    var descMonitorNetwork: String = "Network speed and usage"
    var descMonitorDisk: String = "Disk space and activity"
    var descMonitorPower: String = "Battery, power and charging"
    // Availability controls and the restart-to-unload card
    var installButton: String = "Enable"
    var uninstallButton: String = "Disable"
    var footerNote: String = "Disabling a module stops its background behavior and shortcuts and keeps its data and preferences. Saved behavior settings and key combinations remain readable here. Enable it again to edit all settings."
    var restartNote: String = "Disabled modules may still hold resources in memory. Restart the app to release them."
    var restartButton: String = "Restart now"
    var installAllButton: String = "Enable all"
    var uninstallAllButton: String = "Disable all"
    var energyIdle: String = "Nothing at rest"
    var energyMouse: String = "Listens to the mouse"
    var energyPointer: String = "Listens to pointer input"
    var energyKeyboard: String = "Listens to the keyboard"
    var energyInputs: String = "Listens to mouse and keyboard"
    var energyPeriodic: String = "Checks on an interval"
    var energyHelp: String = "Background activity while the feature is running. Disabled features do not run."
    var explainAppManagement: String = "Lets updates replace or remove apps installed by the package manager."
    var onboardingSelectedPermissionsTitle: String = "Permissions for your choices"
    var onboardingNoSelectedPermissions: String = "You do not need to grant any permission to finish setup."
    var onboardingOtherPermissionsTitle: String = "Other permissions"
    var onboardingOtherPermissionsCaption: String = "Optional. Grant these now or later, when a feature needs them."
}

extension FeatureStrings {
    static func hub(_ language: AppLanguage) -> FeatureHubStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension FeatureHubStrings {
    static let ko = FeatureHubStrings(
        pageTitle: "기능",
        intro: "작업 공간에 추가할 도구를 선택하세요. 제거한 도구는 실행을 멈추고 실행 항목이 숨겨집니다. 저장된 설정은 유지되며 기능에서 요약을 확인할 수 있습니다.",
        tabFeatures: "기능",
        tabPermissions: "권한",
        activeCountFormat: "기능 %1$d개 / %2$d개 설치됨",
        monitorAllOffNote: "모두 끄면 모니터가 패널과 메뉴 막대에서 사라집니다.",
        titleMouseNavigation: "사이드 버튼",
        groupMonitor: "시스템 모니터",
        groupWindowsDesktop: "윈도우 및 데스크탑",
        groupInputDevices: "입력 장치",
        groupGlobalEntry: "전역 진입점",
        groupClipboardFiles: "클립보드 및 파일",
        groupCapture: "캡처 및 콘텐츠",
        groupSoundDevices: "사운드 및 기기",
        groupFocusEnergy: "집중 및 에너지",
        groupAppManagement: "앱 관리",
        permissionsIntro: "각 권한의 용도와 사용하는 기능을 확인하세요. 다른 접근 권한은 해당 기능을 사용할 때만 요청합니다.",
        usedByFormat: "사용 중: %@",
        usedByNone: "현재 켜진 기능 중 이 권한을 사용하는 기능이 없습니다.",
        unusedBanner: "이 권한을 허용했지만 현재 켠 기능은 필요로 하지 않습니다. 원한다면 시스템 설정에서 취소할 수 있습니다.",
        statusGranted: "허용됨",
        statusMissing: "허용되지 않음",
        statusUnknown: "앱에서 이 권한은 확인할 수 없습니다",
        requestButton: "요청",
        openSystemSettings: "시스템 설정 열기",
        permAccessibility: "손쉬운 사용",
        permScreenRecording: "화면 녹화",
        permFullDisk: "전체 디스크 접근",
        permFilesAndFolders: "파일 및 폴더",
        permNotifications: "알림",
        permAutomationFinder: "Finder 자동화",
        permAutomationTerminal: "Terminal 자동화",
        permAudioCapture: "앱 오디오",
        explainAccessibility: "기능이 클릭과 키 입력에 반응하고 윈도우를 이동할 수 있게 합니다.",
        explainScreenRecording: "기능이 윈도우 썸네일을 표시하고 화면의 텍스트를 읽을 수 있게 합니다.",
        explainFullDisk: "정리기와 앱 제거기가 어디서나 남은 파일을 찾을 수 있게 합니다.",
        explainFilesAndFolders: "WhatsApp 다운로드 정리 및 실험적 구성 기능이 다운로드 폴더를 확인할 수 있게 합니다.",
        explainNotifications: "켜 둔 경고를 앱에서 알릴 수 있게 합니다.",
        explainAutomationFinder: "앱이 Finder에 파일 이동을 요청할 수 있게 합니다.",
        explainAutomationTerminal: "Homebrew 명령을 Terminal에서 열 수 있게 합니다.",
        explainAudioCapture: "믹서가 앱별 볼륨을 조절하고 화면 기록에 Mac의 소리를 담을 수 있게 합니다.",
        descSwitcher: "미리보기로 앱과 윈도우 전환",
        descDockPreview: "Dock에 포인터를 올리면 윈도우 미리보기",
        descDockClick: "Dock 아이콘 클릭으로 최소화 또는 윈도우 전환",
        descWindowMaximizer: "초록색 버튼으로 전체 화면 대신 최대화",
        descAutoQuit: "마지막 윈도우를 닫으면 앱 종료",
        descScrollInverter: "마우스 휠 방향 반전",
        descSmoothScroll: "부드러운 애니메이션 마우스 스크롤",
        descMouseNavigation: "마우스 사이드 버튼으로 뒤로 및 앞으로 이동",
        descMiddleClick: "세 손가락 클릭을 가운데 클릭으로 사용",
        descKeyboardDebounce: "실수로 누른 중복 키 입력 무시",
        descClipboardHistory: "복사한 내용의 로컬 기록 보관",
        descPastePlain: "서식 없이 텍스트 붙여넣기",
        descFinderCutPaste: "Finder에서 파일 잘라내기 및 붙여넣기",
        descShelf: "파일을 메뉴 막대에 놓아 보관",
        descURLCleaner: "복사한 링크에서 추적 요소 제거",
        descMixer: "앱별 볼륨 슬라이더",
        descSoundOutputSwitcher: "단축키로 사운드 출력 순환",
        descMicMute: "어디서나 마이크 음소거",
        descKeepAwake: "필요할 때 Mac을 깨운 상태로 유지",
        descColorPicker: "화면의 모든 색상 선택",
        descScreenOCR: "화면의 모든 텍스트 또는 QR 코드 복사",
        descCleaningMode: "청소를 위해 키보드와 화면 잠금",
        descMediaTools: "동영상, 이미지 및 GIF 압축",
        descCleaner: "캐시와 정크 파일 정리",
        descUninstaller: "앱과 남은 파일 제거",
        descHomebrew: "Homebrew 패키지를 최신 상태로 유지",
        descMonitorCPU: "프로세서 사용량 및 온도",
        descMonitorGPU: "그래픽 사용량 및 온도",
        descMonitorMemory: "메모리 사용량 및 압력",
        descMonitorNetwork: "네트워크 속도 및 사용량",
        descMonitorDisk: "디스크 공간 및 활동",
        descMonitorPower: "배터리, 전원 및 충전",
        installButton: "설치",
        uninstallButton: "제거",
        footerNote: "제거해도 아무것도 삭제되지 않습니다. 기능이 앱에서 빠지고 더 이상 불러와지지 않을 뿐입니다. 언제든 다시 설치하면 이전처럼 모두 돌아옵니다.",
        restartNote: "이 세션에서 제거한 기능은 앱을 다시 시작할 때까지 불러온 상태로 남습니다. 지금 메모리에서 해제하려면 다시 시작하세요.",
        restartButton: "지금 다시 시작",
        installAllButton: "모두 설치",
        uninstallAllButton: "모두 제거",
        energyIdle: "대기 중에도 작업 없음",
        energyMouse: "마우스 감시",
        energyPointer: "포인터 입력 감지",
        energyKeyboard: "키보드 감시",
        energyInputs: "마우스와 키보드 감시",
        energyPeriodic: "일정 간격으로 확인",
        energyHelp: "기능이 켜져 있을 때 계속 유지하는 작업입니다. 제거한 기능은 전혀 불러오지 않습니다.",
        explainAppManagement: "업데이트가 패키지 관리자로 설치한 앱을 교체하거나 제거할 수 있게 합니다.",
        onboardingSelectedPermissionsTitle: "선택한 기능에 필요한 권한",
        onboardingNoSelectedPermissions: "설정을 마치는 데 필요한 권한이 없습니다.",
        onboardingOtherPermissionsTitle: "기타 권한",
        onboardingOtherPermissionsCaption: "선택 사항입니다. 기능에서 필요할 때 지금 또는 나중에 허용할 수 있습니다."
    )
}

extension FeatureHubStrings {
    static let enUS = FeatureHubStrings()

    static let ptBR = FeatureHubStrings(
        pageTitle: "Recursos",
        intro: "Escolha as ferramentas para adicionar ao espaço de trabalho. As ferramentas removidas param de funcionar e seus acessos ficam ocultos. As configurações salvas são mantidas, com um resumo disponível em Recursos.",
        tabFeatures: "Recursos",
        tabPermissions: "Permissões",
        activeCountFormat: "%1$d de %2$d recursos instalados",
        monitorAllOffNote: "Com tudo desligado, o Monitor some do painel e da barra de menus.",
        titleMouseNavigation: "Botões laterais",
        groupMonitor: "Monitor do sistema",
        groupWindowsDesktop: "Janelas e Mesa",
        groupInputDevices: "Dispositivos de entrada",
        groupGlobalEntry: "Pontos de entrada globais",
        groupClipboardFiles: "Área de transferência e arquivos",
        groupCapture: "Captura e conteúdo",
        groupSoundDevices: "Som e dispositivos",
        groupFocusEnergy: "Foco e energia",
        groupAppManagement: "Gestão de apps",
        permissionsIntro: "O que cada permissão faz e quais recursos usam cada uma. Outros acessos só são pedidos quando você os usa.",
        usedByFormat: "Usada por %@",
        usedByNone: "Nada que está ligado usa esta permissão agora.",
        unusedBanner: "Você concedeu esta permissão, mas nada que está ligado precisa dela. Se quiser, revogue nos Ajustes do Sistema.",
        statusGranted: "Concedida",
        statusMissing: "Não concedida",
        statusUnknown: "O app não consegue verificar esta",
        requestButton: "Solicitar",
        openSystemSettings: "Abrir Ajustes do Sistema",
        permAccessibility: "Acessibilidade",
        permScreenRecording: "Gravação de Tela",
        permFullDisk: "Acesso Total ao Disco",
        permFilesAndFolders: "Arquivos e Pastas",
        permNotifications: "Notificações",
        permAutomationFinder: "Automação do Finder",
        permAutomationTerminal: "Automação do Terminal",
        permAudioCapture: "Áudio dos apps",
        explainAccessibility: "Deixa os recursos reagirem a cliques e teclas e moverem janelas.",
        explainScreenRecording: "Deixa os recursos mostrarem miniaturas de janelas e lerem texto na tela.",
        explainFullDisk: "Deixa o limpador e o desinstalador acharem restos de arquivos em todo lugar.",
        explainFilesAndFolders: "Permite que a limpeza e o organizador experimental do WhatsApp verifiquem a pasta Downloads.",
        explainNotifications: "Deixa o app avisar você sobre os alertas que ligou.",
        explainAutomationFinder: "Deixa o app pedir ao Finder para mover arquivos por você.",
        explainAutomationTerminal: "Deixa os comandos do Homebrew abrirem no Terminal.",
        explainAudioCapture: "Deixa o mixer ajustar o volume de cada app e as gravações de tela incluírem o som do Mac.",
        descSwitcher: "Troque de app e janela com miniaturas",
        descDockPreview: "Miniaturas das janelas ao passar o mouse no Dock",
        descDockClick: "Clique no ícone do Dock para minimizar ou alternar",
        descWindowMaximizer: "O botão verde maximiza em vez de tela cheia",
        descAutoQuit: "Fecha o app quando a última janela fecha",
        descScrollInverter: "Inverte a direção da rodinha do mouse",
        descSmoothScroll: "Rolagem suave e animada do mouse",
        descMouseNavigation: "Botões laterais do mouse voltam e avançam",
        descMiddleClick: "Clique com três dedos vira clique do meio",
        descKeyboardDebounce: "Ignora teclas duplicadas sem querer",
        descClipboardHistory: "Guarda um histórico local do que você copia",
        descPastePlain: "Cole texto sem formatação",
        descFinderCutPaste: "Recorte e cole arquivos no Finder",
        descShelf: "Solte arquivos na barra de menus para segurar",
        descURLCleaner: "Links copiados perdem os rastreadores",
        descMixer: "Um controle de volume para cada app",
        descSoundOutputSwitcher: "Troque a saída de som com um atalho",
        descMicMute: "Silencie o microfone de qualquer lugar",
        descKeepAwake: "Mantenha o Mac acordado quando quiser",
        descColorPicker: "Capture qualquer cor da tela",
        descScreenOCR: "Copie texto ou QR codes de qualquer coisa na tela",
        descCleaningMode: "Trava teclado e tela para limpeza",
        descMediaTools: "Comprima vídeos, imagens e GIFs",
        descCleaner: "Limpe caches e arquivos inúteis",
        descUninstaller: "Remova apps e seus restos",
        descHomebrew: "Mantenha os pacotes do Homebrew em dia",
        descMonitorCPU: "Uso e temperatura do processador",
        descMonitorGPU: "Uso e temperatura dos gráficos",
        descMonitorMemory: "Uso e pressão de memória",
        descMonitorNetwork: "Velocidade e uso da rede",
        descMonitorDisk: "Espaço e atividade do disco",
        descMonitorPower: "Bateria, energia e carregamento",
        installButton: "Instalar",
        uninstallButton: "Desinstalar",
        footerNote: "Desinstalar não apaga nada: a feature só some do app e deixa de carregar. Instale de novo quando quiser e tudo volta como estava.",
        restartNote: "Features desinstaladas nesta sessão continuam carregadas até o app reiniciar. Reinicie para tirar tudo da memória agora.",
        restartButton: "Reiniciar agora",
        installAllButton: "Instalar tudo",
        uninstallAllButton: "Desinstalar tudo",
        energyIdle: "Nada em repouso",
        energyMouse: "Escuta o mouse",
        energyPointer: "Escuta o ponteiro",
        energyKeyboard: "Escuta o teclado",
        energyInputs: "Escuta mouse e teclado",
        energyPeriodic: "Verifica em intervalos",
        energyHelp: "O custo enquanto a função está ligada. Desinstalada, ela não carrega nada.",
        explainAppManagement: "Permite que as atualizações substituam ou removam apps instalados pelo gerenciador de pacotes.",
        onboardingSelectedPermissionsTitle: "Permissões para suas escolhas",
        onboardingNoSelectedPermissions: "Você não precisa conceder nenhuma permissão para concluir a configuração.",
        onboardingOtherPermissionsTitle: "Outras permissões",
        onboardingOtherPermissionsCaption: "Opcional. Você pode concedê-las agora ou depois, quando algum recurso precisar."
    )

    static let tr = FeatureHubStrings(
        pageTitle: "Özellikler",
        intro: "Çalışma alanınıza eklenecek araçları seçin. Çıkarılan araçlar çalışmayı durdurur ve işlem girişleri gizlenir. Kayıtlı ayarlar korunur. Özetini Özellikler bölümünde görebilirsiniz.",
        tabFeatures: "Özellikler",
        tabPermissions: "İzinler",
        activeCountFormat: "%2$d özellikten %1$d tanesi yüklü",
        monitorAllOffNote: "Hepsi kapalıyken Monitör panelden ve menü çubuğundan kaybolur.",
        titleMouseNavigation: "Yan düğmeler",
        groupMonitor: "Sistem monitörü",
        groupWindowsDesktop: "Pencereler ve masaüstü",
        groupInputDevices: "Giriş aygıtları",
        groupGlobalEntry: "Genel giriş noktaları",
        groupClipboardFiles: "Pano ve dosyalar",
        groupCapture: "Yakalama ve içerik",
        groupSoundDevices: "Ses ve aygıtlar",
        groupFocusEnergy: "Odaklanma ve enerji",
        groupAppManagement: "Uygulama yönetimi",
        permissionsIntro: "Her iznin ne yaptığı ve hangi özelliklerin onu kullandığı. Diğer erişimler yalnızca kullandığınızda istenir.",
        usedByFormat: "Kullanan: %@",
        usedByNone: "Şu anda açık olan hiçbir şey bu izni kullanmıyor.",
        unusedBanner: "Bu izni verdiniz ama açık olan hiçbir şeyin ona ihtiyacı yok. İsterseniz Sistem Ayarları’ndan geri alabilirsiniz.",
        statusGranted: "Verildi",
        statusMissing: "Verilmedi",
        statusUnknown: "Uygulama bunu denetleyemiyor",
        requestButton: "İste",
        openSystemSettings: "Sistem Ayarları’nı Aç",
        permAccessibility: "Erişilebilirlik",
        permScreenRecording: "Ekran Kaydı",
        permFullDisk: "Tam Disk Erişimi",
        permFilesAndFolders: "Dosyalar ve Klasörler",
        permNotifications: "Bildirimler",
        permAutomationFinder: "Finder otomasyonu",
        permAutomationTerminal: "Terminal otomasyonu",
        permAudioCapture: "Uygulama sesi",
        explainAccessibility: "Özelliklerin tıklamalara ve tuşlara tepki vermesini ve pencereleri taşımasını sağlar.",
        explainScreenRecording: "Özelliklerin pencere önizlemeleri göstermesini ve ekrandaki metni okumasını sağlar.",
        explainFullDisk: "Temizleyicinin ve kaldırıcının artık dosyaları her yerde bulmasını sağlar.",
        explainFilesAndFolders: "WhatsApp temizliğinin ve deneysel düzenleyicinin İndirilenler klasörünü denetlemesini sağlar.",
        explainNotifications: "Uygulamanın açtığınız uyarılar için sizi bilgilendirmesini sağlar.",
        explainAutomationFinder: "Uygulamanın Finder’dan sizin için dosya taşımasını istemesini sağlar.",
        explainAutomationTerminal: "Homebrew komutlarının Terminal’de açılmasını sağlar.",
        explainAudioCapture: "Mikserin her uygulamanın sesini ayarlamasını ve ekran kayıtlarının Mac’in sesini içermesini sağlar.",
        descSwitcher: "Önizlemelerle uygulama ve pencere değiştirin",
        descDockPreview: "Dock üzerine gelince pencere önizlemeleri",
        descDockClick: "Dock simgesine tıklayarak küçültün veya geçiş yapın",
        descWindowMaximizer: "Yeşil düğme tam ekran yerine büyütür",
        descAutoQuit: "Son pencere kapanınca uygulamadan çıkar",
        descScrollInverter: "Fare tekerleğinin yönünü ters çevirir",
        descSmoothScroll: "Akıcı ve animasyonlu fare kaydırması",
        descMouseNavigation: "Yan fare düğmeleri geri ve ileri gider",
        descMiddleClick: "Üç parmakla tıklama orta tık olur",
        descKeyboardDebounce: "İstenmeyen çift tuş basımlarını yok sayar",
        descClipboardHistory: "Kopyaladıklarınızın yerel geçmişini tutar",
        descPastePlain: "Metni biçimlendirmesiz yapıştırın",
        descFinderCutPaste: "Finder’da dosyaları kesip yapıştırın",
        descShelf: "Dosyaları menü çubuğuna bırakıp bekletin",
        descURLCleaner: "Kopyalanan bağlantılar izleyicilerden arınır",
        descMixer: "Her uygulama için ayrı ses düzeyi",
        descSoundOutputSwitcher: "Kısayolla ses çıkışları arasında geçin",
        descMicMute: "Mikrofonu her yerden sessize alın",
        descKeepAwake: "Mac’i istediğinizde uyanık tutun",
        descColorPicker: "Ekrandaki herhangi bir rengi alın",
        descScreenOCR: "Ekrandaki her şeyden metin veya QR kodu kopyalayın",
        descCleaningMode: "Temizlik için klavyeyi ve ekranı kilitler",
        descMediaTools: "Videoları, görselleri ve GIF’leri sıkıştırın",
        descCleaner: "Önbellekleri ve gereksiz dosyaları temizleyin",
        descUninstaller: "Uygulamaları ve kalıntılarını kaldırın",
        descHomebrew: "Homebrew paketlerini güncel tutun",
        descMonitorCPU: "İşlemci kullanımı ve sıcaklığı",
        descMonitorGPU: "Grafik kullanımı ve sıcaklığı",
        descMonitorMemory: "Bellek kullanımı ve baskısı",
        descMonitorNetwork: "Ağ hızı ve kullanımı",
        descMonitorDisk: "Disk alanı ve etkinliği",
        descMonitorPower: "Pil, güç ve şarj",
        installButton: "Yükle",
        uninstallButton: "Kaldır",
        footerNote: "Kaldırmak hiçbir şeyi silmez: özellik yalnızca uygulamadan kaybolur ve yüklenmeyi bırakır. İstediğinizde yeniden yükleyin, her şey olduğu gibi geri gelir.",
        restartNote: "Bu oturumda kaldırılan özellikler uygulama yeniden başlayana kadar yüklü kalır. Şimdi bellekten atmak için yeniden başlatın.",
        restartButton: "Şimdi yeniden başlat",
        installAllButton: "Tümünü yükle",
        uninstallAllButton: "Tümünü kaldır",
        energyIdle: "Boşta hiçbir şey",
        energyMouse: "Fareyi dinler",
        energyPointer: "İşaretçi girişini dinler",
        energyKeyboard: "Klavyeyi dinler",
        energyInputs: "Fare ve klavyeyi dinler",
        energyPeriodic: "Aralıklarla denetler",
        energyHelp: "Özellik açıkken tuttuğu maliyet. Kaldırılan özellik hiçbir şey yüklemez.",
        explainAppManagement: "Güncellemelerin paket yöneticisiyle yüklenen uygulamaları değiştirmesini veya kaldırmasını sağlar.",
        onboardingSelectedPermissionsTitle: "Seçimleriniz için gereken izinler",
        onboardingNoSelectedPermissions: "Kurulumu tamamlamak için izin vermeniz gerekmiyor.",
        onboardingOtherPermissionsTitle: "Diğer izinler",
        onboardingOtherPermissionsCaption: "İsteğe bağlıdır. Bir özellik gerektiğinde şimdi veya daha sonra izin verebilirsiniz."
    )

    static let ru = FeatureHubStrings(
        pageTitle: "Функции",
        intro: "Выберите инструменты для рабочего пространства. Удалённые из него инструменты перестают работать, а пункты их запуска скрываются. Сохранённые настройки остаются доступны в виде сводки в разделе «Функции».",
        tabFeatures: "Функции",
        tabPermissions: "Разрешения",
        activeCountFormat: "Установлено %1$d из %2$d функций",
        monitorAllOffNote: "Когда всё выключено, Монитор исчезает из панели и строки меню.",
        titleMouseNavigation: "Боковые кнопки",
        groupMonitor: "Системный монитор",
        groupWindowsDesktop: "Окна и рабочий стол",
        groupInputDevices: "Устройства ввода",
        groupGlobalEntry: "Глобальные точки входа",
        groupClipboardFiles: "Буфер обмена и файлы",
        groupCapture: "Захват и контент",
        groupSoundDevices: "Звук и устройства",
        groupFocusEnergy: "Концентрация и энергия",
        groupAppManagement: "Управление приложениями",
        permissionsIntro: "Что делает каждое разрешение и какие функции им пользуются. Остальной доступ запрашивается только при использовании.",
        usedByFormat: "Используется: %@",
        usedByNone: "Сейчас ни одна включённая функция не использует это разрешение.",
        unusedBanner: "Вы дали это разрешение, но ничему включённому оно не нужно. При желании отзовите его в Системных настройках.",
        statusGranted: "Предоставлено",
        statusMissing: "Не предоставлено",
        statusUnknown: "Приложение не может это проверить",
        requestButton: "Запросить",
        openSystemSettings: "Открыть Системные настройки",
        permAccessibility: "Универсальный доступ",
        permScreenRecording: "Запись экрана",
        permFullDisk: "Полный доступ к диску",
        permFilesAndFolders: "Файлы и папки",
        permNotifications: "Уведомления",
        permAutomationFinder: "Автоматизация Finder",
        permAutomationTerminal: "Автоматизация Терминала",
        permAudioCapture: "Звук приложений",
        explainAccessibility: "Позволяет функциям реагировать на клики и клавиши и перемещать окна.",
        explainScreenRecording: "Позволяет функциям показывать миниатюры окон и читать текст с экрана.",
        explainFullDisk: "Позволяет очистке и деинсталлятору находить остатки файлов повсюду.",
        explainFilesAndFolders: "Разрешает очистке и экспериментальному органайзеру WhatsApp проверять папку «Загрузки».",
        explainNotifications: "Позволяет приложению сообщать о включённых вами оповещениях.",
        explainAutomationFinder: "Позволяет приложению просить Finder перемещать файлы за вас.",
        explainAutomationTerminal: "Позволяет командам Homebrew открываться в Терминале.",
        explainAudioCapture: "Позволяет микшеру настраивать громкость каждого приложения, а записям экрана включать звук Mac.",
        descSwitcher: "Переключайте приложения и окна с миниатюрами",
        descDockPreview: "Миниатюры окон при наведении на Dock",
        descDockClick: "Клик по значку в Dock сворачивает или переключает окна",
        descWindowMaximizer: "Зелёная кнопка разворачивает вместо полного экрана",
        descAutoQuit: "Закрывает приложение вместе с последним окном",
        descScrollInverter: "Инвертирует направление колёсика мыши",
        descSmoothScroll: "Плавная анимированная прокрутка мышью",
        descMouseNavigation: "Боковые кнопки мыши ведут назад и вперёд",
        descMiddleClick: "Клик тремя пальцами работает как средняя кнопка",
        descKeyboardDebounce: "Игнорирует случайные двойные нажатия клавиш",
        descClipboardHistory: "Хранит локальную историю скопированного",
        descPastePlain: "Вставка текста без форматирования",
        descFinderCutPaste: "Вырезайте и вставляйте файлы в Finder",
        descShelf: "Бросайте файлы на строку меню на хранение",
        descURLCleaner: "Скопированные ссылки очищаются от трекеров",
        descMixer: "Отдельная громкость для каждого приложения",
        descSoundOutputSwitcher: "Переключайте выходы звука сочетанием клавиш",
        descMicMute: "Отключайте микрофон откуда угодно",
        descKeepAwake: "Не давайте Mac засыпать, когда нужно",
        descColorPicker: "Возьмите любой цвет с экрана",
        descScreenOCR: "Копируйте текст или QR-коды с чего угодно на экране",
        descCleaningMode: "Блокирует клавиатуру и экран для чистки",
        descMediaTools: "Сжимайте видео, изображения и GIF",
        descCleaner: "Очищайте кэши и мусорные файлы",
        descUninstaller: "Удаляйте приложения вместе с остатками",
        descHomebrew: "Держите пакеты Homebrew в актуальном виде",
        descMonitorCPU: "Загрузка и температура процессора",
        descMonitorGPU: "Загрузка и температура графики",
        descMonitorMemory: "Использование и нагрузка памяти",
        descMonitorNetwork: "Скорость и трафик сети",
        descMonitorDisk: "Место и активность диска",
        descMonitorPower: "Батарея, питание и зарядка",
        installButton: "Установить",
        uninstallButton: "Удалить",
        footerNote: "Удаление ничего не стирает: функция просто исчезает из приложения и перестаёт загружаться. Установите её снова, и всё вернётся как было.",
        restartNote: "Функции, удалённые в этой сессии, остаются в памяти до перезапуска приложения. Перезапустите, чтобы выгрузить их прямо сейчас.",
        restartButton: "Перезапустить сейчас",
        installAllButton: "Установить все",
        uninstallAllButton: "Удалить все",
        energyIdle: "Ничего в покое",
        energyMouse: "Слушает мышь",
        energyPointer: "Отслеживает указатель",
        energyKeyboard: "Слушает клавиатуру",
        energyInputs: "Слушает мышь и клавиатуру",
        energyPeriodic: "Проверяет с интервалом",
        energyHelp: "Стоимость, пока функция включена. Удалённая функция ничего не загружает.",
        explainAppManagement: "Позволяет обновлениям заменять или удалять приложения, установленные через менеджер пакетов.",
        onboardingSelectedPermissionsTitle: "Разрешения для выбранных функций",
        onboardingNoSelectedPermissions: "Для завершения настройки разрешения не нужны.",
        onboardingOtherPermissionsTitle: "Другие разрешения",
        onboardingOtherPermissionsCaption: "Необязательно. Их можно выдать сейчас или позже, когда они понадобятся функции."
    )

    static let es = FeatureHubStrings(
        pageTitle: "Funciones",
        intro: "Activa los módulos que necesites. El funcionamiento en segundo plano y los atajos siguen los ajustes guardados. Activar un módulo no activa todos sus comportamientos. Ajusta cada interruptor en los ajustes del módulo.",
        tabFeatures: "Funciones",
        tabPermissions: "Permisos",
        activeCountFormat: "%1$d de %2$d módulos activados",
        monitorAllOffNote: "Con todo apagado, el Monitor desaparece del panel y de la barra de menús.",
        titleMouseNavigation: "Botones laterales",
        groupMonitor: "Monitor del sistema",
        groupWindowsDesktop: "Ventanas y escritorio",
        groupInputDevices: "Dispositivos de entrada",
        groupGlobalEntry: "Puntos de entrada globales",
        groupClipboardFiles: "Portapapeles y archivos",
        groupCapture: "Captura y contenido",
        groupSoundDevices: "Sonido y dispositivos",
        groupFocusEnergy: "Concentración y energía",
        groupAppManagement: "Gestión de apps",
        permissionsIntro: "Qué hace cada permiso y qué funciones lo usan. Los demás accesos se piden solo al utilizarlos.",
        usedByFormat: "Usado por %@",
        usedByNone: "Nada de lo que está activo usa este permiso ahora.",
        unusedBanner: "Concediste este permiso, pero nada de lo que está activo lo necesita. Si quieres, revócalo en Ajustes del Sistema.",
        statusGranted: "Concedido",
        statusMissing: "No concedido",
        statusUnknown: "La app no puede comprobar este",
        requestButton: "Solicitar",
        openSystemSettings: "Abrir Ajustes del Sistema",
        permAccessibility: "Accesibilidad",
        permScreenRecording: "Grabación de pantalla",
        permFullDisk: "Acceso total al disco",
        permFilesAndFolders: "Archivos y carpetas",
        permNotifications: "Notificaciones",
        permAutomationFinder: "Automatización del Finder",
        permAutomationTerminal: "Automatización de Terminal",
        permAudioCapture: "Audio de las apps",
        explainAccessibility: "Permite que las funciones reaccionen a clics y teclas y muevan ventanas.",
        explainScreenRecording: "Permite mostrar miniaturas de ventanas y leer texto en pantalla.",
        explainFullDisk: "Permite que el limpiador y el desinstalador encuentren restos en todas partes.",
        explainFilesAndFolders: "Permite que la limpieza y el organizador experimental de WhatsApp examinen la carpeta Descargas.",
        explainNotifications: "Permite que la app te avise de las alertas que activaste.",
        explainAutomationFinder: "Permite que la app pida al Finder mover archivos por ti.",
        explainAutomationTerminal: "Permite que los comandos de Homebrew se abran en Terminal.",
        explainAudioCapture: "Permite que el mezclador ajuste el volumen de cada app y que las grabaciones de pantalla incluyan el sonido del Mac.",
        descSwitcher: "Cambia de app y ventana con miniaturas",
        descDockPreview: "Miniaturas de ventanas al pasar por el Dock",
        descDockClick: "Clic en un icono del Dock para minimizar o alternar",
        descWindowMaximizer: "El botón verde maximiza en vez de pantalla completa",
        descAutoQuit: "Cierra la app cuando se cierra su última ventana",
        descScrollInverter: "Invierte la dirección de la rueda del ratón",
        descSmoothScroll: "Desplazamiento suave y animado del ratón",
        descMouseNavigation: "Los botones laterales van atrás y adelante",
        descMiddleClick: "El clic con tres dedos actúa como clic central",
        descKeyboardDebounce: "Ignora pulsaciones dobles accidentales",
        descClipboardHistory: "Guarda un historial local de lo que copias",
        descPastePlain: "Pega texto sin formato",
        descFinderCutPaste: "Corta y pega archivos en el Finder",
        descShelf: "Suelta archivos en la barra de menús para guardarlos",
        descURLCleaner: "Los enlaces copiados pierden los rastreadores",
        descMixer: "Un control de volumen para cada app",
        descSoundOutputSwitcher: "Cambia la salida de sonido con un atajo",
        descMicMute: "Silencia el micrófono desde cualquier lugar",
        descMusicBlock: "Bloquear el inicio de apps elegidas tras las teclas multimedia",
        descKeepAwake: "Mantén el Mac despierto cuando quieras",
        descColorPicker: "Toma cualquier color de la pantalla",
        descScreenOCR: "Copia texto o códigos QR de cualquier cosa en pantalla",
        descCleaningMode: "Bloquea teclado y pantalla para limpiar",
        descMediaTools: "Comprime vídeos, imágenes y GIF",
        descCleaner: "Limpia cachés y archivos basura",
        descUninstaller: "Elimina apps y sus restos",
        descHomebrew: "Mantén los paquetes de Homebrew al día",
        descMonitorCPU: "Uso y temperatura del procesador",
        descMonitorGPU: "Uso y temperatura de los gráficos",
        descMonitorMemory: "Uso y presión de memoria",
        descMonitorNetwork: "Velocidad y uso de la red",
        descMonitorDisk: "Espacio y actividad del disco",
        descMonitorPower: "Batería, energía y carga",
        installButton: "Activar",
        uninstallButton: "Desactivar",
        footerNote: "Desactivar un módulo detiene su funcionamiento en segundo plano y sus atajos. Sus datos y ajustes se conservan. Los ajustes de comportamiento y las combinaciones de teclas guardados siguen disponibles aquí. Vuelve a activarlo para editar todos sus ajustes.",
        restartNote: "Los módulos desactivados pueden conservar recursos en memoria. Reinicia la app para liberarlos.",
        restartButton: "Reiniciar ahora",
        installAllButton: "Activar todos",
        uninstallAllButton: "Desactivar todos",
        energyIdle: "Nada en reposo",
        energyMouse: "Escucha el ratón",
        energyPointer: "Escucha el puntero",
        energyKeyboard: "Escucha el teclado",
        energyInputs: "Escucha ratón y teclado",
        energyPeriodic: "Comprueba a intervalos",
        energyHelp: "Actividad en segundo plano mientras funciona. Las funciones desactivadas no se ejecutan.",
        explainAppManagement: "Permite que las actualizaciones sustituyan o eliminen apps instaladas con el gestor de paquetes.",
        onboardingSelectedPermissionsTitle: "Permisos para tus elecciones",
        onboardingNoSelectedPermissions: "No necesitas conceder permisos para terminar la configuración.",
        onboardingOtherPermissionsTitle: "Otros permisos",
        onboardingOtherPermissionsCaption: "Opcional. Concédelos ahora o después, cuando una función los necesite."
    )

    static let de = FeatureHubStrings(
        pageTitle: "Funktionen",
        intro: "Aktiviere die benötigten Module. Hintergrundverhalten und Kurzbefehle folgen den gespeicherten Einstellungen. Das Aktivieren eines Moduls schaltet nicht jedes Verhalten ein. Passe diese Schalter in den Moduleinstellungen einzeln an.",
        tabFeatures: "Funktionen",
        tabPermissions: "Berechtigungen",
        activeCountFormat: "%1$d von %2$d Modulen aktiviert",
        monitorAllOffNote: "Ist alles aus, verschwindet der Monitor aus dem Panel und der Menüleiste.",
        titleMouseNavigation: "Seitentasten",
        groupMonitor: "Systemmonitor",
        groupWindowsDesktop: "Fenster und Schreibtisch",
        groupInputDevices: "Eingabegeräte",
        groupGlobalEntry: "Globale Einstiegspunkte",
        groupClipboardFiles: "Zwischenablage und Dateien",
        groupCapture: "Aufnahme und Inhalte",
        groupSoundDevices: "Ton und Geräte",
        groupFocusEnergy: "Fokus und Energie",
        groupAppManagement: "App-Verwaltung",
        permissionsIntro: "Was jede Berechtigung tut und welche Funktionen sie nutzen. Weitere Zugriffe werden erst bei der Nutzung angefragt.",
        usedByFormat: "Genutzt von %@",
        usedByNone: "Nichts Eingeschaltetes nutzt diese Berechtigung gerade.",
        unusedBanner: "Du hast diese Berechtigung erteilt, aber nichts Eingeschaltetes braucht sie. Du kannst sie in den Systemeinstellungen widerrufen.",
        statusGranted: "Erteilt",
        statusMissing: "Nicht erteilt",
        statusUnknown: "Die App kann das nicht prüfen",
        requestButton: "Anfragen",
        openSystemSettings: "Systemeinstellungen öffnen",
        permAccessibility: "Bedienungshilfen",
        permScreenRecording: "Bildschirmaufnahme",
        permFullDisk: "Festplattenvollzugriff",
        permFilesAndFolders: "Dateien & Ordner",
        permNotifications: "Mitteilungen",
        permAutomationFinder: "Finder-Automation",
        permAutomationTerminal: "Terminal-Automation",
        permAudioCapture: "App-Audio",
        explainAccessibility: "Lässt Funktionen auf Klicks und Tasten reagieren und Fenster bewegen.",
        explainScreenRecording: "Lässt Funktionen Fenstervorschauen zeigen und Text vom Bildschirm lesen.",
        explainFullDisk: "Lässt Reiniger und Deinstallierer überall Dateireste finden.",
        explainFilesAndFolders: "Erlaubt der WhatsApp-Bereinigung und dem experimentellen Organizer, den Downloads-Ordner zu prüfen.",
        explainNotifications: "Lässt die App dich über aktivierte Warnungen informieren.",
        explainAutomationFinder: "Lässt die App den Finder bitten, Dateien für dich zu bewegen.",
        explainAutomationTerminal: "Lässt Homebrew-Befehle im Terminal öffnen.",
        explainAudioCapture: "Lässt den Mixer die Lautstärke jeder App regeln und Bildschirmaufnahmen den Ton des Mac aufnehmen.",
        descSwitcher: "Apps und Fenster mit Vorschauen wechseln",
        descDockPreview: "Fenstervorschauen beim Zeigen aufs Dock",
        descDockClick: "Dock-Symbol klicken, um zu minimieren oder zu wechseln",
        descWindowMaximizer: "Der grüne Knopf maximiert statt Vollbild",
        descAutoQuit: "Beendet Apps, wenn das letzte Fenster schließt",
        descScrollInverter: "Kehrt die Richtung des Mausrads um",
        descSmoothScroll: "Sanftes, animiertes Scrollen mit der Maus",
        descMouseNavigation: "Seitentasten der Maus gehen vor und zurück",
        descMiddleClick: "Drei-Finger-Klick wirkt als Mittelklick",
        descKeyboardDebounce: "Ignoriert versehentliche doppelte Tastendrücke",
        descClipboardHistory: "Behält einen lokalen Verlauf des Kopierten",
        descPastePlain: "Text ohne Formatierung einsetzen",
        descFinderCutPaste: "Dateien im Finder ausschneiden und einsetzen",
        descShelf: "Dateien auf der Menüleiste ablegen und festhalten",
        descURLCleaner: "Kopierte Links verlieren ihre Tracker",
        descMixer: "Ein Lautstärkeregler für jede App",
        descSoundOutputSwitcher: "Tonausgänge per Kurzbefehl durchschalten",
        descMicMute: "Das Mikrofon von überall stummschalten",
        descMusicBlock: "Starts ausgewählter Apps nach Medientasten blockieren",
        descKeepAwake: "Hält den Mac wach, wann immer du willst",
        descColorPicker: "Jede Farbe vom Bildschirm aufnehmen",
        descScreenOCR: "Text oder QR-Codes von allem auf dem Bildschirm kopieren",
        descCleaningMode: "Sperrt Tastatur und Bildschirm zum Putzen",
        descMediaTools: "Videos, Bilder und GIFs komprimieren",
        descCleaner: "Caches und Datenmüll aufräumen",
        descUninstaller: "Apps samt Überresten entfernen",
        descHomebrew: "Homebrew-Pakete aktuell halten",
        descMonitorCPU: "Prozessorauslastung und Temperatur",
        descMonitorGPU: "Grafikauslastung und Temperatur",
        descMonitorMemory: "Speichernutzung und Druck",
        descMonitorNetwork: "Netzwerkgeschwindigkeit und Verbrauch",
        descMonitorDisk: "Speicherplatz und Festplattenaktivität",
        descMonitorPower: "Batterie, Strom und Laden",
        installButton: "Aktivieren",
        uninstallButton: "Deaktivieren",
        footerNote: "Das Deaktivieren eines Moduls stoppt sein Hintergrundverhalten und seine Kurzbefehle. Daten und Einstellungen bleiben erhalten. Gespeicherte Verhaltenseinstellungen und Tastenkombinationen bleiben hier einsehbar. Aktiviere es erneut, um alle Einstellungen zu bearbeiten.",
        restartNote: "Deaktivierte Module können weiterhin Ressourcen im Speicher halten. Starte die App neu, um sie freizugeben.",
        restartButton: "Jetzt neu starten",
        installAllButton: "Alle aktivieren",
        uninstallAllButton: "Alle deaktivieren",
        energyIdle: "Nichts im Ruhezustand",
        energyMouse: "Hört auf die Maus",
        energyPointer: "Hört auf Zeigereingaben",
        energyKeyboard: "Hört auf die Tastatur",
        energyInputs: "Hört auf Maus und Tastatur",
        energyPeriodic: "Prüft in Intervallen",
        energyHelp: "Hintergrundaktivität während die Funktion läuft. Deaktivierte Funktionen laufen nicht.",
        explainAppManagement: "Erlaubt App-Updates, vom Paketmanager installierte Apps zu ersetzen oder zu entfernen.",
        onboardingSelectedPermissionsTitle: "Berechtigungen für deine Auswahl",
        onboardingNoSelectedPermissions: "Zum Abschließen der Einrichtung ist keine Berechtigung nötig.",
        onboardingOtherPermissionsTitle: "Weitere Berechtigungen",
        onboardingOtherPermissionsCaption: "Optional. Erlaube sie jetzt oder später, wenn eine Funktion sie benötigt."
    )

    static let fr = FeatureHubStrings(
        pageTitle: "Fonctions",
        intro: "Activez les modules nécessaires. Le fonctionnement en arrière-plan et les raccourcis suivent les réglages enregistrés. Activer un module n’active pas tous ses comportements. Réglez chaque interrupteur dans les réglages du module.",
        tabFeatures: "Fonctions",
        tabPermissions: "Autorisations",
        activeCountFormat: "%1$d modules sur %2$d activés",
        monitorAllOffNote: "Tout éteint, le Moniteur disparaît du panneau et de la barre des menus.",
        titleMouseNavigation: "Boutons latéraux",
        groupMonitor: "Moniteur système",
        groupWindowsDesktop: "Fenêtres et bureau",
        groupInputDevices: "Périphériques de saisie",
        groupGlobalEntry: "Points d’entrée globaux",
        groupClipboardFiles: "Presse-papiers et fichiers",
        groupCapture: "Capture et contenu",
        groupSoundDevices: "Son et appareils",
        groupFocusEnergy: "Concentration et énergie",
        groupAppManagement: "Gestion des apps",
        permissionsIntro: "Ce que fait chaque autorisation et quelles fonctions l’utilisent. Les autres accès ne sont demandés qu’à l’utilisation.",
        usedByFormat: "Utilisée par %@",
        usedByNone: "Rien d’activé n’utilise cette autorisation pour l’instant.",
        unusedBanner: "Vous avez accordé cette autorisation, mais rien d’activé n’en a besoin. Si vous voulez, révoquez-la dans Réglages Système.",
        statusGranted: "Accordée",
        statusMissing: "Non accordée",
        statusUnknown: "L’app ne peut pas vérifier celle-ci",
        requestButton: "Demander",
        openSystemSettings: "Ouvrir Réglages Système",
        permAccessibility: "Accessibilité",
        permScreenRecording: "Enregistrement de l’écran",
        permFullDisk: "Accès complet au disque",
        permFilesAndFolders: "Fichiers et dossiers",
        permNotifications: "Notifications",
        permAutomationFinder: "Automatisation du Finder",
        permAutomationTerminal: "Automatisation du Terminal",
        permAudioCapture: "Audio des apps",
        explainAccessibility: "Permet aux fonctions de réagir aux clics et touches et de déplacer les fenêtres.",
        explainScreenRecording: "Permet d’afficher des aperçus de fenêtres et de lire le texte à l’écran.",
        explainFullDisk: "Permet au nettoyeur et au désinstalleur de trouver les restes partout.",
        explainFilesAndFolders: "Autorise le nettoyage et l’organisateur expérimental WhatsApp à examiner le dossier Téléchargements.",
        explainNotifications: "Permet à l’app de vous prévenir des alertes que vous avez activées.",
        explainAutomationFinder: "Permet à l’app de demander au Finder de déplacer des fichiers pour vous.",
        explainAutomationTerminal: "Permet aux commandes Homebrew de s’ouvrir dans le Terminal.",
        explainAudioCapture: "Permet au mixeur d’ajuster le volume de chaque app et aux enregistrements d’écran d’inclure le son du Mac.",
        descSwitcher: "Changez d’app et de fenêtre avec des aperçus",
        descDockPreview: "Aperçus des fenêtres au survol du Dock",
        descDockClick: "Cliquez une icône du Dock pour réduire ou alterner",
        descWindowMaximizer: "Le bouton vert agrandit au lieu du plein écran",
        descAutoQuit: "Quitte l’app quand sa dernière fenêtre se ferme",
        descScrollInverter: "Inverse le sens de la molette de la souris",
        descSmoothScroll: "Défilement fluide et animé à la souris",
        descMouseNavigation: "Les boutons latéraux vont en arrière et en avant",
        descMiddleClick: "Le clic à trois doigts devient un clic du milieu",
        descKeyboardDebounce: "Ignore les doubles frappes accidentelles",
        descClipboardHistory: "Garde un historique local de vos copies",
        descPastePlain: "Collez du texte sans mise en forme",
        descFinderCutPaste: "Coupez et collez des fichiers dans le Finder",
        descShelf: "Déposez des fichiers sur la barre des menus",
        descURLCleaner: "Les liens copiés perdent leurs traqueurs",
        descMixer: "Un volume pour chaque app",
        descSoundOutputSwitcher: "Changez de sortie audio avec un raccourci",
        descMicMute: "Coupez le micro depuis n’importe où",
        descMusicBlock: "Bloquer le lancement des apps choisies après les touches multimédias",
        descKeepAwake: "Gardez le Mac éveillé à la demande",
        descColorPicker: "Prélevez n’importe quelle couleur à l’écran",
        descScreenOCR: "Copiez le texte ou les codes QR de tout ce qui s’affiche",
        descCleaningMode: "Verrouille clavier et écran pour le nettoyage",
        descMediaTools: "Compressez vidéos, images et GIF",
        descCleaner: "Nettoyez caches et fichiers inutiles",
        descUninstaller: "Supprimez les apps et leurs restes",
        descHomebrew: "Gardez les paquets Homebrew à jour",
        descMonitorCPU: "Utilisation et température du processeur",
        descMonitorGPU: "Utilisation et température graphique",
        descMonitorMemory: "Utilisation et pression mémoire",
        descMonitorNetwork: "Vitesse et usage du réseau",
        descMonitorDisk: "Espace et activité du disque",
        descMonitorPower: "Batterie, alimentation et charge",
        installButton: "Activer",
        uninstallButton: "Désactiver",
        footerNote: "Désactiver un module arrête son fonctionnement en arrière-plan et ses raccourcis. Ses données et réglages sont conservés. Les réglages de comportement et combinaisons de touches enregistrés restent consultables ici. Réactivez-le pour modifier tous ses réglages.",
        restartNote: "Les modules désactivés peuvent conserver des ressources en mémoire. Redémarrez l’app pour les libérer.",
        restartButton: "Redémarrer maintenant",
        installAllButton: "Tout activer",
        uninstallAllButton: "Tout désactiver",
        energyIdle: "Rien au repos",
        energyMouse: "Écoute la souris",
        energyPointer: "Écoute le pointeur",
        energyKeyboard: "Écoute le clavier",
        energyInputs: "Écoute souris et clavier",
        energyPeriodic: "Vérifie par intervalles",
        energyHelp: "Activité en arrière-plan pendant le fonctionnement. Les fonctions désactivées ne s’exécutent pas.",
        explainAppManagement: "Permet aux mises à jour de remplacer ou supprimer les apps installées par le gestionnaire de paquets.",
        onboardingSelectedPermissionsTitle: "Autorisations pour vos choix",
        onboardingNoSelectedPermissions: "Aucune autorisation n’est nécessaire pour terminer la configuration.",
        onboardingOtherPermissionsTitle: "Autres autorisations",
        onboardingOtherPermissionsCaption: "Facultatif. Accordez-les maintenant ou plus tard, lorsqu’une fonction en aura besoin."
    )

    static let it = FeatureHubStrings(
        pageTitle: "Funzioni",
        intro: "Scegli gli strumenti da aggiungere all’area di lavoro. Gli strumenti rimossi smettono di funzionare e i relativi comandi vengono nascosti. Le impostazioni salvate vengono conservate e puoi consultarne il riepilogo in Funzioni.",
        tabFeatures: "Funzioni",
        tabPermissions: "Permessi",
        activeCountFormat: "%1$d funzioni installate su %2$d",
        monitorAllOffNote: "Con tutto spento, il Monitor sparisce dal pannello e dalla barra dei menu.",
        titleMouseNavigation: "Tasti laterali",
        groupMonitor: "Monitor di sistema",
        groupWindowsDesktop: "Finestre e scrivania",
        groupInputDevices: "Dispositivi di input",
        groupGlobalEntry: "Punti di accesso globali",
        groupClipboardFiles: "Appunti e file",
        groupCapture: "Cattura e contenuti",
        groupSoundDevices: "Suono e dispositivi",
        groupFocusEnergy: "Concentrazione ed energia",
        groupAppManagement: "Gestione delle app",
        permissionsIntro: "Cosa fa ogni permesso e quali funzioni lo usano. Gli altri accessi vengono chiesti solo quando servono.",
        usedByFormat: "Usato da %@",
        usedByNone: "Niente di attivo usa questo permesso al momento.",
        unusedBanner: "Hai concesso questo permesso, ma niente di attivo ne ha bisogno. Se vuoi, revocalo in Impostazioni di Sistema.",
        statusGranted: "Concesso",
        statusMissing: "Non concesso",
        statusUnknown: "L’app non può verificarlo",
        requestButton: "Richiedi",
        openSystemSettings: "Apri Impostazioni di Sistema",
        permAccessibility: "Accessibilità",
        permScreenRecording: "Registrazione schermo",
        permFullDisk: "Accesso completo al disco",
        permFilesAndFolders: "File e cartelle",
        permNotifications: "Notifiche",
        permAutomationFinder: "Automazione del Finder",
        permAutomationTerminal: "Automazione del Terminale",
        permAudioCapture: "Audio delle app",
        explainAccessibility: "Permette alle funzioni di reagire a clic e tasti e spostare finestre.",
        explainScreenRecording: "Permette di mostrare anteprime delle finestre e leggere il testo sullo schermo.",
        explainFullDisk: "Permette a pulizia e disinstallazione di trovare residui ovunque.",
        explainFilesAndFolders: "Consente alla pulizia e all’organizzatore sperimentale di WhatsApp di controllare la cartella Download.",
        explainNotifications: "Permette all’app di avvisarti degli allarmi che hai attivato.",
        explainAutomationFinder: "Permette all’app di chiedere al Finder di spostare file per te.",
        explainAutomationTerminal: "Permette ai comandi Homebrew di aprirsi nel Terminale.",
        explainAudioCapture: "Permette al mixer di regolare il volume di ogni app e alle registrazioni dello schermo di includere l’audio del Mac.",
        descSwitcher: "Cambia app e finestra con le anteprime",
        descDockPreview: "Anteprime delle finestre passando sul Dock",
        descDockClick: "Clic su un’icona del Dock per ridurre o alternare",
        descWindowMaximizer: "Il pulsante verde ingrandisce invece dello schermo intero",
        descAutoQuit: "Chiude l’app quando si chiude l’ultima finestra",
        descScrollInverter: "Inverte la direzione della rotella del mouse",
        descSmoothScroll: "Scorrimento fluido e animato del mouse",
        descMouseNavigation: "I tasti laterali vanno indietro e avanti",
        descMiddleClick: "Il clic a tre dita funge da clic centrale",
        descKeyboardDebounce: "Ignora le doppie pressioni accidentali",
        descClipboardHistory: "Tiene una cronologia locale di ciò che copi",
        descPastePlain: "Incolla il testo senza formattazione",
        descFinderCutPaste: "Taglia e incolla i file nel Finder",
        descShelf: "Trascina file sulla barra dei menu per tenerli lì",
        descURLCleaner: "I link copiati perdono i tracciatori",
        descMixer: "Un volume per ogni app",
        descSoundOutputSwitcher: "Cambia uscita audio con una scorciatoia",
        descMicMute: "Silenzia il microfono da ovunque",
        descKeepAwake: "Tieni il Mac sveglio quando serve",
        descColorPicker: "Preleva qualsiasi colore dallo schermo",
        descScreenOCR: "Copia testo o codici QR da qualsiasi cosa sullo schermo",
        descCleaningMode: "Blocca tastiera e schermo per la pulizia",
        descMediaTools: "Comprimi video, immagini e GIF",
        descCleaner: "Pulisci cache e file inutili",
        descUninstaller: "Rimuovi le app e i loro residui",
        descHomebrew: "Tieni aggiornati i pacchetti Homebrew",
        descMonitorCPU: "Uso e temperatura del processore",
        descMonitorGPU: "Uso e temperatura della grafica",
        descMonitorMemory: "Uso e pressione della memoria",
        descMonitorNetwork: "Velocità e uso della rete",
        descMonitorDisk: "Spazio e attività del disco",
        descMonitorPower: "Batteria, alimentazione e ricarica",
        installButton: "Installa",
        uninstallButton: "Disinstalla",
        footerNote: "Disinstallare non cancella nulla: la funzione sparisce dall’app e smette di caricarsi. Reinstallala quando vuoi e tutto torna com’era.",
        restartNote: "Le funzioni disinstallate in questa sessione restano caricate finché l’app non si riavvia. Riavvia per scaricarle dalla memoria ora.",
        restartButton: "Riavvia ora",
        installAllButton: "Installa tutto",
        uninstallAllButton: "Disinstalla tutto",
        energyIdle: "Niente a riposo",
        energyMouse: "Ascolta il mouse",
        energyPointer: "Ascolta il puntatore",
        energyKeyboard: "Ascolta la tastiera",
        energyInputs: "Ascolta mouse e tastiera",
        energyPeriodic: "Controlla a intervalli",
        energyHelp: "Il costo mentre la funzione è attiva. Disinstallata non carica nulla.",
        explainAppManagement: "Consente agli aggiornamenti di sostituire o rimuovere le app installate dal gestore di pacchetti.",
        onboardingSelectedPermissionsTitle: "Permessi per le tue scelte",
        onboardingNoSelectedPermissions: "Non servono permessi per completare la configurazione.",
        onboardingOtherPermissionsTitle: "Altri permessi",
        onboardingOtherPermissionsCaption: "Facoltativo. Concedili ora o più tardi, quando una funzione ne avrà bisogno."
    )

    static let ja = FeatureHubStrings(
        pageTitle: "機能",
        intro: "必要なモジュールを有効にしてください。バックグラウンド動作とショートカットは保存済みの設定に従います。モジュールを有効にしても、すべての動作がオンになるわけではありません。各動作のスイッチはモジュールの設定で個別に調整できます。",
        tabFeatures: "機能",
        tabPermissions: "権限",
        activeCountFormat: "%2$d 件中 %1$d 件のモジュールが有効",
        monitorAllOffNote: "すべてオフにすると、モニタはパネルとメニューバーから消えます。",
        titleMouseNavigation: "サイドボタン",
        groupMonitor: "システムモニタ",
        groupWindowsDesktop: "ウインドウとデスクトップ",
        groupInputDevices: "入力デバイス",
        groupGlobalEntry: "グローバルな入口",
        groupClipboardFiles: "クリップボードとファイル",
        groupCapture: "キャプチャとコンテンツ",
        groupSoundDevices: "サウンドとデバイス",
        groupFocusEnergy: "集中とエネルギー",
        groupAppManagement: "Appの管理",
        permissionsIntro: "各権限の役割と、それを使う機能です。その他のアクセスは機能を使うときだけ求めます。",
        usedByFormat: "使用中: %@",
        usedByNone: "現在オンの機能でこの権限を使うものはありません。",
        unusedBanner: "この権限は許可されていますが、オンの機能はどれも必要としていません。よければシステム設定で取り消せます。",
        statusGranted: "許可済み",
        statusMissing: "未許可",
        statusUnknown: "アプリからは確認できません",
        requestButton: "許可を求める",
        openSystemSettings: "システム設定を開く",
        permAccessibility: "アクセシビリティ",
        permScreenRecording: "画面収録",
        permFullDisk: "フルディスクアクセス",
        permFilesAndFolders: "ファイルとフォルダ",
        permNotifications: "通知",
        permAutomationFinder: "Finderの自動化",
        permAutomationTerminal: "ターミナルの自動化",
        permAudioCapture: "アプリのオーディオ",
        explainAccessibility: "機能がクリックやキーに反応し、ウインドウを動かせるようにします。",
        explainScreenRecording: "ウインドウのサムネイル表示や画面上の文字の読み取りを可能にします。",
        explainFullDisk: "クリーナーとアンインストーラが残りファイルをどこでも見つけられるようにします。",
        explainFilesAndFolders: "WhatsAppのダウンロード整理と実験的オーガナイザーがダウンロードフォルダを確認できるようにします。",
        explainNotifications: "オンにした警告をアプリが通知できるようにします。",
        explainAutomationFinder: "アプリがFinderにファイル移動を頼めるようにします。",
        explainAutomationTerminal: "Homebrewのコマンドをターミナルで開けるようにします。",
        explainAudioCapture: "ミキサーがアプリごとの音量を調整し、画面収録にMacの音声を含められるようにします。",
        descSwitcher: "プレビュー付きでアプリとウインドウを切り替え",
        descDockPreview: "Dockにポインタを重ねるとウインドウをプレビュー",
        descDockClick: "Dockアイコンのクリックで最小化や切り替え",
        descWindowMaximizer: "緑のボタンがフルスクリーンではなく最大化に",
        descAutoQuit: "最後のウインドウを閉じるとアプリを終了",
        descScrollInverter: "マウスホイールの向きを反転",
        descSmoothScroll: "なめらかにアニメーションするスクロール",
        descMouseNavigation: "サイドボタンで戻る、進む",
        descMiddleClick: "3本指クリックをミドルクリックに",
        descKeyboardDebounce: "誤った二重入力を無視",
        descClipboardHistory: "コピーの履歴をローカルに保存",
        descPastePlain: "書式なしでテキストをペースト",
        descFinderCutPaste: "Finderでファイルをカット&ペースト",
        descShelf: "メニューバーにファイルをドロップして一時置き",
        descURLCleaner: "コピーしたリンクからトラッカーを除去",
        descMixer: "アプリごとの音量スライダ",
        descSoundOutputSwitcher: "ショートカットで出力先を切り替え",
        descMicMute: "どこからでもマイクをミュート",
        descMusicBlock: "メディアキーによる選択したアプリの起動を防ぐ",
        descKeepAwake: "必要なときにMacをスリープさせない",
        descColorPicker: "画面上のどんな色も取得",
        descScreenOCR: "画面上のあらゆる文字やQRコードをコピー",
        descCleaningMode: "掃除のためにキーボードと画面をロック",
        descMediaTools: "ビデオ、画像、GIFを圧縮",
        descCleaner: "キャッシュと不要ファイルを掃除",
        descUninstaller: "アプリを残りファイルごと削除",
        descHomebrew: "Homebrewのパッケージを最新に",
        descMonitorCPU: "プロセッサの使用率と温度",
        descMonitorGPU: "グラフィックスの使用率と温度",
        descMonitorMemory: "メモリの使用量と圧力",
        descMonitorNetwork: "ネットワークの速度と使用量",
        descMonitorDisk: "ディスクの空きとアクティビティ",
        descMonitorPower: "バッテリー、電力、充電",
        installButton: "有効にする",
        uninstallButton: "無効にする",
        footerNote: "モジュールを無効にするとバックグラウンド動作とショートカットが停止し、データと設定は保持されます。保存済みの動作設定とキーの組み合わせはここで確認できます。すべての設定を編集するには再度有効にしてください。",
        restartNote: "無効にしたモジュールのリソースがメモリに残る場合があります。解放するには、アプリを再起動してください。",
        restartButton: "今すぐ再起動",
        installAllButton: "すべて有効にする",
        uninstallAllButton: "すべて無効にする",
        energyIdle: "待機中は何もなし",
        energyMouse: "マウスを監視",
        energyPointer: "ポインタ入力を監視",
        energyKeyboard: "キーボードを監視",
        energyInputs: "マウスとキーボードを監視",
        energyPeriodic: "一定間隔で確認",
        energyHelp: "機能の実行中に行うバックグラウンド動作です。無効にした機能は動作しません。",
        explainAppManagement: "パッケージマネージャでインストールしたAppをアップデートで置き換えたり削除したりできるようにします。",
        onboardingSelectedPermissionsTitle: "選んだ機能に必要な許可",
        onboardingNoSelectedPermissions: "設定を完了するための許可は必要ありません。",
        onboardingOtherPermissionsTitle: "その他の許可",
        onboardingOtherPermissionsCaption: "任意です。機能で必要になったときに、今または後で許可できます。"
    )

    static let zhHans = FeatureHubStrings(
        pageTitle: "功能",
        intro: "按需启用模块。后台行为和快捷键按已保存的设置运行，启用模块不会打开其中所有行为。各项行为开关可在模块设置中单独调整。",
        tabFeatures: "功能",
        tabPermissions: "权限",
        activeCountFormat: "已启用 %1$d 项，共 %2$d 项",
        monitorAllOffNote: "全部关闭后，系统监控会从面板和菜单栏中消失。",
        titleMouseNavigation: "侧键",
        groupMonitor: "系统监控",
        groupWindowsDesktop: "窗口与桌面",
        groupInputDevices: "输入设备",
        groupGlobalEntry: "全局入口",
        groupClipboardFiles: "剪贴板与文件",
        groupCapture: "捕获与内容处理",
        groupSoundDevices: "声音与设备",
        groupFocusEnergy: "专注与节能",
        groupAppManagement: "App 管理",
        permissionsIntro: "每项权限的作用以及哪些功能会使用它。其他访问权限只会在使用相关功能时请求。",
        usedByFormat: "使用者：%@",
        usedByNone: "目前没有已开启的功能在使用此权限。",
        unusedBanner: "你已授予此权限，但没有已开启的功能需要它。如果愿意，可以在系统设置中撤销。",
        statusGranted: "已授予",
        statusMissing: "未授予",
        statusUnknown: "App 无法检查此项",
        requestButton: "申请",
        openSystemSettings: "打开系统设置",
        permAccessibility: "辅助功能",
        permScreenRecording: "屏幕录制",
        permFullDisk: "完全磁盘访问权限",
        permFilesAndFolders: "文件与文件夹",
        permNotifications: "通知",
        permAutomationFinder: "访达自动化",
        permAutomationTerminal: "终端自动化",
        permAudioCapture: "App 音频",
        explainAccessibility: "让功能响应点按和按键，并移动窗口。",
        explainScreenRecording: "让功能显示窗口缩略图并读取屏幕上的文字。",
        explainFullDisk: "让清理器和卸载器在任何位置找到残留文件。",
        explainFilesAndFolders: "允许 WhatsApp 下载清理和实验性整理器检查下载文件夹。",
        explainNotifications: "让 App 就你开启的警报发出通知。",
        explainAutomationFinder: "让 App 请访达替你移动文件。",
        explainAutomationTerminal: "让 Homebrew 命令在终端中打开。",
        explainAudioCapture: "让混音器调整每个 App 的音量，并让屏幕录制包含 Mac 的声音。",
        descSwitcher: "带预览地切换 App 和窗口",
        descDockPreview: "悬停 Dock 时显示窗口预览",
        descDockClick: "点按 Dock 图标以最小化或切换窗口",
        descWindowMaximizer: "绿色按钮改为最大化而非全屏",
        descAutoQuit: "最后一个窗口关闭时退出 App",
        descScrollInverter: "反转鼠标滚轮方向",
        descSmoothScroll: "顺滑带动画的鼠标滚动",
        descMouseNavigation: "鼠标侧键前进后退",
        descMiddleClick: "三指点按变成中键点按",
        descKeyboardDebounce: "忽略意外的重复按键",
        descClipboardHistory: "在本地保存拷贝历史",
        descPastePlain: "粘贴无格式文本",
        descFinderCutPaste: "在访达中剪切和粘贴文件",
        descShelf: "把文件放到菜单栏上暂存",
        descURLCleaner: "拷贝的链接自动去除跟踪参数",
        descMixer: "每个 App 独立的音量滑块",
        descSoundOutputSwitcher: "用快捷键切换声音输出",
        descMicMute: "随时随地静音麦克风",
        descMusicBlock: "阻止媒体键触发所选 App 启动",
        descKeepAwake: "需要时让 Mac 保持唤醒",
        descColorPicker: "拾取屏幕上的任何颜色",
        descScreenOCR: "拷贝屏幕上任何内容的文字或二维码",
        descCleaningMode: "锁定键盘和屏幕以便清洁",
        descMediaTools: "转换媒体与合并 PDF 文件",
        descCleaner: "清理缓存和垃圾文件",
        descUninstaller: "卸载 App 并清除残留",
        descHomebrew: "保持 Homebrew 软件包最新",
        descMonitorCPU: "处理器占用与温度",
        descMonitorGPU: "图形占用与温度",
        descMonitorMemory: "内存占用与压力",
        descMonitorNetwork: "网络速度与用量",
        descMonitorDisk: "磁盘空间与活动",
        descMonitorPower: "电池、功耗与充电",
        installButton: "启用",
        uninstallButton: "关闭",
        footerNote: "关闭模块会停止其后台行为和快捷键，并保留数据与设置。仍可在这里查看已保存的运行设置与按键组合，重新启用后可编辑完整设置。",
        restartNote: "关闭的模块可能仍有资源驻留在内存中。重启 App 可释放这些资源。",
        restartButton: "立即重启",
        installAllButton: "全部启用",
        uninstallAllButton: "全部关闭",
        energyIdle: "空闲时无任何开销",
        energyMouse: "监听鼠标",
        energyPointer: "监听指针输入",
        energyKeyboard: "监听键盘",
        energyInputs: "监听鼠标和键盘",
        energyPeriodic: "按间隔检查",
        energyHelp: "功能运行时的后台活动。关闭的功能不运行。",
        explainAppManagement: "允许更新替换或移除通过软件包管理器安装的 App。",
        onboardingSelectedPermissionsTitle: "所选功能需要的权限",
        onboardingNoSelectedPermissions: "完成设置无需授予任何权限。",
        onboardingOtherPermissionsTitle: "其他权限",
        onboardingOtherPermissionsCaption: "可选。你可以现在授予，也可以等功能需要时再授予。"
    )

    static let zhTW = FeatureHubStrings(
        pageTitle: "功能",
        intro: "選擇要加入工作區的工具。移出後工具停止執行，操作入口隱藏。已儲存的設定會保留，仍可在「功能」中查看摘要。",
        tabFeatures: "功能",
        tabPermissions: "權限",
        activeCountFormat: "已安裝 %1$d 項，共 %2$d 項",
        monitorAllOffNote: "全部關閉後，監視器會從面板和選單列中消失。",
        titleMouseNavigation: "側鍵",
        groupMonitor: "系統監視器",
        groupWindowsDesktop: "視窗與桌面",
        groupInputDevices: "輸入裝置",
        groupGlobalEntry: "全局入口",
        groupClipboardFiles: "剪貼板與檔案",
        groupCapture: "擷取與內容處理",
        groupSoundDevices: "聲音與裝置",
        groupFocusEnergy: "專注與節能",
        groupAppManagement: "App 管理",
        permissionsIntro: "每項權限的作用，以及哪些功能會使用它。其他存取權限只會在使用相關功能時要求。",
        usedByFormat: "使用者：%@",
        usedByNone: "目前沒有已開啟的功能在使用此權限。",
        unusedBanner: "你已授予此權限，但沒有已開啟的功能需要它。若你願意，可以在系統設定中撤銷。",
        statusGranted: "已授予",
        statusMissing: "未授予",
        statusUnknown: "App 無法檢查此項",
        requestButton: "要求",
        openSystemSettings: "打開系統設定",
        permAccessibility: "輔助使用",
        permScreenRecording: "螢幕錄製",
        permFullDisk: "完整磁碟取用權限",
        permFilesAndFolders: "檔案與資料夾",
        permNotifications: "通知",
        permAutomationFinder: "Finder 自動化",
        permAutomationTerminal: "終端機自動化",
        permAudioCapture: "App 音訊",
        explainAccessibility: "讓功能回應點按和按鍵，並移動視窗。",
        explainScreenRecording: "讓功能顯示視窗縮圖並讀取螢幕上的文字。",
        explainFullDisk: "讓清理器和解除安裝器在任何位置找到殘留檔案。",
        explainFilesAndFolders: "允許 WhatsApp 下載項目清理和實驗性整理器檢查下載項目資料夾。",
        explainNotifications: "讓 App 就你開啟的警示發出通知。",
        explainAutomationFinder: "讓 App 請 Finder 替你移動檔案。",
        explainAutomationTerminal: "讓 Homebrew 指令在終端機中打開。",
        explainAudioCapture: "讓混音器調整每個 App 的音量，並讓螢幕錄製包含 Mac 的聲音。",
        descSwitcher: "帶預覽地切換 App 和視窗",
        descDockPreview: "游標停在 Dock 上時顯示視窗預覽",
        descDockClick: "點按 Dock 圖像以縮到最小或切換視窗",
        descWindowMaximizer: "綠色按鈕改為最大化而非全螢幕",
        descAutoQuit: "最後一個視窗關閉時結束 App",
        descScrollInverter: "反轉滑鼠滾輪方向",
        descSmoothScroll: "順暢帶動畫的滑鼠捲動",
        descMouseNavigation: "滑鼠側鍵前進後退",
        descMiddleClick: "三指點按變成中鍵點按",
        descKeyboardDebounce: "忽略不小心的重複按鍵",
        descClipboardHistory: "在本機保存拷貝歷史",
        descPastePlain: "貼上無格式文字",
        descFinderCutPaste: "在 Finder 中剪下和貼上檔案",
        descShelf: "把檔案放到選單列上暫存",
        descURLCleaner: "拷貝的連結自動移除追蹤參數",
        descMixer: "每個 App 獨立的音量滑桿",
        descSoundOutputSwitcher: "用快速鍵切換聲音輸出",
        descMicMute: "隨時隨地將麥克風靜音",
        descKeepAwake: "需要時讓 Mac 保持喚醒",
        descColorPicker: "擷取螢幕上的任何顏色",
        descScreenOCR: "拷貝螢幕上任何內容的文字或 QR 碼",
        descCleaningMode: "鎖定鍵盤和螢幕以便清潔",
        descMediaTools: "轉換媒體與合併 PDF 檔案",
        descCleaner: "清理快取和垃圾檔案",
        descUninstaller: "移除 App 並清除殘留",
        descHomebrew: "讓 Homebrew 套件保持最新",
        descMonitorCPU: "處理器使用率與溫度",
        descMonitorGPU: "圖形使用率與溫度",
        descMonitorMemory: "記憶體使用量與壓力",
        descMonitorNetwork: "網路速度與用量",
        descMonitorDisk: "磁碟空間與活動",
        descMonitorPower: "電池、功耗與充電",
        installButton: "安裝",
        uninstallButton: "解除安裝",
        footerNote: "解除安裝不會刪除任何資料：功能只是從 App 中消失並不再載入。隨時重新安裝，一切都會原樣恢復。",
        restartNote: "本次工作階段解除安裝的功能在 App 重新啟動前仍會駐留。立即重新啟動即可將它們從記憶體卸下。",
        restartButton: "立即重新啟動",
        installAllButton: "全部安裝",
        uninstallAllButton: "全部解除安裝",
        energyIdle: "閒置時零負擔",
        energyMouse: "監聽滑鼠",
        energyPointer: "監聽游標輸入",
        energyKeyboard: "監聽鍵盤",
        energyInputs: "監聽滑鼠與鍵盤",
        energyPeriodic: "按間隔檢查",
        energyHelp: "功能開啟期間的負擔。解除安裝後完全不載入。",
        explainAppManagement: "允許更新取代或移除透過套件管理器安裝的 App。",
        onboardingSelectedPermissionsTitle: "所選功能需要的權限",
        onboardingNoSelectedPermissions: "完成設定不需要授予任何權限。",
        onboardingOtherPermissionsTitle: "其他權限",
        onboardingOtherPermissionsCaption: "可選。你可以現在授予，也可以等功能需要時再授予。"
    )

    static let zhHK = FeatureHubStrings(
        pageTitle: "功能",
        intro: "選擇要加入工作區的工具。移出後工具會停止運作，操作入口會隱藏。已儲存的設定會保留，仍可在「功能」查看摘要。",
        tabFeatures: "功能",
        tabPermissions: "權限",
        activeCountFormat: "已安裝 %1$d 項，共 %2$d 項",
        monitorAllOffNote: "全部關閉後，監察器會從面板和選單列消失。",
        titleMouseNavigation: "側鍵",
        groupMonitor: "系統監察器",
        groupWindowsDesktop: "視窗及桌面",
        groupInputDevices: "輸入裝置",
        groupGlobalEntry: "全局入口",
        groupClipboardFiles: "剪貼板與檔案",
        groupCapture: "擷取及內容處理",
        groupSoundDevices: "聲音及裝置",
        groupFocusEnergy: "專注及節能",
        groupAppManagement: "App 管理",
        permissionsIntro: "每項權限嘅作用，以及哪些功能會使用佢。其他存取權限只會喺使用相關功能時要求。",
        usedByFormat: "使用者：%@",
        usedByNone: "目前沒有已開啟的功能使用此權限。",
        unusedBanner: "你已授予此權限，但沒有已開啟的功能需要它。如願意，可在系統設定中撤銷。",
        statusGranted: "已授予",
        statusMissing: "未授予",
        statusUnknown: "App 無法檢查此項",
        requestButton: "要求",
        openSystemSettings: "打開系統設定",
        permAccessibility: "輔助使用",
        permScreenRecording: "螢幕錄影",
        permFullDisk: "完整磁碟存取",
        permFilesAndFolders: "檔案與資料夾",
        permNotifications: "通知",
        permAutomationFinder: "Finder 自動化",
        permAutomationTerminal: "終端機自動化",
        permAudioCapture: "App 音訊",
        explainAccessibility: "讓功能回應點按和按鍵，並移動視窗。",
        explainScreenRecording: "讓功能顯示視窗縮圖並讀取螢幕上的文字。",
        explainFullDisk: "讓清理器和移除器在任何位置找到殘留檔案。",
        explainFilesAndFolders: "允許 WhatsApp 下載項目清理和實驗性整理器檢查下載項目資料夾。",
        explainNotifications: "讓 App 就你開啟的警示發出通知。",
        explainAutomationFinder: "讓 App 請 Finder 代你移動檔案。",
        explainAutomationTerminal: "讓 Homebrew 指令在終端機開啟。",
        explainAudioCapture: "讓混音器調整每個 App 的音量，並讓螢幕錄製包含 Mac 的聲音。",
        descSwitcher: "帶預覽地切換 App 和視窗",
        descDockPreview: "游標停在 Dock 上時顯示視窗預覽",
        descDockClick: "點按 Dock 圖示以縮到最小或切換視窗",
        descWindowMaximizer: "綠色按鈕改為最大化而非全螢幕",
        descAutoQuit: "最後一個視窗關閉時結束 App",
        descScrollInverter: "反轉滑鼠滾輪方向",
        descSmoothScroll: "順暢帶動畫的滑鼠捲動",
        descMouseNavigation: "滑鼠側鍵前進後退",
        descMiddleClick: "三指點按變成中鍵點按",
        descKeyboardDebounce: "忽略不小心的重複按鍵",
        descClipboardHistory: "在本機保存複製歷史",
        descPastePlain: "貼上無格式文字",
        descFinderCutPaste: "在 Finder 剪下和貼上檔案",
        descShelf: "把檔案放到選單列暫存",
        descURLCleaner: "複製的連結自動移除追蹤參數",
        descMixer: "每個 App 獨立的音量滑桿",
        descSoundOutputSwitcher: "用快速鍵切換聲音輸出",
        descMicMute: "隨時隨地將咪高風靜音",
        descKeepAwake: "需要時讓 Mac 保持喚醒",
        descColorPicker: "擷取螢幕上的任何顏色",
        descScreenOCR: "複製螢幕上任何內容的文字或 QR 碼",
        descCleaningMode: "鎖定鍵盤和螢幕以便清潔",
        descMediaTools: "轉換媒體與合併 PDF 檔案",
        descCleaner: "清理快取和垃圾檔案",
        descUninstaller: "移除 App 並清除殘留",
        descHomebrew: "讓 Homebrew 套件保持最新",
        descMonitorCPU: "處理器使用率與溫度",
        descMonitorGPU: "圖像使用率與溫度",
        descMonitorMemory: "記憶體使用量與壓力",
        descMonitorNetwork: "網絡速度與用量",
        descMonitorDisk: "磁碟空間與活動",
        descMonitorPower: "電池、功耗與充電",
        installButton: "安裝",
        uninstallButton: "解除安裝",
        footerNote: "解除安裝不會刪除任何資料：功能只是從 App 消失並不再載入。隨時重新安裝，一切都會原樣恢復。",
        restartNote: "本次工作階段解除安裝的功能在 App 重新啟動前仍會駐留。立即重新啟動即可將它們從記憶體卸下。",
        restartButton: "立即重新啟動",
        installAllButton: "全部安裝",
        uninstallAllButton: "全部解除安裝",
        energyIdle: "閒置時零負擔",
        energyMouse: "監聽滑鼠",
        energyPointer: "監聽游標輸入",
        energyKeyboard: "監聽鍵盤",
        energyInputs: "監聽滑鼠與鍵盤",
        energyPeriodic: "按間隔檢查",
        energyHelp: "功能開啟期間的負擔。解除安裝後完全不載入。",
        explainAppManagement: "允許更新取代或移除透過套件管理器安裝的 App。",
        onboardingSelectedPermissionsTitle: "所選功能需要嘅權限",
        onboardingNoSelectedPermissions: "完成設定唔需要授予任何權限。",
        onboardingOtherPermissionsTitle: "其他權限",
        onboardingOtherPermissionsCaption: "可選。你可以而家授予，亦可以等功能需要時再授予。"
    )
}

/// Module availability is separate from a feature's saved behavior and hotkey switches.
struct ModuleWorkspaceStrings {
    var intro = "Enable the modules you need. Background behavior and shortcuts follow their saved settings. Enabling a module does not turn on every behavior. Adjust those switches in each module’s settings."
    var add = "Enable"
    var remove = "Disable"
    var addAll = "Enable all"
    var removeAll = "Disable all"
    var footer = "Disabling a module stops its background behavior and shortcuts and keeps its data and preferences. Saved behavior settings and key combinations remain readable here. Enable it again to edit all settings."
    var activeFormat = "%1$d of %2$d modules enabled"
    var inactiveTitle = "Disabled"
    var inactiveNote = "This module is disabled. Its background behavior and shortcuts are stopped, and its data and settings are kept. Below is a read-only summary of saved behavior settings and key combinations. Enable it to edit all settings."
    var savedBehaviors = "Saved behavior and action settings"
    var savedShortcuts = "Saved key combinations"
    var on = "On (saved)"
    var off = "Off (saved)"
    var noSeparateSwitch = "No separate behavior switch"
    var noMetrics = "No metrics shown in the menu bar"
    var addMetrics = "Add metrics…"
    var inactiveMonitor = "System monitoring is disabled. Enable it, then choose which metrics to show."
    var deferredAppearance = "Appearance choices below are saved and take effect after you add a metric."
    var showMenuBarMetric = "Show in menu bar"
    var hideMenuBarMetric = "Hide from menu bar"
    private var actionCountFormat = "Saved: %1$d of %2$d actions on"

    func actionCount(_ enabled: Int, _ total: Int) -> String {
        String(format: actionCountFormat, enabled, total)
    }

    init(_ language: AppLanguage) {
        switch language {
        case .zhHans:
            showMenuBarMetric = "在菜单栏中显示"
            hideMenuBarMetric = "从菜单栏隐藏"
            intro = "按需启用模块。后台行为和快捷键按已保存的设置运行，启用模块不会打开其中所有行为。各项行为开关可在模块设置中单独调整。"
            add = "启用"
            remove = "关闭"
            addAll = "全部启用"
            removeAll = "全部关闭"
            footer = "关闭模块会停止其后台行为和快捷键，并保留数据与设置。仍可在这里查看已保存的运行设置与按键组合，重新启用后可编辑完整设置。"
            activeFormat = "已启用 %1$d 项，共 %2$d 项"
            inactiveTitle = "已关闭"
            inactiveNote = "此模块已关闭，后台行为和快捷键已停止，数据与设置仍保留。以下为已保存的运行设置与按键组合的只读摘要。启用后可编辑完整设置。"
            savedBehaviors = "已保存的运行与动作设置"
            savedShortcuts = "已保存的按键组合"
            on = "开启（保存值）"
            off = "关闭（保存值）"
            noSeparateSwitch = "没有独立运行开关"
            noMetrics = "尚未在菜单栏显示指标"
            addMetrics = "添加指标…"
            inactiveMonitor = "系统监控已关闭。请先启用，再选择要显示的指标。"
            deferredAppearance = "以下外观选项会保留，在添加指标后生效。"
            actionCountFormat = "已保存：%2$d 项动作中 %1$d 项开启"
        case .de:
            showMenuBarMetric = "In Menüleiste anzeigen"
            hideMenuBarMetric = "Aus Menüleiste ausblenden"
            intro = "Aktiviere die benötigten Module. Hintergrundverhalten und Kurzbefehle folgen den gespeicherten Einstellungen. Das Aktivieren eines Moduls schaltet nicht jedes Verhalten ein. Passe diese Schalter in den Moduleinstellungen einzeln an."
            add = "Aktivieren"
            remove = "Deaktivieren"
            addAll = "Alle aktivieren"
            removeAll = "Alle deaktivieren"
            footer = "Das Deaktivieren eines Moduls stoppt sein Hintergrundverhalten und seine Kurzbefehle. Daten und Einstellungen bleiben erhalten. Gespeicherte Verhaltenseinstellungen und Tastenkombinationen bleiben hier einsehbar. Aktiviere es erneut, um alle Einstellungen zu bearbeiten."
            activeFormat = "%1$d von %2$d Modulen aktiviert"
            inactiveTitle = "Deaktiviert"
            inactiveNote = "Dieses Modul ist deaktiviert. Hintergrundverhalten und Kurzbefehle sind gestoppt, Daten und Einstellungen bleiben erhalten. Unten steht eine schreibgeschützte Übersicht der gespeicherten Verhaltenseinstellungen und Tastenkombinationen. Aktiviere es, um alle Einstellungen zu bearbeiten."
            savedBehaviors = "Gespeichertes Verhalten und Aktionen"
            savedShortcuts = "Gespeicherte Tastenkombinationen"
            on = "Ein (gespeichert)"
            off = "Aus (gespeichert)"
            noSeparateSwitch = "Kein separater Betriebsschalter"
            noMetrics = "Keine Messwerte in der Menüleiste"
            addMetrics = "Messwerte hinzufügen…"
            inactiveMonitor = "Die Systemüberwachung ist deaktiviert. Aktiviere sie und wähle dann die anzuzeigenden Messwerte."
            deferredAppearance = "Die folgenden Darstellungsoptionen werden gespeichert und nach dem Hinzufügen eines Messwerts angewendet."
            actionCountFormat = "Gespeichert: %1$d von %2$d Aktionen ein"
        case .fr:
            showMenuBarMetric = "Afficher dans la barre des menus"
            hideMenuBarMetric = "Masquer dans la barre des menus"
            intro = "Activez les modules nécessaires. Le fonctionnement en arrière-plan et les raccourcis suivent les réglages enregistrés. Activer un module n’active pas tous ses comportements. Réglez chaque interrupteur dans les réglages du module."
            add = "Activer"
            remove = "Désactiver"
            addAll = "Tout activer"
            removeAll = "Tout désactiver"
            footer = "Désactiver un module arrête son fonctionnement en arrière-plan et ses raccourcis. Ses données et réglages sont conservés. Les réglages de comportement et combinaisons de touches enregistrés restent consultables ici. Réactivez-le pour modifier tous ses réglages."
            activeFormat = "%1$d modules sur %2$d activés"
            inactiveTitle = "Désactivé"
            inactiveNote = "Ce module est désactivé. Son fonctionnement en arrière-plan et ses raccourcis sont arrêtés. Ses données et réglages sont conservés. Le résumé ci-dessous présente en lecture seule les réglages de comportement et combinaisons de touches enregistrés. Activez-le pour modifier tous ses réglages."
            savedBehaviors = "Comportement et actions enregistrés"
            savedShortcuts = "Combinaisons de touches enregistrées"
            on = "Activé (enregistré)"
            off = "Désactivé (enregistré)"
            noSeparateSwitch = "Aucun interrupteur de fonctionnement distinct"
            noMetrics = "Aucune mesure affichée dans la barre des menus"
            addMetrics = "Ajouter des mesures…"
            inactiveMonitor = "La surveillance du système est désactivée. Activez-la, puis choisissez les mesures à afficher."
            deferredAppearance = "Les options d’apparence ci-dessous sont enregistrées et prendront effet après l’ajout d’une mesure."
            actionCountFormat = "Enregistré : %1$d actions sur %2$d activées"
        case .es:
            showMenuBarMetric = "Mostrar en la barra de menús"
            hideMenuBarMetric = "Ocultar de la barra de menús"
            intro = "Activa los módulos que necesites. El funcionamiento en segundo plano y los atajos siguen los ajustes guardados. Activar un módulo no activa todos sus comportamientos. Ajusta cada interruptor en los ajustes del módulo."
            add = "Activar"
            remove = "Desactivar"
            addAll = "Activar todos"
            removeAll = "Desactivar todos"
            footer = "Desactivar un módulo detiene su funcionamiento en segundo plano y sus atajos. Sus datos y ajustes se conservan. Los ajustes de comportamiento y las combinaciones de teclas guardados siguen disponibles aquí. Vuelve a activarlo para editar todos sus ajustes."
            activeFormat = "%1$d de %2$d módulos activados"
            inactiveTitle = "Desactivado"
            inactiveNote = "Este módulo está desactivado. Su funcionamiento en segundo plano y sus atajos están detenidos, y sus datos y ajustes se conservan. Abajo se muestra un resumen de solo lectura de los ajustes de comportamiento y las combinaciones de teclas guardados. Actívalo para editar todos sus ajustes."
            savedBehaviors = "Comportamiento y acciones guardados"
            savedShortcuts = "Combinaciones de teclas guardadas"
            on = "Activado (guardado)"
            off = "Desactivado (guardado)"
            noSeparateSwitch = "Sin interruptor de funcionamiento independiente"
            noMetrics = "No se muestran métricas en la barra de menús"
            addMetrics = "Añadir métricas…"
            inactiveMonitor = "La monitorización del sistema está desactivada. Actívala y elige las métricas que quieres mostrar."
            deferredAppearance = "Las opciones de apariencia siguientes se guardan y se aplicarán cuando añadas una métrica."
            actionCountFormat = "Guardado: %1$d de %2$d acciones activadas"
        case .ja:
            showMenuBarMetric = "メニューバーに表示"
            hideMenuBarMetric = "メニューバーから非表示"
            intro = "必要なモジュールを有効にしてください。バックグラウンド動作とショートカットは保存済みの設定に従います。モジュールを有効にしても、すべての動作がオンになるわけではありません。各動作のスイッチはモジュールの設定で個別に調整できます。"
            add = "有効にする"
            remove = "無効にする"
            addAll = "すべて有効にする"
            removeAll = "すべて無効にする"
            footer = "モジュールを無効にするとバックグラウンド動作とショートカットが停止し、データと設定は保持されます。保存済みの動作設定とキーの組み合わせはここで確認できます。すべての設定を編集するには再度有効にしてください。"
            activeFormat = "%2$d 件中 %1$d 件のモジュールが有効"
            inactiveTitle = "無効"
            inactiveNote = "このモジュールは無効です。バックグラウンド動作とショートカットは停止し、データと設定は保持されています。以下は保存済みの動作設定とキーの組み合わせの読み取り専用の概要です。すべての設定を編集するには有効にしてください。"
            savedBehaviors = "保存済みの動作とアクション"
            savedShortcuts = "保存済みのキーの組み合わせ"
            on = "オン（保存済み）"
            off = "オフ（保存済み）"
            noSeparateSwitch = "個別の動作スイッチなし"
            noMetrics = "メニューバーに指標が表示されていません"
            addMetrics = "指標を追加…"
            inactiveMonitor = "システム監視は無効です。有効にしてから、表示する指標を選んでください。"
            deferredAppearance = "以下の表示設定は保存され、指標を追加すると適用されます。"
            actionCountFormat = "保存済み：%2$d 件中 %1$d 件のアクションがオン"
        default:
            break
        }
    }
}
