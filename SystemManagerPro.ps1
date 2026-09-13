#requires -Version 5.1

# --- YÖNETİCİ YETKİ KONTROLÜ ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $currentModule = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($currentModule -match '\.exe$' -and $currentModule -notmatch 'powershell') {
        Start-Process $currentModule -Verb RunAs
    } elseif ($PSCommandPath) {
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    Exit
}

Add-Type -AssemblyName PresentationFramework

function Brush([string]$hex) {
    return [System.Windows.Media.BrushConverter]::new().ConvertFromString($hex)
}
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- WINGET YOLU TESPİTİ ---
$global:wingetExe = "winget.exe"
$possibleWingetPaths = @(
    (Get-Command winget.exe -ErrorAction SilentlyContinue).Source,
    (Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\winget.exe")
)
foreach ($p in $possibleWingetPaths) {
    if ($p -and (Test-Path $p)) {
        $global:wingetExe = $p
        break
    }
}

# --- HD LOGO MOTORU & Ã–NBELLEK (V28 - YEREL LOGOLAR KLASÃ–RÃœ & DOÄRULANMIÅ MOTOR) ---
$global:iconCacheDir = Join-Path $env:TEMP "AppInstallerIconsHD_v28_2026"
if (!(Test-Path $global:iconCacheDir)) { New-Item -ItemType Directory -Path $global:iconCacheDir -Force | Out-Null }

# Cache globe and store bitmap icons for compact badges
$global:bmpGlobeLogo = $null
$global:bmpStoreLogo = $null
try {
    $globePath = if (Test-Path "c:\projem\logolar\globe_with_meridians_3d.png") { "c:\projem\logolar\globe_with_meridians_3d.png" } elseif (Test-Path "c:\projem\logolar\modern_web_installer.png") { "c:\projem\logolar\modern_web_installer.png" } else { "" }
    if ($globePath) {
        $bmpG = New-Object System.Windows.Media.Imaging.BitmapImage
        $bmpG.BeginInit(); $bmpG.UriSource = [Uri]$globePath; $bmpG.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad; $bmpG.EndInit(); $bmpG.Freeze()
        $global:bmpGlobeLogo = $bmpG
    }
    $storePath = if (Test-Path "c:\projem\logolar\microsoft_store.png") { "c:\projem\logolar\microsoft_store.png" } elseif (Test-Path "c:\projem\logolar\ms_store.png") { "c:\projem\logolar\ms_store.png" } else { "" }
    if ($storePath) {
        $bmpS = New-Object System.Windows.Media.Imaging.BitmapImage
        $bmpS.BeginInit(); $bmpS.UriSource = [Uri]$storePath; $bmpS.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad; $bmpS.EndInit(); $bmpS.Freeze()
        $global:bmpStoreLogo = $bmpS
    }
} catch {}

$global:memoryIconCache = @{}

# Yerel logolar klasÃ¶rÃ¼nÃ¼n tespiti
$global:localLogosDir = $null
$scriptLogoDir = if ($PSScriptRoot) { Join-Path $PSScriptRoot "logolar" } else { $null }
$procLogoDir = try {
    $p = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($p) { Join-Path (Split-Path -Parent $p) "logolar" } else { $null }
} catch { $null }

$possibleLogoDirs = @(
    "C:\projem\logolar",
    $scriptLogoDir,
    $procLogoDir
)
foreach ($d in $possibleLogoDirs) {
    if ($d -and (Test-Path $d)) {
        $global:localLogosDir = $d
        break
    }
}

# C:\projem\logolar klasÃ¶rÃ¼ndeki kullanÄ±cÄ± logolarÄ±nÄ±n birebir haritasÄ±
$global:localLogosMap = @{
    "TikTok"                              = @("tiktok.png")
    "Threads"                             = @("threads.png")
    "Snapchat"                            = @("snapchat.png")
    "LinkedIn"                            = @("linkedin.png")
    "Pinterest"                           = @("pinterest.png")
    "Kayıt Defteri Düzenleyicisi (Regedit)" = @("regedit.png")
    "Instagram"                           = @("instagram.png")
    "Facebook"                            = @("facebook.png")
    "X (Twitter)"                         = @("x_corp.png")
    "Telegram Desktop"                    = @("telegram.png")
    "Netflix"                             = @("netflix.png")
    "Amazon Prime Video"                  = @("prime_video.png")
    "Disney+"                             = @("disney_plus.png")
    "Apple TV"                            = @("apple_tv.png")
    "Microsoft 365"                       = @("960px-Microsoft_365_2022.svg.png", "microsoft_365.png")
    "TV+"                                 = @("tv_plus.png")
    "TOD TV"                              = @("tod_tv.png")
    "beIN CONNECT"                        = @("bein_connect.png")
    "Ubisoft Connect"                  = @("064e3a5648fb4a7f911155bd81f87fd2.png")
    "Epic Games"                       = @("1280px-Epic_Games_logo.svg.png")
    "EA App"                           = @("200.png")
    "SteelSeries GG"                   = @("209-2090115_chicago-march-28-ste.png", "4286347-middle.png")
    "Realtek Audio Control"            = @("2379.TW-3cbb6e43.png")
    "Battle.net"                       = @("256x256.png")
    "Intel Driver Support"             = @("30997-256x256x32.png")
    "Kaspersky"                        = @("330px-Kaspersky_icon.svg.png")
    "Adobe Acrobat Reader"             = @("3840px-Adobe_Acrobat_Reader_icon.png")
    "Google Chrome"                    = @("3840px-Google_Chrome_icon_Februa.png")
        "Visual Studio Community"          = @("330px-Visual_Studio_Icon_2026.sv.png", "3840px-Visual_Studio_Icon_2022.s.png")
    "Visual C++ 2015-2022 (x64)"          = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2015-2022 (x86)"          = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2013 (x64)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2013 (x86)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2012 (x64)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2012 (x86)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2010 (x64)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2010 (x86)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2008 (x64)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2008 (x86)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2005 (x64)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "Visual C++ 2005 (x86)"               = @("visual_studio_2019.png", "visual_cpp.png")
    "WhatsApp"                         = @("3840px-WhatsApp.svg.png")
    "Windsurf Editor"                  = @("8xk80rgc0hqe1.png")
    "Adobe Creative Cloud"             = @("adobe-creative-cloud.png")
    "Google Antigravity"               = @("antigravity-icon__full-color.png")
    "CrystalDiskMark"                  = @("apps.28465.13510798887699839.f53.png")
    "Microsoft PC Manager"             = @("apps.8039.14298090620665013.d1d2.png")
    "Avast Free Antivirus"             = @("Avast_Software_white_logo.png")
    "Bitwarden"                        = @("bitwarden_macos_bigsur_icon_1903.png")
    "Core Temp"                        = @("core-temp-logo.png")
    "CPU-Z"                            = @("CPU-Z_icon_new.png", "CPU-Z_icon.png")
    "Driver Booster"                   = @("db_96.png")
    "Display Driver Uninstaller (DDU)" = @("ddu_logo3_17_49.png")
    "Mozilla Firefox"                  = @("Firefox_logo,_2017.png")
    "GOM Player"                       = @("GOM_Player_23385.png")
    "CCleaner"                         = @("image.png")
    "CrystalDiskInfo"                  = @("images.png")
    "Microsoft PowerToys"              = @("MicrosoftPowerToyslogo.png")
    "Microsoft Edge"                   = @("Microsoft_Edge_logo_2019.png")
    "MSI Afterburner + RTSS"           = @("msi_afterburner_icon_2048_best_b.png", "png-transparent-overclocking-gre.png")
    "Opera"                            = @("opera_browser_logo_icon_152972.png")
    "Brave Browser"                   = @("brave.png")
    "Revo Uninstaller"                 = @("revo.png", "images (1).png")
    "TreeSize Free"                    = @("TreeSize-Icon-256.png")
    "uTorrent"                         = @("UTorrent_logo.png")
    "AnyDesk"                          = @("_solution_logo_05092023_38045001.png")
    "TeamViewer"                       = @("teamwiever.png", "d24ec23b89284d31515cc2d8af3386e9.png")
    "TeamViewer QuickSupport"          = @("teamwiever.png", "d24ec23b89284d31515cc2d8af3386e9.png")
    "TeamViewer Host"                  = @("teamwiever.png", "d24ec23b89284d31515cc2d8af3386e9.png")
    "Blitz"                            = @("4267635.png")
    "Riot Games Client"                = @("riotgames.png")
    "Chrome Remote Desktop"            = @("chromeremotedesktop.png")
    "Cloudflare WARP"                  = @("Cloudflare_Logo.png", "cloudflare_warp.png", "cloudflare.png")
    "Java Runtime Environment"         = @("java.png")
    "Java JDK 21"                      = @("java.png")
    "WinRAR"                           = @("21764-256x256x32.png")
    "Intel Graphics Software"          = @("apps.22186.14090896052071218.a5d.png")
    "OpenAI Codex CLI"                 = @("codex-icon.png")
    "SplitWire Turkey"                 = @("splitwire-logo-128.png", "splitwire.png")
    "XBOX"                             = @("xbox.png")
    "Xbox Uygulaması"                  = @("xbox.png")
}

$global:embeddedAppIcons = @{
    "adobecreativecloud" = "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"
    "pcmanager" = "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"
    "utorrent" = "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"
    "corsair" = "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"
    "revo" = "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"
    "treesize" = "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"
    "driver-booster" = "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"
    "anydesk" = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAOzSURBVHhe7ZzLTttAGEZTqTwRK2yiAA4g8iC8QKWuSi/qotCKNwWT0gVddSobfiDG8XVmPJdzpG+TKHjkcyCsPJsBAAAAAAAAAAAAAAAAAAAAAAAAAABMyTrbv8yz5Ff1dZsUZ1hn6VX1dTDMzTL5rFYHqtjdcfqt+r4NXp8hXyZfqu+DIcobf7ZQ98f75aaI4M0ZzhZEYAO58X+O99XdMi1nO4KtZyACs9TdeNsR5Fl60XgGIjBDk3xbEeRZ+qnTGYhAL13km47gUf5B9zMQgR76yN8QoCkCtVi8Xzf82d82ItDAEPkbAjREcH+azNXqUD2czFVec52mEcEIxsjfEDAyAnW+u1N8fuhZiGAAOuRvCBgZQcFttve16/8A1RFBD3TKlxGBJ5iQLyMCxzEpX0YEjmJDvowIHMOmfBkROMIU8mVEMDFTypcRwUS4IF9GBJZxSb6MCCzhonwZERjGZfkyIjCED/JlRKAZn+TLiEATPsqXuRBB8RlvI/BZvowIBhKCfBkR9CQk+TIi6EiI8mVE0ELI8mVEsIUY5MuIoEJM8mVE8ESM8mXRRxCzfFm0ESD/ZdFFgPy3iyYC5G9f8BEgv33BRoD87gsuAuT3XzARIH/4vI8A+ePnbQTI17fnCDIdETw+l7B6jbb1iiDPksviwEMuxOonERSPtVWz2bvqPe/K7VHy8e/J/N+65hptkzMUj7VtPMNdlvwgAL3TF0D6oQjgd8012iZnuDnau249w81R8RUw7DuHba688WfjvwLkGYVDfjFF/u0y+V79uVvJiWD09Mof5mKQfIEIhs97+QIR9F8w8gUi6L7g5AtE0L5g5QtEsH3ByxeI4O2ikS8Qwcuiky8QQcTyhZgjiF6+EGMEyK8QUwTI30IMESC/hZAjQH5HQowA+T0JKQLkDySECJA/Ep8jQL4mfIwA+ZrxKQLkG8KHCJBvGJcjQL4lXIwA+ZZxKQLkT4QLESB/YqaMAPmOMEUEyHcMmxEg31FsRIB8xzEZAfI9wUQEyPcMnREg31N0RKBDvlos3q+z9GLoM5OQP4IxEeiQX3B/mszV6lA9nMxVXnOdpiFfA0Mi0CW/QJ3v7hSPeev7FwD5GukTgU75r+nzrD7kG6BLBKbkC10iQL5BmiIwLV9oigD5FqiLwJZ8oS4C5FtEIihuum35gkTwfAbk26WMYHVQ3njb8oUygqczIH8C8iy9Kh6/Wn3dJvky/Zkv966rrwMAAAAAAAAAAAAAAAAAAAAAAABY5j9zLa/hbk8NtAAAAABJRU5ErkJggg=="
    "adobereader" = "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"
}

$global:b64MenuBefore = "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"
$global:b64MenuAfter = "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"

function Get-WpfIconSource([string]$slug, [string]$altDomain, [string]$directUrl, [string]$appName = "") {
    $cacheKey = if ($appName) { "app:" + $appName } elseif ($slug) { "slug:" + $slug } else { "url:" + $directUrl }
    if ($global:memoryIconCache.ContainsKey($cacheKey) -and $global:memoryIconCache[$cacheKey]) {
        return $global:memoryIconCache[$cacheKey]
    }

        # 0. Öncelik: logolar klasöründeki kullanıcı logoları
    if ($appName -and $global:localLogosDir -and $global:localLogosMap.ContainsKey($appName)) {
        $candidates = $global:localLogosMap[$appName]
        foreach ($fn in $candidates) {
            $localFile = Join-Path $global:localLogosDir $fn
            if (Test-Path $localFile) {
                try {
                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bmp.BeginInit()
                    $bmp.UriSource = [Uri]$localFile
                    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $bmp.EndInit()
                    $bmp.Freeze()
                    $global:memoryIconCache[$cacheKey] = $bmp
                    return $bmp
                } catch {}
            }
        }
    }

    # 1. Ã–ncelik: Dahili GÃ¶mÃ¼lÃ¼ HD Ä°konlar (SÄ±fÄ±r Gecikme, %100 Orijinal Kalite)
    if ($slug -and $global:embeddedAppIcons -and $global:embeddedAppIcons.ContainsKey($slug)) {
        try {
            $raw = [Convert]::FromBase64String($global:embeddedAppIcons[$slug])
            $ms = New-Object System.IO.MemoryStream(,$raw)
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.StreamSource = $ms
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.EndInit()
            $bmp.Freeze()
            $global:memoryIconCache[$cacheKey] = $bmp
            return $bmp
        } catch {}
    }

    # 2. Base64 Data URI DesteÄŸi
    if ($directUrl -and $directUrl.StartsWith("data:image/")) {
        try {
            $commaIdx = $directUrl.IndexOf(",")
            if ($commaIdx -gt 0) {
                $b64 = $directUrl.Substring($commaIdx + 1)
                $raw = [Convert]::FromBase64String($b64)
                $ms = New-Object System.IO.MemoryStream(,$raw)
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.StreamSource = $ms
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bmp.EndInit()
                $bmp.Freeze()
                $global:memoryIconCache[$cacheKey] = $bmp
                return $bmp
            }
        } catch { return $null }
    }

    if ([string]::IsNullOrEmpty($slug) -and [string]::IsNullOrEmpty($altDomain) -and [string]::IsNullOrEmpty($directUrl)) { return $null }

    $key = if ($slug) { $slug } elseif ($directUrl) { [System.IO.Path]::GetFileNameWithoutExtension($directUrl.Split("?")[0]) } else { $altDomain }
    $cacheFile = Join-Path $global:iconCacheDir "$key.png"

    # 3. Disk Ã–nbelleÄŸini DoÄŸrula
    if (Test-Path $cacheFile) {
        try {
            $fi = Get-Item $cacheFile
            if ($fi.Length -gt 200) {
                $bytes = [System.IO.File]::ReadAllBytes($cacheFile)
                if ($bytes[0] -ne 60) { # 60 = '<'
                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bmp.BeginInit()
                    $bmp.UriSource = [Uri]$cacheFile
                    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $bmp.EndInit()
                    $bmp.Freeze()
                    $global:memoryIconCache[$cacheKey] = $bmp
                    return $bmp
                }
            }
            Remove-Item $cacheFile -Force -ErrorAction SilentlyContinue
        } catch {
            Remove-Item $cacheFile -Force -ErrorAction SilentlyContinue
        }
    }

    # 4. Ä°ndirilebilir Kaynaklar
    $urls = @()
    if ($directUrl) { $urls += $directUrl }
    if ($slug) {
        $urls += "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/$slug.png"
        $urls += "https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/$slug.png"
    }
    if ($altDomain) {
        $urls += "https://www.google.com/s2/favicons?domain=$altDomain&sz=128"
        $urls += "https://icon.horse/icon/$altDomain"
    }

    foreach ($u in $urls) {
        try {
            $req = [System.Net.HttpWebRequest]::Create($u)
            $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
            if ($u -match "wikimedia\.org") { $req.Referer = "https://commons.wikimedia.org/" }
            $req.Timeout = 6000
            $res = $req.GetResponse()
            $str = $res.GetResponseStream()

            $ms = New-Object System.IO.MemoryStream
            $str.CopyTo($ms)
            $res.Close(); $str.Close()

            $raw = $ms.ToArray()
            $ms.Close()

            if ($raw.Length -lt 200) { continue }
            if ($raw[0] -eq 60) { continue }

            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $ms2 = New-Object System.IO.MemoryStream(,$raw)
            $bmp.StreamSource = $ms2
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.EndInit()
            $bmp.Freeze()

            [System.IO.File]::WriteAllBytes($cacheFile, $raw)
            $global:memoryIconCache[$cacheKey] = $bmp
            return $bmp
        } catch {}
    }
    return $null
}
# --- UYGULAMA HAVUZU ---

# ---------------------------------------------------------
# KULLANICI AYARLARI VE KAYNAK TERCİHİ MOTORU
# ---------------------------------------------------------
$global:settingsFile = "c:\projem\user_settings.json"
$global:preferredInstallSource = "Ask" # "Ask", "Normal", "Store"

function Load-UserSettings {
    if (Test-Path $global:settingsFile) {
        try {
            $json = Get-Content $global:settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($json.PreferredSource) {
                $global:preferredInstallSource = $json.PreferredSource
            }
        } catch {}
    }
}

function Save-UserSettings {
    try {
        @{ PreferredSource = $global:preferredInstallSource } | ConvertTo-Json | Set-Content $global:settingsFile -Encoding UTF8
    } catch {}
}

Load-UserSettings

$global:categoryHeaders = @{
    "Browsers" = "Tarayıcı, İletişim & Sosyal Medya"
    "Games"    = "Oyun Başlatıcıları, Medya & Dijital Yayın"
    "Dev"      = "Geliştirici Araçları & AI"
    "Hardware" = "Donanım, Disk & Sürücüler"
    "Security" = "Güvenlik & Antivirüs"
    "Tools"    = "Sistem, USB, Araçlar & Belgeler"
    "Runtimes" = ".NET & Visual C++ Kütüphaneleri"
}
$categoryHeaders = $global:categoryHeaders


# Full Application Knowledge Base for System Manager Pro
$global:appKnowledgeBase = @{
    "TikTok" = @{
        Details = "TikTok; kisa videolar, canli yayinlar, viral trendler ve eglenceli iceriklerin yer aldigi dunyanin en populer video platformudur. Resmi Microsoft Store masaustu istemcisi ile dikey ve yatay tam ekran video izleme, yorum yapma ve icerik arama deneyimi sunar."
        Publisher = "TikTok Pte. Ltd."
        OfficialUrl = "https://www.tiktok.com"
        Category = "Sosyal Medya & Video"
        WingetId = "9NH2GPH4JZS4"
        StoreId = "9NH2GPH4JZS4"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Kisa Video Platformu"
        Features = @(
            "Masaustu ekraninda akici ve tam cozunurlukte video akisi",
            "Muzikler, efektler ve viral akimlar arasinda anlik kesif",
            "Masaustu bildirimleri ve direkt mesajlasma destegi",
            "Düşük kaynak tüketimi ve hafif Store uygulama yapısı"
        )
    }
    "Threads" = @{
        Details = "Threads; Instagram ekibi tarafindan gelistirilen, fikirlerinizi, guncel dusuncelerinizi ve gorsel paylasimlarinizi paylasabileceginiz metin tabanli yeni nesil sosyal ag platformudur. Instagram hesabiyla aninda giris saglar."
        Publisher = "Instagram / Meta Platforms"
        OfficialUrl = "https://www.threads.net"
        Category = "Sosyal Ag & Sohbet"
        WingetId = "9MXBP1FB84CQ"
        StoreId = "9MXBP1FB84CQ"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Metin Tabanli Paylasim Agi"
        Features = @(
            "Instagram aginizla aninda baglanti ve otomatik profil aktarimi",
            "500 karaktere kadar metinler, fotograflar ve 5 dakikalik videolar",
            "Topluluk sohbetlerine ve guncel gundem tartismalarina katilim",
            "Modern, sade ve gozu yormayan karanlik tema arayuzu"
        )
    }
    "Snapchat" = @{
        Details = "Snapchat; arkadaslarinizla anlik fotograflar, kisa videolar ve artirilmis gerceklik (AR) lensleriyle iletisim kurmanizi saglayan resmi Windows masaustu uygulamasidir. Bilgisayar kamerasi ile eglenceli gorusmeler saglar."
        Publisher = "Snap Inc."
        OfficialUrl = "https://www.snapchat.com"
        Category = "Anlik Mesajlasma & Medya"
        WingetId = "9PF9RTKMMQ69"
        StoreId = "9PF9RTKMMQ69"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Kamera & Sohbet Uygulamasi"
        Features = @(
            "Bilgisayarinizin web kamerasiyla Snap cekme ve AR lensleri kullanma",
            "Arkadaslarla sesli ve goruntulu grup sohbetleri yapabilme",
            "Spotlight videolari ve kesfet hikayelerini tam ekranda izleme",
            "Masaustu bildirimleriyle mesajlari aninda yanitlama"
        )
    }
    "LinkedIn" = @{
        Details = "LinkedIn; kuresel profesyonel is agi, kariyer gelisimi ve is firsatlarinin tek merkezden yonetildigi resmi Windows istemcisidir. Sektorel haberler, is ilanlari ve profesyonel baglantilara kolayca ulasmanizi saglar."
        Publisher = "Microsoft Corporation / LinkedIn"
        OfficialUrl = "https://www.linkedin.com"
        Category = "Kariyer & Is Dunyasi"
        WingetId = "9WZDNCRFJ4Q7"
        StoreId = "9WZDNCRFJ4Q7"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Profesyonel Is Agi"
        Features = @(
            "Guncel is ilanlarina hizli basvuru ve kariyer firsatlari takibi",
            "Sektorel makaleler, gelismeler ve profesyonel ag paylasimlari",
            "Is arkadaslari ve profesyonel temaslarla direkt mesajlasma",
            "Profil goruntuleme ve baglanti istekleri bildirimleri"
        )
    }
    "Pinterest" = @{
        Details = "Pinterest; ev dekorasyonu, moda, yemek tarifleri, grafik tasarim ve yaratici fikirler gibi milyonlarca gorsel ilhami kesfetmenizi ve kendi panolarinizda toplamanizi saglayan gorsel kesif motorudur."
        Publisher = "Pinterest, Inc."
        OfficialUrl = "https://www.pinterest.com"
        Category = "Gorsel Tasarim & Kesif"
        WingetId = "9PFHDSF91B9R"
        StoreId = "9PFHDSF91B9R"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Gorsel Ilham ve Pano Uygulamasi"
        Features = @(
            "Yaratici fikirleri ve tasarim ilhamlarini kisisel panolara kaydetme",
            "Benzer gorselleri ve estetik konseptleri yapay zeka ile arama",
            "Yuksek cozunurluklu gorsel ve video koleksiyonlari olusturma",
            "Tasarimcilar ve yaratici ureticiler icin zengin ilham kutuphanesi"
        )
    }
    "Kayıt Defteri Düzenleyicisi (Regedit)" = @{
        Details = "Kayıt Defteri Düzenleyicisi (Regedit); Windows isletim sisteminin kok ayarlarini, sistem anahtarlarini, donanim yapilandirmalarini ve yazilim parametrelerini dogrudan duzenlemenizi saglayan en yetkili sistem yonetim aracidir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com"
        Category = "Sistem & Araclar"
        WingetId = "Microsoft.Windows.Regedit"
        InstallSource = "Windows Yerel Sistem Bileseni"
        Type = "Kok Sistem Yapilandirma Araci"
        Features = @(
            "Windows kayit defteri anahtarlarini (HKEY) arama, duzenleme ve yedekleme",
            "Sistem performans ve ince ayar optimizasyonlarini uygulama",
            "Reg uzantili yapilandirma dosyalarini ice/disa aktarma",
            "Yetkili yonetici izinleriyle dogrudan yerel calisma"
        )
    }
    "Telegram Desktop" = @{
        Details = "Telegram Desktop; guvenlik, hiz ve gizlilik odakli dunyanin en populer bulut tabanli mesajlasma istemcisidir. 2 GB'a kadar devasa dosya gonderimi, uctan uca sifreli sohbetler, genis grup ve kanallar, sesli/goruntulu gorusmeler ve bot ekosistemi sunar. Tum cihazlar arasinda aninda senkronize calisir."
        Publisher = "Telegram FZ-LLC"
        OfficialUrl = "https://desktop.telegram.org"
        Category = "Mesajlasma & Iletisim"
        WingetId = "Telegram.TelegramDesktop"
        InstallSource = "Win32 / Store Resmi Istemci"
        Type = "Masaustu Mesajlasma Uygulamasi"
        Features = @(
            "2 GB boyutuna kadar sinirsiz dosya ve medya aktarimi",
            "200.000 kisiye kadar dev gruplar ve sinirsiz kanallar",
            "Tum cihazlar (telefon, tablet, PC) arasinda aninda bulut senkronizasyonu",
            "Guclu bot entegrasyonlari ve gelismis gizlilik ayarlari"
        )
    }
    "Instagram" = @{
        Details = "Instagram; Meta tarafindan sunulan resmi Windows masaustu uygulamasidir. Reels videolari, Hikayeler (Stories), Direkt Mesajlar (DM), kesfet akisi ve arkadas paylasimlarini yuksek cozunurlukte bilgisayarinizda deneyimlemenizi saglar. Android emulator gerektirmez, yerel Windows ve Microsoft Store mimarisinde calisir."
        Publisher = "Meta Platforms, Inc."
        OfficialUrl = "https://www.instagram.com"
        Category = "Sosyal Medya & Iletisim"
        WingetId = "9NBLGGH5L9XT"
        StoreId = "9NBLGGH5L9XT"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Sosyal Medya Uygulamasi"
        Features = @(
            "Masaustunden Reels izleme ve Hikayeleri tam ekran goruntuleme",
            "Bilgisayar klavyesiyle hizli ve konforlu Direkt Mesajlasma (DM)",
            "Fotograf ve video paylasimlarini yuksek cozunurlukte inceleme",
            "Hafif ve dusuk RAM tuketen yerel Store mimarisi"
        )
    }
    "Facebook" = @{
        Details = "Facebook; Meta tarafindan Windows icin optimize edilmis resmi masaustu uygulamasidir. Ana haber kaynagi, arkadas gruplari, Marketplace, Facebook Watch videolari ve bildirimleri masaustunuze getirir. Android APK veya emulator gerektirmez, yerel Microsoft Store guvenli paketidir."
        Publisher = "Meta Platforms, Inc."
        OfficialUrl = "https://www.facebook.com"
        Category = "Sosyal Medya & Topluluk"
        WingetId = "9WZDNCRFJ2WL"
        StoreId = "9WZDNCRFJ2WL"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Sosyal Ag Uygulamasi"
        Features = @(
            "Anlik masaustu bildirimleriyle arkadas hareketlerini kacirmama",
            "Facebook Watch uzerinden kesintisiz video izleme",
            "Marketplace uzerinden urun arama ve ilanlari inceleme",
            "Gruplar ve etkinlikler arasinda hizli gecis"
        )
    }
    "X (Twitter)" = @{
        Details = "X (Twitter); kuresel olcekte tum guncel haberlerin, canli tartismalarin ve multimedya paylasimlarinin anlik olarak takip edildigi dijital sehir meydanidir. Sesli odalar (Spaces), direkt mesajlar, anlik trendler ve topluluk odalari masaustu konforuyla sunulur."
        Publisher = "X Corp."
        OfficialUrl = "https://x.com"
        Category = "Haber & Sosyal Ag"
        WingetId = "9WZDNCRFJ140"
        StoreId = "9WZDNCRFJ140"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Mikroblog & Haber"
        Features = @(
            "Gercek zamanli gundem (Trends) ve son dakika gelismeleri",
            "Grok yapay zeka asistani ve premium ozellikler destegi",
            "Canli yayinlar ve Spaces ses odalarina masaustunden katilim",
            "Karanlik tema uyumlu akici zaman akisi"
        )
    }
    "Netflix" = @{
        Details = "Netflix; dunyanin lider film, dizi, belgesel ve animasyon yayin platformudur. 4K Ultra HD, Dolby Vision, Spatial Audio destekli yuksek ses ve goruntu kalitesi; cevrimdisi izlemek icin bolum indirme yetenegi ve genis profil yonetimi sunar. Resmi Microsoft Store Windows istemcisiyle tarayiciya gore cok daha yuksek cozunurluk ve akici kare hizi saglar."
        Publisher = "Netflix, Inc."
        OfficialUrl = "https://www.netflix.com"
        Category = "Dijital Yayin & Eglence"
        WingetId = "9WZDNCRFJ3TJ"
        StoreId = "9WZDNCRFJ3TJ"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Video Yayin Platformu"
        Features = @(
            "Tarayici kisitlamalarini asan yuksek bit hizli 4K ve HDR yayin",
            "Seyahatlerde ve internetsiz ortamlarda izlemek icin icerik indirme",
            "Dolby Atmos ve 5.1 cevresel ses destegi",
            "Coklu profil yonetimi ve kisisellestirilmis yapay zeka onerileri"
        )
    }
    "Amazon Prime Video" = @{
        Details = "Amazon Prime Video; Amazon tarafindan sunulan odullu Prime Originals yapimlarinin (The Boys, Yuzuklerin Efendisi, Fallout vb.), populer filmlerin ve canli spor karsilasmalarinin bulundugu resmi Windows uygulamasidir. X-Ray IMDb entegrasyonu, cevrimdisi film/dizi indirme destegi ve 4K HDR oynatma ozelliklerine sahiptir."
        Publisher = "Amazon Development Centre"
        OfficialUrl = "https://www.primevideo.com"
        Category = "Dijital Yayin & Eglence"
        WingetId = "9P6RC76MSMMJ"
        StoreId = "9P6RC76MSMMJ"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Video Yayin Platformu"
        Features = @(
            "IMDb entegrasyonlu X-Ray ile anlik oyuncu ve muzik bilgisi",
            "Cevrimdisi izleme icin dizi ve filmleri yerel diske indirme",
            "4K Ultra HD ve HDR video kalitesi",
            "Prime Gaming ve Amazon alisveris ekosistemiyle entegre profil"
        )
    }
    "Disney+" = @{
        Details = "Disney+; Disney, Pixar, Marvel, Star Wars, National Geographic ve Star yapimlarinin yer aldigi kapsamli video yayin servisidir. IMAX Enhanced goruntu formati, Dolby Atmos ses, eszamanli izleme (GroupWatch) ve cevrimdisi indirme yetenekleriyle Windows bilgisayarlarda tam ekran sinematik deneyim sunar."
        Publisher = "Disney Interactive"
        OfficialUrl = "https://www.disneyplus.com"
        Category = "Dijital Yayin & Eglence"
        WingetId = "9NXQXXLFST89"
        StoreId = "9NXQXXLFST89"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Video Yayin Platformu"
        Features = @(
            "IMAX Enhanced genisletilmis goruntu orani destegi",
            "Marvel Sinematik Evreni ve Star Wars tum serileri",
            "Cevrimdisi izlemek icin bolumleri ve filmleri indirme",
            "GroupWatch ile uzaktaki arkadaslarla eszamanli izleme"
        )
    }
    "Apple TV" = @{
        Details = "Apple TV; Apple Original yapimlari (Ted Lasso, Severance, Morning Show vb.), film kiralama/satin alma magazasi ve 4K HDR sinema arsivini Windows masaustune getiren resmi Apple uygulamasidir. Apple ekosistemiyle eszamanli calisir ve yuksek bit oranli video akisi saglar."
        Publisher = "Apple Inc."
        OfficialUrl = "https://tv.apple.com"
        Category = "Dijital Yayin & Eglence"
        WingetId = "9NM4T8B9JQZ1"
        StoreId = "9NM4T8B9JQZ1"
        InstallSource = "Microsoft Store (UWP / MSIX)"
        Type = "Masaustu Video Yayin Platformu"
        Features = @(
            "Apple TV+ orijinal yapimlari ve ozel spor karsilasmalari",
            "En yuksek bit oranli 4K HDR10 ve Dolby Vision yayin kalitesi",
            "Apple hesabiyla satin alinan filmlere tum cihazlardan erisim",
            "Akici, modern ve sade Apple tasarim arayuzu"
        )
    }
    "TV+" = @{
        Details = "TV+; Turkcell tarafindan sunulan canli televizyon kanallari, spor karsilasmalari, populer yerli/yabanci dizi ve filmleri barindiran dijital televizyon platformudur. Yayini 24 saate kadar geri sarabilme, favori programlari kaydetme ve coklu cihaz senkronizasyonu sunar."
        Publisher = "Turkcell TV Plus"
        OfficialUrl = "https://tvplus.com.tr"
        Category = "Canli TV & Dijital Yayin"
        WingetId = "Turkcell.TVPlus"
        StoreId = "9WZDNCRDFTK8"
        InstallSource = "Resmi Web & Store Entegrasyonu"
        Type = "Canli TV & Dizi Platformu"
        Features = @(
            "150'den fazla canli TV kanalini 24 saat geri sarabilme",
            "Canli spor musabakalari, Premier League ve NBA yayinlari",
            "Zengin Turkce dublaj ve altyazili dizi/film kutuphanesi",
            "Coklu cihaz destegi ve kaldigin yerden devam etme"
        )
    }
    "TOD TV" = @{
        Details = "TOD TV; Trendyol Super Lig maclari, Premier League, Bundesliga, canli spor yayinlari ve Digiturk'un zengin dizi/film arsivini canli olarak sunan yeni nesil dijital platformdur. 1080p Full HD canli mac yayinlari ve anlik spor ozetleri icerir."
        Publisher = "Digiturk / beIN Media Group"
        OfficialUrl = "https://www.todtv.com.tr"
        Category = "Canli Mac & Spor & Yayin"
        WingetId = "Digiturk.TOD"
        InstallSource = "Resmi Web & Masaustu Entegrasyonu"
        Type = "Canli Spor & Mac Izleme"
        Features = @(
            "Trendyol Super Lig ve canli spor musabakalarini kesintisiz izleme",
            "Premier League, Bundesliga ve Formula 1 canli yayinlari",
            "Odullu yabanci diziler ve bini askin sinema filmi",
            "Yuksek kare hizli (60 FPS) akici spor deneyimi"
        )
    }
    "beIN CONNECT" = @{
        Details = "beIN CONNECT; beIN SPORTS kanallarinin canli spor musabakalari, sinema kanallari ve binlerce saatlik eglence arsivini sunan resmi Digiturk internet yayin servisidir. Super Lig ve UEFA organizasyonlarinin maclarini kesintisiz yuksek kalitede yayinlar."
        Publisher = "Digiturk beIN Media Group"
        OfficialUrl = "https://www.beinconnect.com.tr"
        Category = "Canli Spor & Sinema"
        WingetId = "Digiturk.beINCONNECT"
        InstallSource = "Resmi Web & Masaustu Entegrasyonu"
        Type = "Canli Spor & Dizi/Film"
        Features = @(
            "beIN SPORTS 1, 2, 3, 4 kanallari ve tum Super Lig maclari",
            "Mac sonu ozetleri, kritik anlar ve ozel spor analizleri",
            "Box Office vizyon filmleri ve dunya sinemasi arsivi",
            "Esnek profil yonetimi ve akilli arama destegi"
        )
    }
    "Microsoft 365" = @{
        Details = "Microsoft 365 (Office); Word, Excel, PowerPoint, Outlook, OneNote, OneDrive ve Microsoft Copilot yapay zeka araclarini iceren dunyanin en yaygin ofis ve uretkenlik ekosistemidir. Bulut eszamanlamasi, eszamanli ortak calisma ve guvenli belge yonetimi saglar."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://www.office.com"
        Category = "Ofis & Uretkenlik"
        WingetId = "9WZDNCRD29V9"
        StoreId = "9WZDNCRD29V9"
        InstallSource = "Microsoft Store / Win32 Cift Kaynak"
        Type = "Ofis & Dokuman Paketi"
        Features = @(
            "Word, Excel ve PowerPoint ile profesyonel dokuman ve sunum hazirlama",
            "Microsoft Copilot yapay zeka asistanligi ve otomatik veri analizi",
            "1 TB OneDrive bulut depolama ve otomatik dosya yedekleme",
            "Es zamanli ortak calisma ve gercek zamanli belge duzenleme"
        )
    }
    "LocalSend" = @{
        Details = "LocalSend; yerel ag (Wi-Fi/LAN) uzerinden bilgisayarlar ve mobil cihazlar arasinda internet baglantisina ve harici sunuculara gerek kalmadan sifreli dosya paylasimi saglayan acik kaynakli, hizli ve guvenli bir transfer uygulamasidir."
        Publisher = "LocalSend Open Source Team"
        OfficialUrl = "https://localsend.org"
        Category = "Dosya Paylasimi & Ag"
        WingetId = "LocalSend.LocalSend"
        InstallSource = "Acik Kaynak Win32 / Store"
        Type = "Yerel Dosya Transfer Araci"
        Features = @(
            "Internetsiz calisabilen tam guvenli yerel ag dosya paylasimi",
            "Windows, macOS, Linux, Android ve iOS arasinda capraz platform destegi",
            "Uctan uca HTTPS sifreleme ile mutlak veri gizliligi",
            "Reklamsiz, kayit gerektirmeyen hafif ve acik kaynakli yapi"
        )
    }
    "TeamViewer QuickSupport" = @{
        Details = "TeamViewer QuickSupport; kurulum ve yonetici yetkisi gerektirmeyen, aninda uzaktan teknik destek saglanmasi icin optimize edilmis son derece hafif ve hizli bir tek kullanimlik erisim moduludur. Tek bir ID ve parola ile aninda baglanti saglar."
        Publisher = "TeamViewer Germany GmbH"
        OfficialUrl = "https://www.teamviewer.com"
        Category = "Hizli Uzaktan Destek"
        WingetId = "TeamViewer.TeamViewer.QuickSupport"
        InstallSource = "Win32 Resmi Istemci"
        Type = "Hizli Yardim Modulu"
        Features = @(
            "Kurulum gerektirmeyen tek tikla calisan portatif exe yapisi",
            "256-bit AES uctan uca sifrelenmis guvenli baglanti protokolu",
            "Guvenlik duvari (firewall) ve NAT arkasinda kesintisiz baglanti",
            "Teknik servisin veya uzaktaki uzmanın aninda mudahale edebilmesi"
        )
    }
    "TeamViewer Host" = @{
        Details = "TeamViewer Host; bilgisayarlara 7/24 kesintisiz ve basinda kullanici olmadan (Unattended Access) uzaktan erisim saglamak amaciyla Windows servisi olarak calisan kurumsal uzak masaustu sunucusudur."
        Publisher = "TeamViewer Germany GmbH"
        OfficialUrl = "https://www.teamviewer.com"
        Category = "Surekli Uzak Sunucu"
        WingetId = "TeamViewer.TeamViewer.Host"
        InstallSource = "Win32 Sistem Servisi"
        Type = "Arka Plan Uzak Baglanti"
        Features = @(
            "Basinda kimse yokken 7/24 guvenli uzaktan erisim (Unattended Access)",
            "Windows servisi olarak sistem acilisinda otomatik baslama",
            "Coklu monitor destegi ve uzaktan dosya transferi",
            "Sistem yeniden baslatildiginda otomatik yeniden baglanma yetenegi"
        )
    }
    ".NET Framework 3.5" = @{
        Details = ".NET Framework 3.5; .NET 2.0 ve 3.0 cekirdeklerini iceren, bircok klasik oyunun, nostaljik yazilimin ve eski Windows bilesenlerinin calismasi icin zorunlu olan Microsoft calisma zamani paketidir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.Framework.DeveloperPack_3_5"
        InstallSource = "Microsoft Windows Bileseni"
        Type = "Sistem Calisma Zamani"
        Features = @(
            "Eski oyunlar ve klasik Windows programlari icin zorunlu calisma altyapisi",
            "WPF, WCF ve LINQ teknolojilerinin ilk nesil calisma modulleri",
            "Windows 10 ve 11 ile tam uyumlu resmi Microsoft bileseni",
            "Sistem kararliligi ve eski yazilim uyumlulugu"
        )
    }
    ".NET Framework 4.8.1" = @{
        Details = ".NET Framework 4.8.1; Windows uzerinde calisan milyonlarca masaustu uygulamasinin temelini olusturan en guncel .NET Framework surumudur. Gelismis yuksek DPI destegi, ARM64 optimizasyonlari ve en yuksek duzeyde TLS guvenligi sunar."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.Framework.DeveloperPack_4"
        InstallSource = "Microsoft Resmi Paket"
        Type = "Sistem Calisma Zamani"
        Features = @(
            "Yuksek DPI (High-DPI) ekranlarda pikselsiz net arayuz olusturma",
            "Gelismis kriptografi ve TLS 1.3 guvenli iletisim destegi",
            "ARM64 mimarisi icin yerel optimizasyon ve yuksek performans",
            "Kurumsal yazilimlar ve modern masaustu araclari icin zorunlu paket"
        )
    }
    ".NET Desktop Runtime 6.0 (x64)" = @{
        Details = ".NET Desktop Runtime 6.0; C# ve .NET 6 ile kodlanmis modern Windows Forms ve WPF masaustu uygulamalarini calistirmak icin gereken resmi Microsoft LTS (Uzun Sureli Destek) calisma zamanidir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.DesktopRuntime.6"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "Masaustu Calisma Platformu"
        Features = @(
            ".NET 6 tabanli modern masaustu uygulamalarini calistirma",
            "Yuksek verimli JIT derleyici ve dusuk bellek ayak izi",
            "Uzun sureli destek (LTS) guvenlik ve kararlilik yamalari",
            "64-bit optimize edilmis hizli bellek yonetimi"
        )
    }
    ".NET Desktop Runtime 7.0 (x64)" = @{
        Details = ".NET Desktop Runtime 7.0; performans odakli modern masaustu programlarini calistiran Microsoft .NET 7 platformudur. Cok cekirdekli islemcilerde optimize edilmis yurutme hizi saglar."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.DesktopRuntime.7"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "Masaustu Calisma Platformu"
        Features = @(
            ".NET 7 ile yazilmis modern Windows yazilimlari icin gerekli paket",
            "Geliskin profil kilavuzlu optimizasyon (PGO) ile yuksek CPU verimi",
            "Hizli arayuz yukleme ve akici animasyon destegi",
            "Guclu 64-bit sistem entegrasyonu"
        )
    }
    ".NET Desktop Runtime 8.0 (x64)" = @{
        Details = ".NET Desktop Runtime 8.0; Microsoft'un en yaygin modern LTS platformudur. Yapay zeka araclari, sistem optimizasyon yazilimlari ve guncel gelistirici uygulamalari icin zorunlu bilesendir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.DesktopRuntime.8"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "Masaustu Calisma Platformu"
        Features = @(
            "Modern yapay zeka ve sistem araclarinin gereksinim duydugu temel LTS motoru",
            "Dinamik PGO (Profile-Guided Optimization) ile maksimum calisma hizi",
            "Gelismis bellek yonetimi ve son derece dusuk RAM kullanimi",
            "Windows 11 ile en yuksek duzeyde uyum ve guvenlik"
        )
    }
    ".NET Desktop Runtime 9.0 (x64)" = @{
        Details = ".NET Desktop Runtime 9.0; Microsoft'un en son nesil ve en yuksek performansli .NET calisma platformudur. En yeni nesil masaustu uygulamalarini ve yapay zeka destekli yazilimlari calistirir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.DesktopRuntime.9"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "Masaustu Calisma Platformu"
        Features = @(
            "En guncel .NET 9 mimarisiyle gelistirilen yazilimlar icin calisma zamani",
            "Server GC ve modern bellek tahsisi optimizasyonlari",
            "AVX-512 ve modern CPU komut setlerinden tam yararlanma",
            "Gelecek nesil Windows masaustu standartlari"
        )
    }
    "ASP.NET Core Runtime 8.0 (x64)" = @{
        Details = "ASP.NET Core Runtime 8.0; yerel web servisleri, arka plan mikro servisleri ve web tabanli masaustu yazilimlarinin Windows uzerinde calismasini saglayan resmi Microsoft calisma motorudur."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.AspNetCore.8"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "Web & Servis Calisma Platformu"
        Features = @(
            "Yerel web servisleri ve arka plan servislerinin calismasi",
            "Kestrel yuksek performansli yerel web sunucusu motoru",
            "Minimal API mimarisi ve yuksek baglanti isleme kapasitesi",
            "Kurumsal araclar ve sunucu yazilimlari icin LTS guvencesi"
        )
    }
    "ASP.NET Core Runtime 9.0 (x64)" = @{
        Details = "ASP.NET Core Runtime 9.0; en son web ve bulut teknolojilerini barindiran, yerel web servisleri ve gelismis arkaplan araclarinin Windows uzerinde calismasini saglayan Microsoft motorudur."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://dotnet.microsoft.com"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.DotNet.AspNetCore.9"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "Web & Servis Calisma Platformu"
        Features = @(
            "En yeni nesil yerel servis ve backend calisma ortami",
            "HTTP/3 ve modern iletisim protokolleri yerel destegi",
            "Ultra yuksek verimli asenkron I/O islemleri",
            "Geliskin guvenlik ve sertifika denetimleri"
        )
    }
    "Visual C++ 2015-2022 (x64)" = @{
        Details = "Visual C++ 2015-2022 Yeniden Dagitilabilir Paketi (x64); Steam, Epic Games, modern 3D oyunlar ve grafik yazilimlarinin calismasi icin olmazsa olmaz en kritik sistem DLL kutuphanesidir. Eksik oldugunda 'VCRUNTIME140.dll bulunamadi' hatasi alinir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2015+.x64"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "Modern oyunlar ve 3D grafik motorlari icin zorunlu DLL bileseni",
            "'MSVCP140.dll' ve 'VCRUNTIME140.dll' eksikligi hatalarini kesin cozer",
            "64-bit Windows mimarisi icin derlenmis C/C++ calisma zamani",
            "Microsoft tarafindan duzenli guncellenen en kritik sistem kutuphanesi"
        )
    }
    "Visual C++ 2015-2022 (x86)" = @{
        Details = "Visual C++ 2015-2022 Yeniden Dagitilabilir Paketi (x86); 32-bit mimaride derlenmis bircok populer oyun, emulator ve masaustu aracinin 64-bit Windows sistemlerde hatasiz calismasi icin zorunlu olan bilesendir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2015+.x86"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "32-bit oyunlar ve klasik yazilimlarin calismasi icin temel gereksinim",
            "VCRUNTIME140.dll ve bagli runtime dosyalarini sisteme yukler",
            "64-bit Windows icerisindeki SysWOW64 entegrasyonunu tamamlar",
            "Oyun baslaticilari ve mod yoneticileri icin zorunlu altyapi"
        )
    }
    "Visual C++ 2013 (x64)" = @{
        Details = "Visual C++ 2013 Redistributable (x64); 2013-2015 doneminde cikan DirectX 11 oyunlarinin ve donanim araclarinin calismasi icin gereken resmi Microsoft C++ kutuphanelerini sisteme kazandirir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2013.x64"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "MSVCR120.dll ve MSVCP120.dll eksikliklerini giderir",
            "Orta nesil oyunlar ve donanim konfigurasyon araclari icin gereklidir",
            "Temiz ve sorunsuz sistem DLL kayit islemi",
            "Klasik oyun arsivleri icin vazgecilmez paket"
        )
    }
    "Visual C++ 2013 (x86)" = @{
        Details = "Visual C++ 2013 Redistributable (x86); 32-bit tabanli bircok populer klasik oyunun ve yardimci programin gereksinim duydugu 2013 donemi Visual C++ calisma zamani dosyalaridir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2013.x86"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "32-bit oyun motorlari ve emulatorler icin calisma altyapisi",
            "MSVCR120.dll hatasini cozer",
            "Hafif ve kararliligi kanitlanmis Microsoft bileseni",
            "Sorunsuz geriye donuk uyumluluk"
        )
    }
    "Visual C++ 2012 (x64)" = @{
        Details = "Visual C++ 2012 Redistributable (x64); 2012 donemi oyunlarinin ve grafik yazilimlarinin gereksinim duydugu MSVCR110.dll ve MSVCP110.dll kutuphanelerini Windows sistemine tanitir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2012.x64"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "MSVCR110.dll ve MSVCP110.dll eksikliklerini giderir",
            "DirectX 9/11 donemi oyunlarinin calismasi icin gereklidir",
            "Resmi Microsoft 64-bit runtime kutuphanesi",
            "Eski oyunlarda '0xc000007b' baslatma hatalarini onler"
        )
    }
    "Visual C++ 2012 (x86)" = @{
        Details = "Visual C++ 2012 Redistributable (x86); 32-bit klasik yazilim ve oyunlarin Windows uzerinde DLL eksikligi yasamadan calismasini saglayan bilesendir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2012.x86"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "32-bit oyunlar icin MSVCR110.dll saglar",
            "Klasik oyunlarin yuklenmesini ve calismasini garanti eder",
            "Windows 10 ve 11 ile tam uyumlu",
            "Hafif ve guvenilir sistem kutuphanesi"
        )
    }
    "Visual C++ 2010 (x64)" = @{
        Details = "Visual C++ 2010 Redistributable (x64); klasik donem oyunlarinin ve eski surum muhendislik/tasarim programlarinin ihtiyac duydugu MSVCR100.dll dosyasini iceren resmi Microsoft bilesenidir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2010.x64"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "MSVCR100.dll ve MSVCP100.dll dosyalarini yukler",
            "Efsanevi 2010 donemi oyunlarinin acilmasini saglar",
            "Eski tasarim ve muhendislik programlari uyumlulugu",
            "Sistem DLL butunlugunu saglar"
        )
    }
    "Visual C++ 2010 (x86)" = @{
        Details = "Visual C++ 2010 Redistributable (x86); 32-bit klasik oyunlar, eski kurulum sihirbazlari ve donanim suruculerinin yardimci modulleri icin zorunlu kutuphanedir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2010.x86"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "32-bit MSVCR100.dll dosyasini sisteme kaydeder",
            "Nostaljik oyunlar ve eski kurulum paketleri icin sarttir",
            "Geriye donuk tam sistem destegi",
            "0xc000007b hatasini engelleyici kritik paket"
        )
    }
    "Visual C++ 2008 (x64)" = @{
        Details = "Visual C++ 2008 Redistributable (x64); 2008 donemi 64-bit oyun ve uygulamalarinin gereksinim duydugu MSVCR90.dll kutuphanelerini Windows yan yana (WinSxS) dizinine yukler."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2008.x64"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "MSVCR90.dll ve bagli C++ calisma zamani bilesenleri",
            "WinSxS (Side-by-Side) dizinine guvenli kurulum",
            "Eski nesil 64-bit yazilimlarin calismasi",
            "Microsoft SP1 guvenlik guncellemeleri icerir"
        )
    }
    "Visual C++ 2008 (x86)" = @{
        Details = "Visual C++ 2008 Redistributable (x86); bini askin nostaljik oyunun ve eski Windows programinin calismasi icin gerekli olan 32-bit 2008 calisma zamanidir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2008.x86"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "32-bit MSVCR90.dll bileseni saglar",
            "Eski nesil oyun arsivleri icin zorunludur",
            "Klasik CD/DVD kurulumlu oyunlarda hata alinmasini onler",
            "Hafif ve kararliligi kanitlanmis bilesen"
        )
    }
    "Visual C++ 2005 (x64)" = @{
        Details = "Visual C++ 2005 Redistributable (x64); 2005 ve oncesi donemde cikan ilk 64-bit yazilimlarin calismasi icin gereken MSVCR80.dll kutuphanesini barindirir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2005.x64"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "MSVCR80.dll bilesenini saglar",
            "Ilk nesil 64-bit Windows uygulamalari icin geriye donuk destek",
            "WinSxS klasorune guvenli kayit",
            "Kapsamli sistem kutuphane butunlugu"
        )
    }
    "Visual C++ 2005 (x86)" = @{
        Details = "Visual C++ 2005 Redistributable (x86); Windows XP doneminin tum efsanevi klasik oyunlarinin (GTA San Andreas, NFS Most Wanted vb.) hatasiz calismasi icin zorunlu temel kutuphanedir."
        Publisher = "Microsoft Corporation"
        OfficialUrl = "https://support.microsoft.com/help/4032938"
        Category = ".NET & Visual C++ Kutuphaneleri"
        WingetId = "Microsoft.VCRedist.2005.x86"
        InstallSource = "Microsoft WinGet / Win32"
        Type = "C/C++ Calisma Zamani DLL Kutuphanesi"
        Features = @(
            "Windows XP donemi efsanevi oyunlarinin calismasi icin zorunlu",
            "MSVCR80.dll eksikligi hatalarini kokunden cozer",
            "32-bit klasik yazilim kutuphanesi",
            "Eski oyun arsivleri icin temel bilesen"
        )
    }
    "Google Chrome" = @{
        Details = "Google Chrome; Google tarafindan gelistirilen, Chromium motorunu kullanan ve dunyada en yaygin kullanilan web tarayicisidir. Hizli V8 JavaScript motoru, Google servisleriyle (Gmail, Drive, Sifreler) tam entegrasyonu ve zengin eklenti magazasina sahiptir."
        Features = @(
            "Google hesabi ile yer imleri, kayitli sifreler ve tarama gecmisi esitleme",
            "Chrome Web Magazasi uzerinden binlerce guvenlik, ceviri ve uretkenlik eklentisi destegi",
            "Dahili zararli yazilim, kimlik avi ve guvensiz indirme engelleme kalkani",
            "Dahili Turkce/coklu dil web sayfasi ceviri sistemi"
        )
    }
    "Opera" = @{
        Details = "Opera; dahili ucretsiz VPN, gelismis reklam engelleyici, kripto cuzdan ve yapay zeka asistani (Aria) barindiran zengin ozellikli ve yuksek performansli Chromium tabanli web tarayicisidir."
        Features = @(
            "Ucretsiz ve sinirsiz dahili tarayici VPN servisi",
            "Sayfalarin daha hizli yuklenmesini saglayan dahili reklam ve takipci engelleyici",
            "Yan panelde WhatsApp, Telegram, Discord ve Instagram anlik mesajlasma entegrasyonu",
            "Pil tasarrufu modu ve ayrilabilir video penceresi (Picture-in-Picture)"
        )
    }
    "Mozilla Firefox" = @{
        Details = "Mozilla Firefox; kullanici gizliligine, acik internet standartlarina ve bagimsizliga onem veren, kar amaci gutmeyen Mozilla Vakfi tarafindan gelistirilen guclu ve guvenli acik kaynakli tarayicidir."
        Features = @(
            "Gelismis Izlenme Korumasi ile ucuncu taraf cerezleri ve reklam takipcilerini engelleme",
            "Coklu Hesap Kapsayicilari (Multi-Account Containers) ile is ve kisisel oturumlari ayirma",
            "Kisisellestirilebilir tasarim, genis eklenti ekosistemi ve tema destegi",
            "Yuksek gizlilik, acik kaynak guvencesi ve bagimsiz Gecko motoru"
        )
    }
    "Microsoft Edge" = @{
        Details = "Microsoft Edge; Windows 10 ve 11 isletim sistemleriyle derin donanim entegrasyonuna sahip, yapay zeka Copilot motoru destekli, ultra hizli ve dusuk RAM tuketen Chromium tarayicisidir."
        Features = @(
            "Uyku modundaki sekmeler (Sleeping Tabs) ile sistem RAM ve pil kullanimini minimize etme",
            "Dahili Copilot yapay zeka ile web sayfalarini ozetleme, soru sorma ve icerik olusturma",
            "Microsoft Defender SmartScreen ile gelismis zararli indirme ve oltalama korumasi",
            "Dikey sekmeler, dahili PDF duzenleyici, ekran alintisi ve koleksiyonlar"
        )
    }
    "Brave Browser" = @{
        Details = "Brave Browser; internetteki reklamlari, izleme betiklerini ve parmak izi takipcilerini varsayilan olarak engelleyen, yuksek hiz ve maksimum gizlilik vadeden Chromium tabanli tarayicidir."
        Features = @(
            "Brave Shields kalkani ile tum web reklamlarini ve izleyicilerini eklentisiz engelleme",
            "Gereksiz veri ve reklam yuklemedigi icin 3 kata kadar daha hizli sayfa acilisi",
            "Gizli pencerelerde dahili Tor yonlendirme destegi ile IP gizleme",
            "Kripto cuzdan ve Brave Rewards ile gizlilik odakli kullanim modeli"
        )
    }
    "Zen Browser" = @{
        Details = "Zen Browser; Firefox altyapisi uzerine insa edilmis, minimalist modern tasarimi, dikey sekme sistemi ve calisma alanlari (Workspaces) ile dikkat ceken yeni nesil acik kaynak web tarayicisidir."
        Features = @(
            "Modern dikey sekme mimarisi ve kompakt odaklanma modu",
            "Farkli isler veya projeler icin ayrilmis Calisma Alanlari (Workspaces)",
            "Bolunmus Ekran (Split View) ile iki farkli sekmeyi tek pencerede yan yana kullanma",
            "Firefox eklenti ekosistemi ile tam uyumluluk ve sifre/veri gizliligi"
        )
    }
    "Discord" = @{
        Details = "Discord; oyuncular, yazilimcilar ve topluluklar icin gelistirilmis, dusuk gecikmeli sesli sohbet, kristal netliginde goruntulu gorusme, 60 FPS ekran paylasimi ve metin kanallari sunan lider iletisim platformudur."
        Features = @(
            "Dusuk pingli ve gurultu engellemeli (Krisp) sesli sohbet kanallari",
            "60 FPS 1080p ekran ve oyun yayini paylasma destegi",
            "Ozel sunucular, metin kanallari, roller ve zengin bot otomasyonu",
            "Oyun ici arayuz (Overlay) ve zengin aktivite/durum gosterimi"
        )
    }
    "WhatsApp" = @{
        Details = "WhatsApp; telefonunuzdaki WhatsApp hesabini bilgisayariniza baglayarak buyuk ekranda mesajlasmanizi, dosya/fotograf paylasmanizi, sesli ve goruntulu gorusme yapmanizi saglayan resmi masaustu uygulamasidir."
        Features = @(
            "Telefonunuz kapali olsa bile bagimsiz mesajlasma ve bildirim alma",
            "Birebir ve grup ici yuksek kaliteli sesli ve goruntulu arama destegi",
            "Uctan uca sifreleme (End-to-End Encryption) ile maksimum mesaj guvenligi",
            "Belge, PDF, yuksek cozunurluklu gorsel ve ses kaydi gonderme"
        )
    }
    "Zoom Meetings" = @{
        Details = "Zoom Meetings; online egitim, is toplantilari, web seminerleri ve ekip ici gorusmeler icin dunya capinda standart haline gelmis profesyonel video konferans ve toplantilari yazilimidir."
        Features = @(
            "HD kalitesinde ses ve goruntu ile yuzlerce kisilik toplanti imkani",
            "Ekran paylasimi, etkilesimli Beyaz Tahta (Whiteboard) ve grup calisma odalari",
            "Akilli arka plan bulaniklastirma ve gelismis ortam gurultusu filtreleme",
            "Yerel veya buluta toplanti kaydetme ve otomatik sohbet arsivleme"
        )
    }
    "Microsoft Teams" = @{
        Details = "Microsoft Teams; kurumsal sirketler, okullar ve calisma ekipleri icin sohbet, video toplanti, dosya paylasimi ve Office 365 uygulamalarini tek cati altinda toplayan resmi isbirligi platformudur."
        Features = @(
            "Kanal tabanli ekip sohbetleri ve organize konu basliklari",
            "Gorev yonetimi, takvim planlama ve Office 365 (Word, Excel) ortak calisma",
            "Genis katilimli canli etkinlikler ve guvenli toplanti kayitlari",
            "OneDrive ve SharePoint ile kesintisiz bulut dosya entegrasyonu"
        )
    }
    "Thunderbird" = @{
        Details = "Mozilla Thunderbird; birden fazla e-posta hesabini, kisisel takvimleri ve kisi rehberini tek bir ekranda toplayan guclu, guvenli ve reklamsiz acik kaynak e-posta istemcisidir."
        Features = @(
            "Gmail, Outlook, Yahoo ve ozel sirket IMAP/POP3 hesaplarini tek merkezden yonetme",
            "Akilli istenmeyen posta (Spam) ve kimlik avi koruma kalkanlari",
            "Entegre takvim, hatirlaticilar ve kisi adres defteri",
            "Eklenti ve tema destegi ile arayuzu tamamen ozellestirebilme"
        )
    }
    "Steam" = @{
        Details = "Steam; Valve Corporation tarafindan isletilen, on binlerce oyunu barindiran, dunyanin en buyuk dijital oyun dagitim, satin alma ve oyuncu toplulugu platformudur."
        Features = @(
            "Muazzam oyun arsivi, sezonluk indirim festivalleri ve aninda indirme",
            "Steam Cloud ile oyun kayitlarinizi her bilgisayarda otomatik senkronize etme",
            "Steam Atolyesi (Workshop) ile binlerce oyuna tek tikla ucretsiz mod yukleme",
            "Arkadas listesi, oyun ici arayuz, canli yayin ve basarim rozetleri"
        )
    }
    "Epic Games" = @{
        Details = "Epic Games Launcher; Fortnite, Unreal Engine oyun motoru ve her hafta kullanicilara hediye ettigi yuksek butceli ucretsiz oyunlarla bilinen buyuk dijital oyun magazasidir."
        Features = @(
            "Her hafta persembe gunleri hediye edilen ucretsiz orjinal oyunlar",
            "Fortnite, Rocket League ve Fall Guys icin resmi baslatici ve guncelleyici",
            "Oyun gelistiricileri icin Unreal Engine indirme, varlik ve proje yonetim merkezi",
            "Bulut kayitlari (Cloud Save) ve arkadas davet sistemi"
        )
    }
    "Battle.net" = @{
        Details = "Blizzard Battle.net; Call of Duty serisi (Warzone, Black Ops), World of Warcraft, Diablo IV, Overwatch 2 ve StarCraft oyunlarinin resmi magaza ve baslatici istemcisidir."
        Features = @(
            "Call of Duty Warzone ve Black Ops serisi icin resmi oyun baslaticisi",
            "World of Warcraft, Diablo IV ve Hearthstone aninda indirme ve otomatik guncelleme",
            "Oyun dosyalarini tarayip onarma (Scan & Repair) ozelligi",
            "Blizzard arkadas agi, sesli sohbet ve guvenli hesap yonetimi"
        )
    }
    "EA App" = @{
        Details = "EA App (eski adiyla Origin); Electronic Arts tarafindan gelistirilen, EA SPORTS FC (FIFA), Battlefield, Apex Legends, The Sims ve Need for Speed oyunlarinin resmi istemcisidir."
        Features = @(
            "EA Play abonelik kutuphanesindeki oyunlara dogrudan erisim",
            "EA SPORTS FC, Battlefield ve Apex Legends indirme ve otomatik yama yukleme",
            "Hizli arka plan indirmeleri ve optimize edilmis bellek kullanimi",
            "Platformlar arasi EA hesap eslestirmesi ve arkadas listesi"
        )
    }
    "Ubisoft Connect" = @{
        Details = "Ubisoft Connect; Assassin's Creed, Far Cry, Rainbow Six Siege, The Crew ve The Division gibi tum Ubisoft oyunlarinin resmi istemcisi, dijital magazasi ve odul sistemidir."
        Features = @(
            "Ubisoft yapimlarini indirme, kurma, onarma ve otomatik guncelleme",
            "Bulut Kayitlari (Cloud Save) ile ilerlemenizi kaybetmeden oynama",
            "Ubisoft Connect Rewards ile oyun ici ozel esyalar, kaplamalar ve indirim kuponlari",
            "Arkadas listesi, grup sohbeti, basarimlar ve detayli oyun istatistikleri"
        )
    }
    "Rockstar Games Launcher" = @{
        Details = "Rockstar Games Launcher; Grand Theft Auto (GTA V, GTA Online, GTA IV) ve Red Dead Redemption 2 oyunlarini oynamak icin gerekli resmi oyun istemcisidir."
        Features = @(
            "GTA V, GTA Online ve Red Dead Redemption 2 indirme ve baslatma",
            "Bulut Kayitlari (Cloud Save) ile hikaye ilerlemesini guvende tutma",
            "Rockstar Games Social Club arkadas agi ve aktivite takibi",
            "Otomatik oyun yamalari ve Rockstar dijital magazasi"
        )
    }
    "Riot Games Client" = @{
        Details = "Riot Games Client; League of Legends, Valorant, Teamfight Tactics (TFT) ve Legends of Runeterra oyunlarinin resmi guncelleme ve baslatma merkezidir."
        Features = @(
            "Valorant ve Vanguard hile koruma sistemini calistirma ve guncelleme",
            "League of Legends ve TFT istemcilerini tek noktadan yonetme",
            "Riot hesabi guvenligi ve iki asamali dogrulama ile hesap koruma",
            "Tum Riot oyunlari arasinda aninda gecis yapabilme"
        )
    }
    "Blitz" = @{
        Details = "Blitz.gg; League of Legends, Valorant, TFT ve CS gibi rekabetci oyunlarda profesyonel oyuncu analizlerini, en yuksek kazanma oranina sahip runleri ve esyalari otomatik oyununuza aktaran yapay zeka oyun asistanidir."
        Features = @(
            "LoL icin mac basladiginda en iyi run ve esya dizilimlerini otomatik yukleme",
            "Sampiyon secim ekraninda karsi eslesme (counter pick) ve yetenek sirasi onerileri",
            "TFT icin guncel yamanin en guclu kompozisyon ve esya birlestirme rehberleri",
            "Valorant mac sonrasi detayli vurus, hasar ve performans istatistikleri"
        )
    }
    "XBOX" = @{
        Details = "Microsoft XBOX uygulamasi; PC Game Pass kutuphanesine eriserek yuzlerce konsol ve PC oyununu bilgisayariniza indirmenizi, oynamanizi ve Bulut Oyun (Cloud Gaming) ile guclu donanim olmadan oynamanizi saglayan resmi platformdur."
        Features = @(
            "PC Game Pass aboneligiyle yuzlerce kaliteli oyuna sinirsiz erisim",
            "XBOX Cloud Gaming (Bulut Oyun) ile yuksek sistem istemeden tarayici uzerinden oyun oynama",
            "EA Play ve Ubisoft Connect hesaplarini baglayarak tum oyunlari tek yerde toplama",
            "XBOX basarimlari, profil ozellestirme ve arkadaslarla parti sesli sohbeti"
        )
    }
    "Spotify" = @{
        Details = "Spotify; yuz milyonlarca sarki, podcast, sesli kitap ve ozel calma listesine aninda erisim sunan dunyanin bir numarali cevrim ici muzik akis platformudur."
        Features = @(
            "Devasa muzik arsivi, kayipsiz ses kalitesi ve kisisellestirilmis Haftalik Kesif listeleri",
            "Spotify Connect ile bilgisayardaki muzigi telefondan veya hoparlorlerden uzaktan kontrol etme",
            "Sarkilarin sozlerini anlik ritimle takip edebilme",
            "Arkadaslarin ne dinledigini canli gorme ve ortak calma listeleri olusturma"
        )
    }
    "VLC Media Player" = @{
        Details = "VLC Media Player; harici hicbir codec paketi yuklemeye gerek kalmadan MP4, MKV, AVI, FLV dahil neredeyse tum video ve ses formatlarini acabilen dunyaca unlu ucretsiz acik kaynak medya oynaticisidir."
        Features = @(
            "Hemen hemen tum ses ve video formatlarini (MKV, MP4, AVI, MOV, FLAC vb.) sorunsuz acma",
            "Bozuk, yarim inmis veya hasarli video dosyalarini onararak oynatabilme",
            "Dahili online altyazi arama, otomatik indirme ve senkronize etme",
            "Donanim hizlandirmasi ile 4K/8K videolarda takilmasiz akici oynatma"
        )
    }
    "GOM Player" = @{
        Details = "GOM Player; dahili codec destegi, 360 derece VR video oynatma yetenegi ve genis altyazi kutuphanesi iceren gelismis bir multimedya oynaticidir."
        Features = @(
            "Sistemde bulunmayan nadir video formatlari icin dahili Codec Bulucu servisi",
            "360 derece sanal gerceklik (VR) videolari fareyle dondurerek izleme",
            "Buyuk online altyazi arsivinden videoyla otomatik eslesme saglama",
            "Video hizlandirma/yavaslatma, ses ayrirma ve ekran goruntusu yakalama"
        )
    }
    "OBS Studio" = @{
        Details = "OBS Studio (Open Broadcaster Software); Twitch, YouTube, Kick gibi platformlara canli yayin yapmak veya bilgisayar ekranini yuksek cozunurlukte kaydetmek icin kullanilan profesyonel acik kaynak yazilimdir."
        Features = @(
            "Coklu sahne, oyun yakalama, web kamerasi ve pencere mikseri",
            "NVIDIA NVENC, AMD AMF ve Intel QuickSync donanim hizlandirmali yayin ve kayit",
            "Gurultu filtreleme, ses karsisimi ve profesyonel VST eklenti destegi",
            "Tamamen ozellestirilebilir yerlesim ve genis topluluk eklentileri"
        )
    }
    "K-Lite Codec Pack" = @{
        Details = "K-Lite Codec Pack Mega; Windows'un ve diger medya oynaticilarin piyasadaki tum video ve ses dosyalarini acmasini saglayan, MPC-HC oynatici ile birlikte gelen en kapsamli codec paketidir."
        Features = @(
            "MPC-HC (Media Player Classic Home Cinema) hafif oynaticisini icerir",
            "Windows Dosya Gezgininde video kucuk resimleri (thumbnail) olusturur",
            "Eksik DirectShow filtrelerini tamamlayarak video acilmama sorunlarini cozer",
            "Gelismis altyazi ve yuksek kaliteli ses/video render bilesenleri saglar"
        )
    }
    "Visual Studio Code" = @{
        Details = "Visual Studio Code; Microsoft tarafindan gelistirilen; Python, C++, C#, JavaScript, Go ve web dilleri basta olmak uzere her programlama diliyle calisan ultra hafif ve guclu acik kaynak kod editorudur."
        Features = @(
            "Zengin eklenti magazasinda binlerce dil destegi, linter ve tema",
            "Dahili Git kaynak kontrolu, degisiklik inceleme ve dal yonetimi",
            "IntelliSense ile akilli kod tamamlama, parametre bilgisi ve sozdizimi vurgulama",
            "Entegre terminal ve dogrudan kod hata ayiklama (Debugging) araclari"
        )
    }
    "Cursor AI Editor" = @{
        Details = "Cursor; VS Code tabanli olarak insa edilen, Claude 3.5 Sonnet ve GPT-4o yapay zeka modelleriyle kod yazmayi, refactoring yapmayi ve hata ayiklamayi devrimlestiren yeni nesil yapay zeka kod editorudur."
        Features = @(
            "Tum kod tabanini anlayarak coklu dosyalarda ayni anda kod degisikligi yapabilme",
            "Kod yazarken akilli otomatik tamamlama ve sonraki adimi tahmin etme",
            "Dogal dille projeye ozellik ekleme, kod aciklatma ve hata cozme",
            "Tum VS Code eklentileri, ayarlari ve kisayollariyla yuzde yuz uyumluluk"
        )
    }
    "Windsurf Editor" = @{
        Details = "Windsurf Editor; Codeium tarafindan gelistirilen, gelistiricinin dusunce akisini takip eden 'Flows' ozelligi ve derin baglam analiziyle one cikan yuksek performansli yapay zeka kod editorudur."
        Features = @(
            "Flow mimarisi ile gelistiriciyle birlikte gercek zamanli kod uretimi",
            "Projenin mimari yapisini tarayarak nokta atisi kod onerileri sunma",
            "Hizli terminal komut onerileri ve derleme hatasi cozumleri",
            "Dusuk bellek kullanimi ve yuksek yanit verme hizi"
        )
    }
    "Visual Studio Community" = @{
        Details = "Visual Studio Community; C#, C++, .NET, WPF, Unity ve Azure uygulamalari gelistirmek icin Microsoft tarafindan bireysel gelistiricilere ve ogrencilere ucretsiz sunulan profesyonel IDE'dir."
        Features = @(
            "Dunyanin en gelismis C# ve C++ kod hata ayiklayicisi (Debugger) ve profil olusturucusu",
            "WPF, Windows Forms ve MAUI icin gorsel arayuz tasarimcisi (XAML Designer)",
            "Canli kod analizi, otomatik birim test kosucusu ve performans olcumu",
            "Git isbirligi ve Azure bulut dagitim entegrasyonu"
        )
    }
    "Git SCM" = @{
        Details = "Git; yazilim gelistirme surecinde kodlardaki degisiklikleri kaydeden, farkli surumleri yoneten ve GitHub/GitLab gibi platformlar uzerinden takim calismasini saglayan dagitik surum kontrol sistemidir."
        Features = @(
            "Kod projelerinde dallanma (Branch) ve birlestirme (Merge) yonetimi",
            "Proje gecmisine donme, yapilan hatalari geri alma ve farklari (Diff) inceleme",
            "GitHub, GitLab ve Bitbucket uzak depolariyla kolay senkronizasyon",
            "Git Bash guclu komut satiri terminali ve GUI araclari"
        )
    }
    "Python 3.13" = @{
        Details = "Python 3.13; yapay zeka, veri analizi, makine ogrenimi, web gelistirme ve sistem otomasyonu alanlarinda dunyada en cok tercih edilen modern programlama dilinin resmi calisma ortamidir."
        Features = @(
            "Yapay zeka (PyTorch, TensorFlow) ve veri bilimi (Pandas, NumPy) temel platformu",
            "Pip paket yoneticisi ile yuzbinlerce acik kaynak kutuphaneye erisim",
            "Hizli script yazma, anlasilir sozdizimi ve kolay ogrenim",
            "Windows ortam degiskenlerine (PATH) otomatik entegrasyon"
        )
    }
    "Java JDK 21" = @{
        Details = "Oracle Java Development Kit (JDK 21 LTS); Java programlama diliyle uygulama, oyun, sunucu ve Minecraft modlari gelistirmek icin gerekli resmi Java Geliştirme Kitidir. Uzun Sureli Destek (LTS) surumudur."
        Features = @(
            "Uzun Sureli Destek (LTS) ile maksimum sistem kararliligi ve guvenlik yamalari",
            "Sanal Is Parcaciklari (Virtual Threads) ile yuksek performansli sunucu islemleri",
            "Java derleyicisi (javac), JVM ve resmi Java kutuphane paketleri",
            "Minecraft gelistirme, kurumsal yazilimlar ve Android gelistirme icin temel gereksinim"
        )
    }
    "Java Runtime Environment" = @{
        Details = "Java Runtime Environment (JRE 8); Java tabanli masaustu uygulamalarini, .jar uzantili programlari ve klasik Minecraft oyununu calistirmak icin gerekli resmi Java sanal makinesidir."
        Features = @(
            ".jar uzantili Java programlarini tek tikla calistirma yetenegi",
            "Minecraft ve Java tabanli oyunlar icin zorunlu calisma altyapisi",
            "Dahili guvenlik kalkani ve otomatik bellek temizleme motoru",
            "Hafif ve arka planda sorunsuz calisma destegi"
        )
    }
    "C# / .NET SDK" = @{
        Details = ".NET SDK; modern Windows uygulamalari, REST API'leri, mikroservisler ve konsol programlari gelistirmek ve derlemek icin Microsoft tarafindan saglanan resmi yazilim gelistirme kitidir."
        Features = @(
            "C# dilinin en guncel ozelliklerini ve derleyicisini icerir",
            "Windows, Linux ve macOS icin capraz platform uygulama derleme",
            "NuGet paket yoneticisi ile milyonlarca kutuphaneyi projeye ekleme",
            "Yuksek performansli JIT derleyicisi ve dusuk bellek tuketimi"
        )
    }
    "C++ Build Tools" = @{
        Details = "Visual Studio C++ Build Tools; tam Visual Studio IDE'sini kurmadan, Python C-uzantilari (pip install c++ derlemeleri), Node.js yerel modulleri ve C/C++ projelerini derlemek icin gerekli Microsoft derleyici paketidir."
        Features = @(
            "Python (pip install) paketlerinin Windows'ta hatasiz derlenmesini saglar",
            "MSVC C/C++ derleyicisi, baglayici (link.exe) ve CMake araclarini icerir",
            "Windows 10/11 SDK baslik dosyalarini sisteme entegre eder",
            "Gereksiz GUI olmadan yalnizca komut satiri derleyicilerini hafifce yukler"
        )
    }
    "Claude Code CLI" = @{
        Details = "Claude Code; Anthropic tarafindan gelistirilen, dogrudan komut satirinizda calisan ve tum kod tabaninizi tarayarak kod yazan, hata ayiklayan ve testleri calistiran otonom yapay zeka gelistirici aracidir."
        Features = @(
            "Terminalden dosyalari okuma, degistirme ve mimari kararlar alma",
            "Derleme hatalarini otomatik okuyarak hatayi kendi kendine duzeltme",
            "Git komutlari calistirma, commit olusturma ve PR hazirlama",
            "Genis baglam penceresi ile buyuk projeleri tek seferde kavrama"
        )
    }
    "Google Antigravity" = @{
        Details = "Google Antigravity; Google DeepMind tarafindan ileri duzey kodlama ve cift programlama (pair-programming) icin gelistirilen yapay zeka aracidir."
        Features = @(
            "Mimari planlar hazirlayarak karmasik projeleri adim adim uygulama",
            "Terminal ve dosya sistemiyle guvenli sekilde gorevleri tamamlama",
            "Gelistirici is akislari, kurallar ve otonom alt ajan (subagent) desteği",
            "Temiz kod mimarisi ve kapsamli test dogrulama altyapisi"
        )
    }
    "OpenAI Codex CLI" = @{
        Details = "OpenAI Codex CLI; terminalde dogal dille yazdiginiz istekleri saniyeler icinde calisir duruma getiren komut satiri yapay zeka asistanidir."
        Features = @(
            "Dogal dille komut satiri gorevleri yurutme",
            "Bash, PowerShell ve Python komutlarini otomatik olusturma",
            "Hizli betik yazimi ve sistem gorevleri otomasyonu",
            "Terminal uzerinde anlik kod cozumu ve aciklamasi"
        )
    }
    "Driver Booster" = @{
        Details = "IObit Driver Booster; bilgisayarinizdaki eski ve eksik ekran karti, ses, ag, Bluetooth ve anakart suruculerini tarayarak tek tikla en guncel WHQL surumlerine yukselten surucu guncelleyicidir."
        Features = @(
            "Milyonlarca WHQL sertifikali guvenli surucu veritabani",
            "Oyun bilesenlerini (DirectX, VC++ vb.) tespit edip otomatik tamamlama",
            "Guncelleme oncesi otomatik sistem geri yukleme noktasi alma guvenligi",
            "Ses gelmeme veya internet kopmasi gibi aygit sorunlarini onarma araci"
        )
    }
    "Display Driver Uninstaller (DDU)" = @{
        Details = "Display Driver Uninstaller (DDU); yeni ekran karti takildiginda veya oyunlarda surucu cokmesi yasandiginda NVIDIA, AMD ve Intel grafik suruculerini kayit defteriyle birlikte tamamen temizleyen hayati sistem aracidir."
        Features = @(
            "Surucu degisimi sonrasi olusan FPS dususu ve siyah ekran sorunlarini cozer",
            "Guvenli Mod'da (Safe Mode) tum surucu ve kayit defteri kalintilarini siler",
            "Yeni surucu kurulumunun sifir ve tertemiz bir zemine yapilmasini saglar",
            "Realtek ses karti surucu kalintilarini da derinlemesine temizler"
        )
    }
    "CPU-Z" = @{
        Details = "CPUID CPU-Z; bilgisayarinizin islemci modelini, cekirdek sayisini, voltajini, calisma saat hizini, anakart modelini ve RAM bellek zamanlamalarini ayrintili gosteren standart donanim bilgi aracidir."
        Features = @(
            "Islemci mimarisi, cekirdek/izlek sayisi, voltaj ve anlik saat frekansi gosterimi",
            "RAM belleklerin calisma frekansi (MHz), CL zamanlamalari ve kanal durumu (Dual Channel)",
            "Anakart marka, model ve mevcut BIOS surum bilgisi",
            "Dahili CPU Benchmark ile islemciyi diger islemcilerle karsilastirma testi"
        )
    }
    "Core Temp" = @{
        Details = "Core Temp; islemcinizin her bir cekirdegindeki sicakligi gercek zamanli olcen ve gorev cubugunda anlik gostererek asiri isinmalari onleyen ultra hafif donanim izleme aracidir."
        Features = @(
            "Her islemci cekirdeginin anlik, minimum ve maksimum sicaklik olcumu",
            "Gorev cubugunda (saatin yaninda) sicaklik degerlerini canli gosterme",
            "Asiri isinma korumasi ile kritik sicaklikta uyari verme veya bilgisayari kapatma",
            "Islemci anlik guc tuketimini (Watt) ve yuk yuzdesini izleme"
        )
    }
    "CrystalDiskInfo" = @{
        Details = "CrystalDiskInfo; bilgisayarinizdaki SSD ve sabit disklerin (HDD) saglik durumunu (yuzde olarak), sicakligini, toplam calisma saatini ve S.M.A.R.T. hata kayitlarini gosteren hayati disk teshis programidir."
        Features = @(
            "SSD saglik durumunu yuzde olarak (%100 Saglikli, Dikkat vb.) gosterir",
            "Disk calisma sicakligini gercek zamanli takip ederek kritik uyarilar verir",
            "Diske yazilan toplam veri miktarini (TBW) ve toplam calisma saatini hesaplar",
            "Bozuk sektor (Bad Sector) ve veri kaybi risklerini onceden haber verir"
        )
    }
    "CrystalDiskMark" = @{
        Details = "CrystalDiskMark; SSD, NVMe, sabit disk ve USB belleklerinizin sirali ve rastgele okuma/yazma hizlarini (MB/s cinsinden) olcerek vadettigi hiza ulasip ulasmadigini test eden standart benchmark aracidir."
        Features = @(
            "Sirali (Sequential) okuma ve yazma hizlarini olcme",
            "4K rastgele okuma/yazma testi ile gunluk kullanim ve oyun yukleme performansini test etme",
            "NVMe SSD, SATA SSD ve harici diskleri dogrulama",
            "Farkli test profilleri ile disk performansini zorlama"
        )
    }
    "MSI Afterburner + RTSS" = @{
        Details = "MSI Afterburner; ekran kartiniza guvenli hiz asirtma (overclock) yapmanizi, fan hiz egrilerini ayarlamanizi ve RivaTuner (RTSS) ile oyun icinde canli FPS, GPU ve CPU sicakliklarini ekrana yansitmanizi saglar."
        Features = @(
            "RivaTuner ile oyun icinde canli FPS, sicaklik, RAM ve GPU kullanim gostergesi (OSD)",
            "Ekran karti fanlarini sicakliga gore ozel kademeli calisacak sekilde ayarlama",
            "GPU cekirdek, bellek frekansi ve guc limitini (Power Limit) optimize etme",
            "Oyun ici ekran goruntusu ve yuksek kaliteli video kayit yetenegi"
        )
    }
    "NVIDIA App" = @{
        Details = "NVIDIA App; GeForce Experience ve klasik NVIDIA Denetim Masasi'ni tek bir modern platformda birlestiren, en yeni GeForce Game Ready surucu ve oyun grafik optimizasyon merkezidir."
        Features = @(
            "Game Ready ve Studio suruculerini tek tikla otomatik guncelleme",
            "YUKLU oyunlarin grafik ayarlarini bilgisayarinizin gucune gore optimize etme",
            "RTX Dynamic Vibrance ve RTX HDR yapay zeka oyun filtreleri",
            "Oyun ici arayuz, 120 FPS ShadowPlay video kaydi ve performans olcumu"
        )
    }
    "NVIDIA Control Panel" = @{
        Details = "NVIDIA Denetim Masasi; NVIDIA ekran kartinizin 3D grafik ayarlarini, monitor yenileme hizini (Hz), G-Sync teknolojisini, cozunurlugu ve renk doygunlugunu ayarladiginiz resmi kontrol panelidir."
        Features = @(
            "Ultra Dusuk Gecikme Modu (Ultra Low Latency) ile oyunlarda input lag dusurme",
            "Monitor yenileme hizi (Hz), cozunurluk ve G-Sync yapilandirmasi",
            "DSR (Dynamic Super Resolution) ve kenar yumusatma ayarlari",
            "Oyun bazli ozel grafik ayarlari ve Digital Vibrance renk doygunlugu"
        )
    }
    "AMD Radeon Software" = @{
        Details = "AMD Software: Adrenalin Edition; AMD Radeon grafik kartlari icin en guncel suruculeri saglayan, HYPR-RX, FSR ve Anti-Lag gibi FPS artirici teknolojileri barindiran resmi yazilimdir."
        Features = @(
            "Radeon Super Resolution (RSR) ve HYPR-RX ile oyunlarda yuksek FPS artisi",
            "Radeon Anti-Lag ile giris gecikmesini (input lag) minimum seviyeye indirme",
            "Dahili ekran kaydetme, canli yayin ve anlik tekrar (Instant Replay) sistemi",
            "GPU voltaj, frekans, sicaklik izleme ve fan ayari araclari"
        )
    }
    "AMD Ryzen Chipset" = @{
        Details = "AMD Ryzen Chipset Drivers; AMD Ryzen islemcili anakartlarin (A320, B450, B550, X570, B650, X670 vb.) guc yonetimini, islemci cekirdek zamanlamasini ve PCIe veri yollarini optimize eden resmi surucudur."
        Features = @(
            "Ryzen islemcilerin en hizli calisan cekirdekleri secip yonetmesini saglar",
            "AMD Ryzen Guc Plani ile bosta dusuk enerji, oyunda maksimum performans sunar",
            "PCIe 4.0/5.0 veri yolu ve NVMe SSD kararliligini garanti eder",
            "Mavi ekran ve sistem donma risklerini ortadan kaldirir"
        )
    }
    "Realtek Audio Control" = @{
        Details = "Realtek Audio Control; anakartinizdaki dahili Realtek ses cipini yoneten, kulaklik ve hoparlor cikislarini duzenleyen, mikrofon gurultu engelleme ve ekolayzer ayarlarini iceren resmi uygulamadir."
        Features = @(
            "Jak algilama ozelligi ile takilan kulaklik/hoparlor cihazini otomatik tanima",
            "Mikrofon icin yankiyi onleme ve arka plan gurultusunu temizleme filtreleri",
            "Muzik, oyun ve film modlarina ozel ekolayzer (EQ) profilleri ve bas guclendirme",
            "Yuksek cozunurluklu ses formatlari (24-bit / 192kHz) yapilandirmasi"
        )
    }
    "Intel Driver Support" = @{
        Details = "Intel Driver & Support Assistant (DSA); bilgisayarinizdaki Intel bilesenlerini (Wi-Fi, Bluetooth, Entegre Grafik ve Yonga Seti) otomatik tarayarak en guncel resmi suruculeri kuran asistan yazilimdir."
        Features = @(
            "Intel Wi-Fi ve Bluetooth suruculerini guncel tutarak internet kopmalarini onleme",
            "Sistem donanim bilesenlerini tek raporda detayli listeleme",
            "Yeni bir surucu ciktiginda gorev cubugundan anlik bildirim verme",
            "Dogrudan Intel guvenli sunucularindan otomatik kurulum"
        )
    }
    "Intel Graphics Software" = @{
        Details = "Intel Graphics Software / Command Center; Intel entegre UHD, Iris Xe ve harici Intel Arc ekran kartlarinin surucu guncellemelerini, ekran cozunurluklerini ve oyun grafik optimizasyonlarini yoneten resmi yazilimdir."
        Features = @(
            "Intel ekran kartiniz icin en son Game On suruculerini kurma",
            "Ekran parlaklik, kontrast, doygunluk ve renk kalibrasyonu ayarlari",
            "Intel XeSS yapay zeka cozunurluk yukseltme destegi",
            "Oyun ici arayuz ve anlik performans olcum gostergeleri"
        )
    }
    "HP Support Assistant" = @{
        Details = "HP Support Assistant; HP masaustu ve dizustu bilgisayarlar icin resmi BIOS, surucu ve donanim yazilimi guncellemeleri sunan, sistem sagligini denetleyen resmi bakim programidir."
        Features = @(
            "HP anakart BIOS ve donanim yazilimi guncellemelerini guvenle kurma",
            "Pil omru, sarj sagligi ve donanim bilesenleri tani testleri",
            "Cihazin resmi garanti durumu ve HP musteri destek hatti baglantisi",
            "Otomatik sistem performansi ve depolama temizlik araclari"
        )
    }
    "Logitech G HUB" = @{
        Details = "Logitech G HUB; Logitech G serisi oyuncu fareleri, klavyeleri, kulakliklari ve direksiyon setlerinin RGB aydinlatmasini, DPI hassasiyetini ve makro tuslarini ozellestiren resmi kontrol yazilimidir."
        Features = @(
            "Fare DPI kademelerini, tarama frekansini ve tus atamalarini belirleme",
            "LIGHTSYNC RGB ile ekipmanlarin oyun ve muzik ritmiyle senkronize aydinlatmasi",
            "Blue VO!CE ses filtreleri ile mikrofon sesini yayinci kalitesine yukseltme",
            "Oyunlara ozel otomatik profil degisimi ve topluluk profili indirme"
        )
    }
    "Razer Synapse" = @{
        Details = "Razer Synapse; Razer oyuncu ekipmanlarinin (fare, klavye, kulaklik vb.) Chroma RGB aydinlatmasini, tus makrolarini, DPI hassasiyetini ve kalibrasyonunu yoneten resmi donanim merkezidir."
        Features = @(
            "Razer Chroma RGB efektleri ve oyun ici dinamik aydinlatma entegrasyonu",
            "Razer Hypershift teknolojisi ile her tusa ikincil bir islev atama",
            "Mousepad yuzey kalibrasyonu ve ayarlanabilir kalkis mesafesi (LOD)",
            "Bulut tabanli profil esitleme ile ayarlari hicbir zaman kaybetmeme"
        )
    }
    "Corsair iCUE" = @{
        Details = "Corsair iCUE; Corsair marka sivi sogutma, fan, RAM, kasa, klavye ve farelerin RGB aydinlatmasini senkronize eden, fan devirlerini ve donanim sicakliklarini kontrol eden gelismis yazilimdir."
        Features = @(
            "Tum Corsair bilesenleri arasinda canli ve dinamik RGB isik senkronizasyonu",
            "Sivi sogutma pompasi ve kasa fanlarini sicakliga gore ozel devirde calistirma",
            "Islemci, ekran karti ve anakart sicakliklarini detayli grafiklerle izleme",
            "Klavyeler ve fareler icin gelismis tus makro ve yeniden esleme motoru"
        )
    }
    "SteelSeries GG" = @{
        Details = "SteelSeries GG; SteelSeries ekipman ayarlarinin yani sira, oyunlarda ayak seslerini netlestiren unlu 'Sonar' ses sistemini ve klip yakalama araci 'Moments'i iceren profesyonel oyuncu yazilimidir."
        Features = @(
            "Sonar Audio ile her oyuna ozel profesyonel ekolayzer ve ses netlestirme",
            "Moments araci ile oyun icindeki onemli vurus ve anlari otomatik klip kaydetme",
            "Engine ile fare hassasiyeti, tus atamalari ve RGB aydinlatma ayarlari",
            "Discord, oyun ve muzik seslerini ayri kanallardan yoneten mikser"
        )
    }
    "Bitwarden" = @{
        Details = "Bitwarden; tum web siteleri sifrelerinizi, kredi kartlarinizi ve gizli notlarinizi Sifir Bilgi (Zero-Knowledge) guvencesiyle sifreleyen guvenli ve acik kaynakli parola yoneticisidir."
        Features = @(
            "Guclu, tahmin edilemez ozel sifreler ureterek hesap guvenligini saglama",
            "Web sitelerinde kullanici adi ve sifreleri tek tikla otomatik doldurma",
            "Bilgisayar, telefon ve tarayicilar arasinda aninda guvenli senkronizasyon",
            "Iki faktorlu dogrulama (2FA) kodlarini saklama ve uretme destegi"
        )
    }
    "Kaspersky" = @{
        Details = "Kaspersky; virusleri, fidye yazilimlarini (Ransomware), truva atlarini ve sifirinci gun tehditlerini gercek zamanli engelleyen dunya lideri odullu antivirus guvenlik paketidir."
        Features = @(
            "Gercek zamanli bulut korumasi ile zararli dosyalari aninda yakalama",
            "Fidye yazilimlarina karsi dosyalari sifrelemeye calisan surecleri bloklama",
            "Guvenli Gezinti ile sahte banka ve oltalama (phishing) sitelerini engelleme",
            "Oyun Modu ile oyun oynarken bildirimleri ve arkaplan taramalarini askiya alma"
        )
    }
    "Bitdefender" = @{
        Details = "Bitdefender Total Security; bilgisayari yavaslatmadan maksimum koruma sunan, cok katmanli fidye korumasi ve davranissal tehdit algilama motoruna sahip lider antivirus programidir."
        Features = @(
            "Sistem performansini yavaslatmadan arka planda sessiz ve guclu koruma",
            "Cok katmanli fidye yazilimi engelleme ve otomatik dosya kurtarma",
            "Safepay korumali ozel tarayici ile guvenli bankacilik ve internet alisverisi",
            "Guvenlik acigi tarayicisi ile eksik Windows yamalarini bulma"
        )
    }
    "ESET NOD32" = @{
        Details = "ESET NOD32; efsanevi dusuk bellek ve islemci kullanimiyla taninan, sistemi yormayan ve oyun performansini etkilemeyen efsanevi guvenlik yazilimidir."
        Features = @(
            "Ultra hafif motor ile en eski bilgisayarlarda bile sifir kasma ve donma",
            "Gelistirilmis sezgisel (Heuristic) analiz ile bilinmeyen tehditleri yakalama",
            "Web ve e-posta kalkanlari ile sakincali icerikleri onleme",
            "Oyuncu Modu ile tam ekran oyunlarda bildirimleri sessize alma"
        )
    }
    "McAfee" = @{
        Details = "McAfee Total Protection; virus korumasi, guvenli web gezintisi, guvenlik acigi taramasi ve kalici dosya ogutucu iceren kapsamli bir guvenlik kalkanidir."
        Features = @(
            "Gercek zamanli antivirüs ve casus yazilim tarama motoru",
            "Supheli indirmeleri ve zararli baglantilari otomatik engelleme",
            "Dosya Ogutucu (Shredder) ile hassas verileri kalici ve geri donussuz silme",
            "Ev Wi-Fi agini ve bagli cihazlari guvenlik denetiminden gecirme"
        )
    }
    "Malwarebytes" = @{
        Details = "Malwarebytes; standart antiviruslerin gozden kacirabildigi reklam yazilimlarini (Adware), tarayici korsanlarini (Hijacker) ve inatci casus yazilimlari temizleyen uzman guvenlik aracidir."
        Features = @(
            "Bilgisayara sizmis inatci zararli yazilimlari derinlemesine temizleme",
            "Istenmeyen programlari (PUP) ve tarayici ana sayfasini degistiren korsanlari yok etme",
            "Mevcut antivirus programinizla cakismaidan yan yana calisabilme",
            "Guvenli web kalkanlari ve exploit engelleme destegi"
        )
    }
    "Avast Free Antivirus" = @{
        Details = "Avast Free Antivirus; dunya capinda yuz milyonlarca kullanicisi olan, dosya, web ve e-posta kalkanlariyla temel bilgisayar korumasini ucretsiz sunan populer guvenlik yazilimidir."
        Features = @(
            "Akilli Tarama ile tek hamlede virusleri, guvensiz sifreleri ve aciklari bulma",
            "Wi-Fi Ag Denetcisi ile ev agindaki guvenlik aciklarini tespit etme",
            "Supheli dosyalari bulutta izole ederek inceleyen Siber Yakalama",
            "Rahatsiz Etme Modu ile oyun ve film esnasinda bildirimleri gizleme"
        )
    }
    "Ventoy" = @{
        Details = "Ventoy; USB bellegi her format dosyasinda yeniden bicimlendirmeye gerek kalmadan, ISO dosyalarini dogrudan icine surukle-birak ile kopyalayip calistirabileceginiz devrimsel format aracidir."
        Features = @(
            "USB bellegi sadece bir kez hazirlayip icine istediginiz kadar ISO atabilme",
            "Ayni USB'de Windows 10, Windows 11, Linux ve kurtarma ISO'larini bir arada tutma",
            "Hem modern UEFI hem de eski Legacy BIOS sistemleriyle tam uyumluluk",
            "USB bellegin icine normal kisisel dosyalarinizi da kaydetmeye devam edebilme"
        )
    }
    "Rufus" = @{
        Details = "Rufus; Windows ve Linux ISO dosyalarini rekor hizda USB bellege yazdiran; Windows 11 icin TPM 2.0, Secure Boot ve Microsoft hesabi zorunluluklarini kaldirabilen vazgecilmez format aracidir."
        Features = @(
            "Windows 11 kurulumundaki TPM 2.0, Secure Boot ve 8GB RAM sinirini tek tikla kaldirma",
            "Microsoft hesabi yerine yerel (Local) kullanici ile kuruluma izin verme",
            "Diger tum yazdirma araclarina gore 2 kata varan daha hizli yazma performansi",
            "GPT (UEFI) ve MBR (Eski BIOS) bolumleme duzenleriyle tam uyum"
        )
    }
    "Microsoft PC Manager" = @{
        Details = "Microsoft PC Manager; Microsoft tarafindan Windows 10 ve 11 icin ozel olarak gelistirilen guvenli, hafif, tek tikla RAM temizleyen ve gereksiz dosyalari silen resmi optimizasyon aracidir."
        Features = @(
            "Tek tikla RAM bellegi bosaltma ve gereksiz gecici dosyalari temizleme",
            "Baslangicta acilan programlari yoneterek bilgisayarin acilisini hizlandirma",
            "Eski Windows guncelleme artiklarini ve buyuk dosyalari derinlemesine temizleme",
            "Windows Guvenligi ile entegre hizli sistem sagligi ve virus taramasi"
        )
    }
    "Microsoft PowerToys" = @{
        Details = "Microsoft PowerToys; Microsoft muhendisleri tarafindan ileri duzey kullanicilar icin gelistirilen; gelismis pencere duzeni (FancyZones), Mac benzeri hizli arama, renk secici ve metin cikarici arac takimdir."
        Features = @(
            "FancyZones ile genis ekranlari bolgelerle ayirip pencereleri hizlica yerlestirme",
            "Alt+Space tuslariyla Mac Spotlight benzeri ultra hizli program/dosya arama (PowerToys Run)",
            "Ekrandaki gorsellerin uzerindeki yazilari OCR ile kopyalama (Text Extractor)",
            "Toplu dosya yeniden adlandirma, gorsel boyutlandirma ve fare bulucu araclari"
        )
    }
    "Lightshot" = @{
        Details = "Lightshot; klavyedeki PrintScreen tusuna bastiginiz anda ekranin istediginiz bolgesini secip uzerine ok, yazi, cizgi eklemenizi ve tek tikla kaydetmenizi saglayan hafif ekran yakalama aracidir."
        Features = @(
            "Ekranin istenen alanini aninda secip tek tusla panoya kopyalama",
            "Ekran goruntusu uzerine canli yazi yazma, ok, cerceve ve vurgulayici cizme",
            "Tek tikla gorseli internete yukleyip aninda paylasilabilir kisa link alma",
            "Secilen bolgedeki resmi Google'da aratarak benzer gorselleri bulma"
        )
    }
    "Flameshot" = @{
        Details = "Flameshot; zengin cizim araclari, hassas verileri buzlama (blur) yetenegi ve yuksek kisisellestirme secenekleri sunan acik kaynakli profesyonel ekran goruntusu alma yazilimidir."
        Features = @(
            "Kisisel bilgileri, sifreleri veya yuzleri gizlemek icin aninda piksellestirme (Blur)",
            "Ok, daire, dikdortgen, numara sayaci ve ozel metin ekleme araclari",
            "Ekran goruntusunu dogrudan Imgur yukleme veya yerel dosyaya kaydetme",
            "Ozel klavye kisayollari ile seri ekran goruntusu yakalama"
        )
    }
    "ShareX" = @{
        Details = "ShareX; ekran goruntusu yakalama, ekran videosu ve GIF kaydetme, renk secme, QR kod cozme ve onlarca bulut servisine otomatik yukleme yapabilen en gelismis acik kaynak aractir."
        Features = @(
            "Tam ekran, pencere veya serbest alan ekran goruntusu, video ve GIF kaydi",
            "Cekilen gorsellere otomatik golge, cerceve, filigran veya efekt uygulama",
            "Gorseli tek hamlede Imgur, Google Drive, Dropbox vb. servislere otomatik yukleme",
            "Dahili ekran cetveli, renk secici, goruntu birlestirici ve QR kod okuyucu"
        )
    }
    "Everything" = @{
        Details = "Everything (voidtools); bilgisayarinizdaki milyonlarca dosya ve klasoru adini yazdiginiz anda milisaniyeler icinde onunuze getiren dunyanin en hizli yerel dosya arama motorudur."
        Features = @(
            "Standart Windows aramasindan yuzlerce kat daha hizli; sonuclari aninda gosterir",
            "Dosya boyutu, turu ve degistirilme tarihine gore gelismis filtreleme ve regex destegi",
            "Sistemi hic yormayan son derece hafif yapi ve yok denecek kadar az RAM kullanimi",
            "Tum sabit diskleri ve harici USB diskleri saniyeler icinde indeksleme"
        )
    }
    "TreeSize Free" = @{
        Details = "TreeSize Free; sabit diskinizde yer kaplayan devasa dosyalari ve klasorleri boyutlarina gore buyukten kucuge siralayarak diskte bos alan acmanizi saglayan profesyonel analiz aracidir."
        Features = @(
            "Hangi klasorun kac GB yer kapladigini hiyerarsik agac semasiyla gosterir",
            "Alt klasorlerin derinliklerine inerek gizli kalmis buyuk dosyalari bulur",
            "Dosya Gezgini sag tik menusunden dogrudan secilen klasoru tarayabilir",
            "NTFS sikistirma oranlarini ve dosya turu dagilimini raporlar"
        )
    }
    "CapCut" = @{
        Details = "CapCut Desktop; TikTok, YouTube Shorts, Instagram Reels ve uzun videolar icin yapay zeka destekli otomatik altyazi, gecis efektleri ve ses filtreleri sunan populer video kurgu programidir."
        Features = @(
            "Turkce dahil konusmalari otomatik taniyarak tek tikla senkronize altyazi olusturma",
            "Yuzlerce populer trend gecis efekti, animasyon, ses efekti ve telifsiz muzik",
            "Yapay zeka ile videodan arka plani ayirma ve yesil ekran (Chroma Key) destegi",
            "4K 60 FPS yuksek kaliteli video disa aktarma ve hiz egrisi (Speed Ramping)"
        )
    }
    "Adobe Creative Cloud" = @{
        Details = "Adobe Creative Cloud; Photoshop, Premiere Pro, After Effects, Illustrator ve InDesign gibi dunyaca unlu tasarim uygulamalarini indirmenizi, kurmanizi ve lisansinizi yonetmenizi saglayan merkezdir."
        Features = @(
            "Tum profesyonel Adobe uygulamalarini tek tikla yukleme ve otomatik guncelleme",
            "Adobe Fonts uzerinden binlerce kaliteli yazi tipini sisteme yukleme",
            "Bulut belgeleri, fircalar, renk paletleri ve kisisel varliklarin senkronizasyonu",
            "Behance portfolyo ve Adobe Stock gorsel kutuphanesi entegrasyonu"
        )
    }
    "Adobe Acrobat Reader" = @{
        Details = "Adobe Acrobat Reader; PDF belgelerini acmak, okumak, yazdirmak, resmi formlari doldurmak, dijital imza atmak ve metinleri vurgulamak icin dunya standardi olan resmi PDF goruntuleyicisidir."
        Features = @(
            "PDF belgelerini en yuksek cozunurluk ve bozulmayan orijinal duzenle goruntuleme",
            "Belgelere metin kutulari, yapiskan notlar ve renkli vurgulayicilar ekleme",
            "Resmi dilekce ve formlari bilgisayarda doldurup e-imza ile imzalayabilme",
            "Teknik cizimleri ve e-kitaplari akici sayfa gecisleriyle rahatca okuma"
        )
    }
    "Blender 3D" = @{
        Details = "Blender; 3D modelleme, canlandirma (animasyon), gorsel efekt (VFX), fizik simulasyonlari, video kurgu ve render alma islemlerini tek programda sunan tamamen ucretsiz profesyonel acik kaynak yazilimdir."
        Features = @(
            "Karakter modelleme, poligon duzenleme ve dijital heykel (Sculpting) araclari",
            "Gercekci Cycles (Isin Izleme) ve ultra hizli EEVEE gercek zamanli render motorlari",
            "Kemikleme (Rigging), duman, ates, sivi ve kumas fizik simulasyonlari",
            "Unreal Engine ve Unity oyun motorlari icin model ve animasyon disa aktarma"
        )
    }
    "GIMP" = @{
        Details = "GIMP (GNU Image Manipulation Program); katmanlar, ozel fircalar, gelismis renk filtreleri ve fotograf manipulasyon araclari sunan tamamen ucretsiz ve acik kaynakli resim duzenleyicisidir."
        Features = @(
            "Fotograf rotuslama, arka plan kesme ve detayli renk tonlama araclari",
            "Katmanlar (Layers), maskeler ve ayarlanabilir seffaflik kanallari",
            "PSD, PNG, JPEG, TIFF dahil neredeyse tum gorsel formatlarini acma ve kaydetme",
            "Girisimci gelistiricilerin sundugu genis eklenti ve firca destegi"
        )
    }
    "HandBrake" = @{
        Details = "HandBrake; buyuk boyuttaki video dosyalarini goruntu kalitesinden neredeyse hic odun vermeden sikistiran ve MP4/MKV formatlarina donusturen acik kaynakli video donusturucudur."
        Features = @(
            "GB seviyesindeki videolari MB seviyesine dusurerek disk ve yukleme tasarrufu",
            "NVIDIA NVENC, AMD ve Intel donanim hizlandirmasi ile super hizli render alma",
            "Telefon, tablet, televizyon ve web icin hazir cozum on ayarlari",
            "Coklu ses kanali secimi, altyazi gomumu ve toplu donusturme kuyrugu"
        )
    }
    "7-Zip" = @{
        Details = "7-Zip; 7z, ZIP, RAR, TAR ve ISO arsivlerini acip olusturabilen, yuksek sikistirma orani ve askeri duzeyde sifreleme sunan ucretsiz ve reklamsiz efsanevi arsiv yoneticisidir."
        Features = @(
            "Ozel 7z formati ile diger programlardan cok daha yuksek sikistirma orani",
            "Sifreli arsivler icin kirilmasi imkansiz AES-256 guvenlik standardi",
            "RAR, ZIP, 7Z, ISO, TAR, GZ dahil onlarca arsiv formatini aninda cikarma",
            "Windows Dosya Gezgini sag tik menusune sorunsuz ve hafif entegrasyon"
        )
    }
    "WinRAR" = @{
        Details = "WinRAR; dunyanin en cok kullanilan RAR ve ZIP arsivleme yazilimidir. Buyuk dosyalari parcalara bolme ve hasar gormus arsivleri kurtarma yetenegiyle bilinir."
        Features = @(
            "Geliskin RAR ve RAR5 formatinda hizli ve guvenli veri sikistirma",
            "Bozulmus veya eksik inmis arsivleri onarma (Kurtarma Kaydi) destegi",
            "Devasa dosyalari belirli boyutlarda parcalara (part1, part2...) ayirarak paketleme",
            "Kendi kendine acilan (SFX .exe) calistirilabilir arsiv olusturabilme"
        )
    }
    "PeaZip" = @{
        Details = "PeaZip; 200'den fazla arsiv formatini taniyan, modern tasarimli, parola kasasi ve dosya butunluk kontrolu (Checksum) saglayan guvenli acik kaynak arsivleyicidir."
        Features = @(
            "200'un uzerinde dosya uzantisini destekleyen genis arsivleme motoru",
            "Dahili guvenli parola kasasi ve iki asamali sifreli arsiv olusturma",
            "Dosya dogrulamasi icin SHA-256, MD5 ve CRC32 hash hesaplama araci",
            "Verileri geri getirilemez sekilde imha eden Guvenli Silme (Secure Delete)"
        )
    }
    "JDownloader 2" = @{
        Details = "JDownloader 2; internet sitelerindeki videolari, sesleri ve dosyalari otomatik yakalayan, coklu baglanti ile indirme hizini sonuna kadar kullanan gelismis indirme yoneticisidir."
        Features = @(
            "Panoya kopyalanan baglantilari otomatik algilayarak video ve sesleri ayirma",
            "Baglantilari parcalara bolerek internet bant genisligini yuzde yuz kullanma",
            "Yarida kalan indirmeleri duraklatma, devam ettirme ve otomatik arsivden cikarma",
            "Zamanlanmis indirme planlamasi ve premium dosya barindirici hesap yonetimi"
        )
    }
    "uTorrent" = @{
        Details = "uTorrent; BitTorrent agi uzerinden buyuk boyutlu dosyalari, ISO kaliplarini ve medyayi esler arasi (P2P) yuksek hizda indirmenizi saglayan klasik torrent istemcisidir."
        Features = @(
            "Sistemi yormayan son derece hafif ve dusuk bellek kullanimli calisma",
            "Indirme ve yukleme hiz limitlerini ayarlayarak interneti kilitlememe",
            "Torrent icerisindeki istenmeyen dosyalari secip sadece gerekli kisimlari indirme",
            "Medya dosyalari inerken onizleme yapabilme yetenegi"
        )
    }
    "Chrome Remote Desktop" = @{
        Details = "Chrome Remote Desktop; evdeki veya ofisteki bilgisayariniza baska bir bilgisayardan, tabletten ya da akilli telefondan internet uzerinden guvenle baglanmanizi saglayan resmi Google uzaktan kontrol aracidir."
        Features = @(
            "Google hesabinizla sifrelenmis guvenli ve pratik uzaktan erisim",
            "Akilli telefondan dokunmatik fare ve klavyeyle masaustunu yonetebilme",
            "Arkadaslariniza teknik destek vermek icin tek kullanimlik erisim kodu paylasma",
            "Dusuk internet baglantilarinda dahi akici goruntu ve ekran yenileme"
        )
    }
    "Cloudflare WARP" = @{
        Details = "Cloudflare WARP; internet trafiginizi Cloudflare'in guvenli 1.1.1.1 DNS altyapisi ve optimize edilmis WireGuard tuneli uzerinden yonlendirerek daha hizli, sansursuz ve gizli internet sunan resmi aractir."
        Features = @(
            "DNS sorgularini sifreleyerek internet servis saglayicisi takibini ve engelleri asma",
            "Modern ve optimize edilmis WireGuard tabanli yuksek hizli baglanti tuneli",
            "Oyunlarda sunuculara giden rotayi optimize ederek ping dalgalanmalarini azaltma",
            "Sifir Kayit (No-Log) politikasi ile internet gizliliginizi garanti altina alma"
        )
    }
    "SplitWire Turkey" = @{
        Details = "SplitWire Turkey; Discord ve Turkiye'de erisimi kisitlanan internet servislerine kesintisiz erisim saglamak amaciyla WireSock ve DPI (Derin Paket Inceleme) atlatma yontemlerini kullanan ozel gelistirilmis yerli aractir."
        Features = @(
            "Discord ses ve metin kanallarini sorunsuz acma ve dusuk gecikmeli sesli sohbet",
            "Bolunmus Tunel (Split Tunnel) sayesinde yalnizca kisitlanan uygulamalari tuneller, internetinizi yavaslatmaz",
            "Tek tikla acma/kapama ve Windows baslangicinda otomatik calisma secenegi",
            "Guvenli WireSock altyapisi ve acik kaynak kod guvencesi"
        )
    }
    "AnyDesk" = @{
        Details = "AnyDesk; DeskRT video kodeki sayesinde neredeyse sifir gecikmeyle uzaktaki bir bilgisayara baglanmanizi, teknik destek vermenizi ve yuksek hizda dosya aktarmanizi saglayan profesyonel uzak masaustu programidir."
        Features = @(
            "DeskRT kodeki ile 60 FPS akici uzaktan ekran goruntusu ve minimum gecikme",
            "Iki bilgisayar arasinda surukle-birak ile yuksek hizli dosya transferi",
            "Katilimsiz Erisim (Unattended Access) ile sifre girerek uzaktaki PC'ye aninda baglanma",
            "Uzaktan yazicidan cikti alma (Remote Print) ve ses aktarim destegi"
        )
    }
    "TeamViewer" = @{
        Details = "TeamViewer; dunyanin en koklu ve guvenli kurumsal uzak masaustu erisim, online toplanti ve teknik destek platformudur. 256-bit AES uctan uca sifreleme ile korunur."
        Features = @(
            "ID ve tek kullanimlik sifre ile saniyeler icinde uzak bilgisayara erisme",
            "256-bit AES oturum sifrelemesi ve iki asamali dogrulama ile yuksek guvenlik",
            "Uzaktan sistemi guvenli modda yeniden baslatip oturumu surdurebilme",
            "Ekran uzerine cizim yapma, sesli/goruntulu iletisim ve oturum kaydi"
        )
    }
    "Revo Uninstaller" = @{
        Details = "Revo Uninstaller; programlari kaldirdiktan sonra arkada kalan tum kayit defteri anahtarlarini, cop dosyalari ve gereksiz klasorleri derinlemesine tarayip tamamen yok eden profesyonel kaldiricidir."
        Features = @(
            "Standart kaldiricilarin geride biraktigi binlerce kayit defteri kalintisini temizler",
            "Kaldirilmayan inatci programlar icin Zorla Kaldirma (Forced Uninstall) destegi",
            "Avci Modu (Hunter Mode) ile ekrandaki bir pencereyi veya simgeyi hedef alarak silme",
            "Islem oncesi otomatik sistem geri yukleme noktasi ve kayit defteri yedegi alma"
        )
    }
    "CCleaner" = @{
        Details = "CCleaner; tarayici gecmisini, onbellekleri, gecici sistem dosyalarini ve gecersiz kayit defteri anahtarlarini temizleyerek diskte bos alan acan ve sistemi ferahlatan temizlik programidir."
        Features = @(
            "Tum tarayicilarin cerezlerini, gecmisini ve gereksiz onbellegini tek tikla temizleme",
            "Gecici Windows dosyalarini (Temp), cop kutusunu ve log dosyalarini bosaltma",
            "Kayit Defteri Temizleyicisi ile hatali ve sahipsiz girdileri guvenle onarma",
            "Baslangicta acilan uygulamalari yoneterek bilgisayar acilis suresini kisaltma"
        )
    }
}


$global:apps = @(
# Tarayıcı & İletişim & Sosyal Medya
    @{Name="Telegram Desktop"; Id="Telegram.TelegramDesktop"; StoreId="9NZTWSQNTD0S"; NormalId="Telegram.TelegramDesktop"; HasDual="1"; Slug="telegram"; Domain="telegram.org"; Desc="Hızlı, güvenli ve bulut tabanlı anlık mesajlaşma uygulaması"; Cat="Browsers"},
    @{Name="Instagram"; Id="9NBLGGH5L9XT"; StoreId="9NBLGGH5L9XT"; StoreOnly="1"; Slug="instagram"; Domain="instagram.com"; Desc="Resmi Meta Instagram masaüstü uygulaması. Reels, DM ve hikayeler"; Cat="Browsers"},
    @{Name="Facebook"; Id="9WZDNCRFJ2WL"; StoreId="9WZDNCRFJ2WL"; StoreOnly="1"; Slug="facebook"; Domain="facebook.com"; Desc="Resmi Meta Facebook masaüstü uygulaması. Haber kaynağı ve gruplar"; Cat="Browsers"},
    @{Name="Google Chrome"; Id="Google.Chrome"; Slug="googlechrome"; Domain="google.com"; IconUrl="https://upload.wikimedia.org/wikipedia/commons/8/87/Google_Chrome_icon_%282011%29.png"; DirectUrl="https://upload.wikimedia.org/wikipedia/commons/8/87/Google_Chrome_icon_%282011%29.png"; Desc="Dünyanın en popüler web tarayıcısı"; Cat="Browsers"},
    @{Name="Opera"; Id="Opera.Opera"; StoreId="XPDBZ4MPRKNN30"; NormalId="Opera.Opera"; HasDual="1"; Slug="opera"; Domain="opera.com"; Desc="Dahili VPN ve engelleyicili tarayıcı"; Cat="Browsers"},
    @{Name="Mozilla Firefox"; Id="Mozilla.Firefox"; StoreId="9NZVDKPMR9RD"; NormalId="Mozilla.Firefox"; HasDual="1"; Slug="firefox"; Domain="mozilla.org"; Desc="Gizlilik odaklı açık kaynaklı tarayıcı"; Cat="Browsers"},
    @{Name="Microsoft Edge"; Id="Microsoft.Edge"; StoreId="XPFFTQ037JWMHS"; NormalId="Microsoft.Edge"; HasDual="1"; Slug="microsoftedge"; Domain="microsoft.com"; IconUrl="https://upload.wikimedia.org/wikipedia/commons/7/7e/Microsoft_Edge_logo_%282019%29.png"; DirectUrl="https://upload.wikimedia.org/wikipedia/commons/7/7e/Microsoft_Edge_logo_%282019%29.png"; Desc="Windows entegre Chromium tarayıcı"; Cat="Browsers"},
    @{Name="Brave Browser"; Id="Brave.Brave"; StoreId="XP8C9QZMS2PC1T"; NormalId="Brave.Brave"; HasDual="1"; Slug="brave"; Domain="brave.com"; Desc="İzleyicileri engelleyen gizlilik tarayıcısı"; Cat="Browsers"},
    @{Name="Zen Browser"; Id="Zen-Team.Zen-Browser"; Slug="zen-browser"; Domain="zen-browser.app"; Desc="Yeni nesil minimalist açık kaynak tarayıcı"; Cat="Browsers"},
    @{Name="Discord"; Id="Discord.Discord"; NormalId="Discord.Discord"; HasDual="1"; Slug="discord"; Domain="discord.com"; Desc="Sesli, yazılı ve görüntülü sohbet platformu"; Cat="Browsers"},
    @{Name="WhatsApp"; Id="WhatsApp.WhatsApp"; StoreId="9NKSQGP7F2NH"; NormalId="WhatsApp.WhatsApp"; HasDual="1"; Slug="whatsapp"; Domain="whatsapp.com"; Desc="Resmi masaüstü mesajlaşma uygulaması"; Cat="Browsers"; RegistryName="WhatsApp"},
    @{Name="Zoom Meetings"; Id="Zoom.Zoom"; StoreId="XP99J3KP4XZ4VV"; NormalId="Zoom.Zoom"; HasDual="1"; Slug="zoom"; Domain="zoom.us"; Desc="Çevrim içi görüntülü toplantı aracı"; Cat="Browsers"},
    @{Name="Microsoft Teams"; Id="Microsoft.Teams"; StoreId="XP8BT8DW290MPQ"; NormalId="Microsoft.Teams"; HasDual="1"; Slug="microsoftteams"; Domain="teams.microsoft.com"; Desc="İş ve eğitim odaklı iletişim"; Cat="Browsers"},
    @{Name="Thunderbird"; Id="Mozilla.Thunderbird"; StoreId="9MX7TGVGQFCL"; NormalId="Mozilla.Thunderbird"; HasDual="1"; Slug="thunderbird"; Domain="thunderbird.net"; Desc="Açık kaynak gelişmiş e-posta istemcisi"; Cat="Browsers"},

    # Oyun & Medya
    @{Name="Steam"; Id="Valve.Steam"; Slug="steam"; Domain="steampowered.com"; Desc="En popüler dijital oyun platformu"; Cat="Games"},
    @{Name="Epic Games"; Id="EpicGames.EpicGamesLauncher"; StoreId="XP99VR1BPSBQJ2"; NormalId="EpicGames.EpicGamesLauncher"; HasDual="1"; Slug="epicgames"; Domain="epicgames.com"; IconUrl="https://thumb.wikimedia.org/wikipedia/commons/thumb/3/31/Epic_Games_logo.svg/1920px-Epic_Games_logo.svg.png?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=thumbnail"; DirectUrl="https://thumb.wikimedia.org/wikipedia/commons/thumb/3/31/Epic_Games_logo.svg/1920px-Epic_Games_logo.svg.png?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=thumbnail"; Desc="Ücretsiz oyunlar ve Unreal ekosistemi"; Cat="Games"},
    @{Name="Battle.net"; Id="Blizzard.BattleNet"; Slug="battle.net"; Domain="blizzard.com"; InstallLocation="C:\Program Files (x86)\Battle.net"; IconUrl="https://www.google.com/s2/favicons?domain=battle.net&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=battle.net&sz=128"; Desc="Call of Duty, Diablo ve WoW istemcisi"; Cat="Games"},
    @{Name="EA App"; Id="ElectronicArts.EADesktop"; Slug="ea"; Domain="ea.com"; IconUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/electronic-arts.png"; DirectUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/electronic-arts.png"; Desc="EA oyunları ve EA Play istemcisi"; Cat="Games"},
    @{Name="Ubisoft Connect"; Id="Ubisoft.Connect"; Slug="ubisoft"; Domain="ubisoft.com"; IconUrl="https://cdn2.steamgriddb.com/icon/064e3a5648fb4a7f911155bd81f87fd2.ico"; DirectUrl="https://cdn2.steamgriddb.com/icon/064e3a5648fb4a7f911155bd81f87fd2.ico"; Desc="Ubisoft yapımları için resmi istemci"; Cat="Games"},
    @{Name="Rockstar Games Launcher"; Id="RockstarGames.Launcher"; Slug="rockstargames"; Domain="rockstargames.com"; IconUrl="https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Rockstar_Games_Logo.svg/500px-Rockstar_Games_Logo.svg.png"; DirectUrl="https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Rockstar_Games_Logo.svg/500px-Rockstar_Games_Logo.svg.png"; Desc="GTA ve Red Dead Redemption resmi oyun istemcisi"; Cat="Games"},
    @{Name="Riot Games Client"; Id="RiotGames.LeagueOfLegends.TR"; Slug="riotgames"; Domain="riotgames.com"; Desc="League of Legends, Valorant ve TFT resmi oyun istemcisi"; Cat="Games"},
    @{Name="Blitz"; Id="Blitz.Blitz"; Slug="blitz"; Domain="blitz.gg"; Desc="LoL, Valorant ve TFT için otomatik rün, eşya ve rehber asistanı"; Cat="Games"},
    @{Name="XBOX"; Id="9MV0B5HZVK9Z"; StoreId="9MV0B5HZVK9Z"; DownloadUrl="https://aka.ms/XboxInstaller.exe"; HasDual="1"; Slug="xbox"; Domain="xbox.com"; IconUrl="https://www.google.com/s2/favicons?domain=xbox.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=xbox.com&sz=128"; Desc="Resmi Microsoft XBOX ve PC Game Pass uygulaması. Yüzlerce konsol ve PC oyununu keşfet, indir ve oyna. Bulut oyun (Cloud Gaming), EA Play ve Xbox Live arkadaş ağı desteği içerir."; Cat="Games"; RegistryName="Microsoft.GamingApp"},
        # --- DİJİTAL YAYIN & EĞLENCE (STREAMING) & OFİS (STORE ÖZEL) ---
    @{Name="Netflix"; Id="9WZDNCRFJ3TJ"; StoreId="9WZDNCRFJ3TJ"; StoreOnly="1"; Slug="netflix"; Domain="netflix.com"; IconUrl="https://assets.nflxext.com/ffe/siteui/common/icons/nficon2016.ico"; Desc="Dünyanın lider film, dizi ve belgesel yayın platformu"; Cat="Games"},
    @{Name="Amazon Prime Video"; Id="9P6RC76MSMMJ"; StoreId="9P6RC76MSMMJ"; StoreOnly="1"; Slug="primevideo"; Domain="primevideo.com"; IconUrl="https://m.media-amazon.com/images/G/01/digital/video/web/Logo-min.png"; Desc="Ödüllü Amazon Originals yapımları ve popüler filmler"; Cat="Games"},
    @{Name="Disney+"; Id="9NXQXXLFST89"; StoreId="9NXQXXLFST89"; StoreOnly="1"; Slug="disneyplus"; Domain="disneyplus.com"; IconUrl="https://www.google.com/s2/favicons?domain=disneyplus.com&sz=128"; Desc="Disney, Pixar, Marvel, Star Wars ve National Geographic yapımları"; Cat="Games"},
    @{Name="Apple TV"; Id="9NM4T8B9JQZ1"; StoreId="9NM4T8B9JQZ1"; StoreOnly="1"; Slug="appletv"; Domain="apple.com"; IconUrl="https://www.google.com/s2/favicons?domain=tv.apple.com&sz=128"; Desc="Apple Original yapımları, film kiralama ve 4K HDR yayınlar"; Cat="Games"},
    @{Name="Microsoft 365"; Id="9WZDNCRD29V9"; StoreId="9WZDNCRD29V9"; NormalId="Microsoft.Office"; HasDual="1"; Slug="microsoft365"; Domain="office.com"; IconUrl="https://www.google.com/s2/favicons?domain=office.com&sz=128"; Desc="Word, Excel, PowerPoint, Outlook ve Copilot üretkenlik paketi"; Cat="Tools"},
    @{Name="Spotify"; Id="Spotify.Spotify"; StoreId="9NCBCSZSJRSB"; NormalId="Spotify.Spotify"; HasDual="1"; Slug="spotify"; Domain="spotify.com"; Desc="Popüler çevrim içi müzik servisi"; Cat="Games"},
    @{Name="VLC Media Player"; Id="VideoLAN.VLC"; StoreId="9NBLGGH4VVNH"; NormalId="VideoLAN.VLC"; HasDual="1"; Slug="vlcmediaplayer"; Domain="videolan.org"; IconUrl="https://raw.githubusercontent.com/memstechtips/package-icons/main/icons/external/videolan.vlc.png"; DirectUrl="https://raw.githubusercontent.com/memstechtips/package-icons/main/icons/external/videolan.vlc.png"; Desc="Tüm video ve ses formatlarını açar"; Cat="Games"},
    @{Name="GOM Player"; Id="GOMLab.GOMPlayer"; StoreId="XP8LKPZT4X0Z0P"; NormalId="GOMLab.GOMPlayer"; HasDual="1"; Slug="gom"; Domain="gomlab.com"; IconUrl="https://images.icon-icons.com/195/PNG/256/GOM_Player_23385.png"; DirectUrl="https://images.icon-icons.com/195/PNG/256/GOM_Player_23385.png"; Desc="Gelişmiş dahili codec destekli video oynatıcı"; Cat="Games"},
    @{Name="OBS Studio"; Id="OBSProject.OBSStudio"; StoreId="XPFFH613W8V6LV"; NormalId="OBSProject.OBSStudio"; HasDual="1"; Slug="obsstudio"; Domain="obsproject.com"; IconUrl="https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d3/OBS_Studio_Logo.svg/3840px-OBS_Studio_Logo.svg.png"; Desc="Canlı yayın ve ekran kaydetme yazılımı"; Cat="Games"},
    @{Name="K-Lite Codec Pack"; Id="CodecGuide.K-LiteCodecPack.Mega"; Slug="k-lite-codec-pack"; Domain="codecguide.com"; Desc="Geniş video ve ses codec kütüphanesi"; Cat="Games"},

    # Geliştirici & AI
    @{Name="Visual Studio Code"; Id="Microsoft.VisualStudioCode"; StoreId="XP9KHM4BK9FZ7Q"; NormalId="Microsoft.VisualStudioCode"; HasDual="1"; Slug="visualstudiocode"; Domain="code.visualstudio.com"; Desc="Hafif ve güçlü açık kaynak kod editörü"; Cat="Dev"},
    @{Name="Cursor AI Editor"; Id="Anysphere.Cursor"; Slug="cursor"; Domain="cursor.com"; IconUrl="https://www.google.com/s2/favicons?domain=cursor.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=cursor.com&sz=128"; Desc="Yapay zeka destekli yeni nesil kod editörü"; Cat="Dev"},
    @{Name="Windsurf Editor"; Id="Codeium.Windsurf"; Slug="codeium"; Domain="codeium.com"; IconUrl="https://www.google.com/s2/favicons?domain=codeium.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=codeium.com&sz=128"; Desc="Codeium destekli yapay zeka kod editörü"; Cat="Dev"},
    @{Name="Visual Studio Community"; Id="Microsoft.VisualStudio.2022.Community"; StoreId="XPDCFJDKLZJLP8"; NormalId="Microsoft.VisualStudio.2022.Community"; HasDual="1"; Slug="visualstudio"; Domain="visualstudio.microsoft.com"; IconUrl="https://thumb.wikimedia.org/wikipedia/commons/thumb/2/20/Visual_Studio_Icon_2026.svg/330px-Visual_Studio_Icon_2026.svg.png"; DirectUrl="https://thumb.wikimedia.org/wikipedia/commons/thumb/2/20/Visual_Studio_Icon_2026.svg/330px-Visual_Studio_Icon_2026.svg.png"; Desc="C#, C++ ve .NET geliştirme IDE'si"; Cat="Dev"},
    @{Name="Git SCM"; Id="Git.Git"; NormalId="Git.Git"; HasDual="1"; Slug="git"; Domain="git-scm.com"; Desc="Sürüm kontrol sistemi"; Cat="Dev"},
    @{Name="Python 3.13"; Id="Python.Python.3.13"; StoreId="9PNRBTZXMB4Z"; NormalId="Python.Python.3.13"; HasDual="1"; Slug="python"; Domain="python.org"; Desc="Resmi Python modern çalışma ortamı"; Cat="Dev"},
    @{Name="Java JDK 21"; Id="Oracle.JDK.21"; Slug="openjdk"; Domain="oracle.com"; Desc="Oracle resmi Java geliştirme kiti (JDK)"; Cat="Dev"},
    @{Name="C# / .NET SDK"; Id="Microsoft.DotNet.SDK.8"; Slug="dotnet"; Domain="microsoft.com"; Desc="C# derleyicisi ve .NET SDK paketi"; Cat="Dev"},
    @{Name="C++ Build Tools"; Id="Microsoft.VisualStudio.2022.BuildTools"; Slug="visualstudio"; Domain="visualstudio.microsoft.com"; Desc="MSVC C/C++ derleyicisi ve derleme araçları"; Cat="Dev"},
    @{Name="Claude Code CLI"; Id="Anthropic.ClaudeCode"; Slug="anthropic"; Domain="anthropic.com"; Desc="Anthropic terminal destekli resmi Claude AI aracı"; Cat="Dev"},
    @{Name="Google Antigravity"; Id="Google.Antigravity"; Slug="google-antigravity"; Domain="deepmind.google"; IconUrl="https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Google_2015_logo.svg/500px-Google_2015_logo.svg.png"; DirectUrl="https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Google_2015_logo.svg/500px-Google_2015_logo.svg.png"; Desc="Google DeepMind yapay zeka kodlama platformu"; Cat="Dev"},
    @{Name="OpenAI Codex CLI"; Id="OpenAI.Codex"; Slug="openaicodex"; Domain="openai.com"; IconUrl="https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/OpenAI_Logo.svg/500px-OpenAI_Logo.svg.png"; DirectUrl="https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/OpenAI_Logo.svg/500px-OpenAI_Logo.svg.png"; Desc="Terminal tabanlı akıllı yapay zeka kodlama ajanı"; Cat="Dev"},

    # Donanım & Sürücüler
    @{Name="Driver Booster"; Id="IObit.DriverBooster"; StoreId="XPFG20V78LRMWG"; NormalId="IObit.DriverBooster"; HasDual="1"; Slug="driver-booster"; Domain="iobit.com"; IconUrl="https://images-eds-ssl.xboxlive.com/image?url=4rt9.lXDC4H_93laV1_eHHFT949fUipzkiFOBH3fAiZZUCdYojwUyX2aTonS1aIwMrx6NUIsHfUHSLzjGJFxxpGJcfKie74mSv3eZVU_NXe1yLh72krpQ3bgUFpescVbkFmSrw1URfdvwp8rcV02mErJazXRkdrCiXXaM36M..s-&format=source"; DirectUrl="https://images-eds-ssl.xboxlive.com/image?url=4rt9.lXDC4H_93laV1_eHHFT949fUipzkiFOBH3fAiZZUCdYojwUyX2aTonS1aIwMrx6NUIsHfUHSLzjGJFxxpGJcfKie74mSv3eZVU_NXe1yLh72krpQ3bgUFpescVbkFmSrw1URfdvwp8rcV02mErJazXRkdrCiXXaM36M..s-&format=source"; Desc="IObit resmi sürücü güncelleme aracı"; Cat="Hardware"},
    @{Name="Display Driver Uninstaller (DDU)"; Id="Wagnardsoft.DisplayDriverUninstaller"; Slug="ddu"; Domain="wagnardsoft.com"; IconUrl="https://www.wagnardsoft.com/sites/default/files/field/image/ddu_logo3_17og.jpg"; DirectUrl="https://www.wagnardsoft.com/sites/default/files/field/image/ddu_logo3_17og.jpg"; Desc="Ekran kartı ve ses sürücüsü kalıntılarını temizleme aracı"; Cat="Hardware"},
    @{Name="CPU-Z"; Id="CPUID.CPU-Z"; Slug="cpuz"; Domain="cpuid.com"; Desc="İşlemci, bellek ve anakart analiz aracı"; Cat="Hardware"},
    @{Name="Core Temp"; Id="ALCPU.CoreTemp"; Slug="coretemp"; Domain="alcpu.com"; IconUrl="https://www.google.com/s2/favicons?domain=alcpu.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=alcpu.com&sz=128"; Desc="İşlemci sıcaklıklarını anlık takip aracı"; Cat="Hardware"},
    @{Name="CrystalDiskInfo"; Id="CrystalDewWorld.CrystalDiskInfo"; StoreId="XP8K4RGX25G3GM"; NormalId="CrystalDewWorld.CrystalDiskInfo"; HasDual="1"; Slug="crystaldiskinfo"; Domain="crystalmark.info"; IconUrl="https://avatars.githubusercontent.com/u/284836015?s=280&v=4"; DirectUrl="https://avatars.githubusercontent.com/u/284836015?s=280&v=4"; Desc="SSD ve HDD sağlık / sıcaklık takip programı"; Cat="Hardware"},
    @{Name="CrystalDiskMark"; Id="CrystalDewWorld.CrystalDiskMark"; NormalId="CrystalDewWorld.CrystalDiskMark"; HasDual="1"; Slug="crystaldiskmark"; Domain="crystalmark.info"; IconUrl="https://store-images.s-microsoft.com/image/apps.28465.13510798887699839.f53826c5-f1b2-4116-8752-c2b96364d5da.d2205bd9-cb87-4564-bdfd-4f11bc99bd35?h=210"; DirectUrl="https://store-images.s-microsoft.com/image/apps.28465.13510798887699839.f53826c5-f1b2-4116-8752-c2b96364d5da.d2205bd9-cb87-4564-bdfd-4f11bc99bd35?h=210"; Desc="SSD ve HDD hız testi (Benchmark) aracı"; Cat="Hardware"},
    @{Name="MSI Afterburner + RTSS"; Id="Guru3D.Afterburner"; Slug="msi"; Domain="msi.com"; IconUrl="https://tr.msi.com/images/front/apps/afterburner-icon.png"; Desc="GPU hız aşırtma, sıcaklık izleme ve FPS göstergesi"; Cat="Hardware"; ExePath="C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"},
    @{Name="NVIDIA App"; Id="Nvidia.App"; StoreId="XP8CLZL93F5Z4P"; NormalId="Nvidia.App"; HasDual="1"; Slug="nvidia"; Domain="nvidia.com"; Desc="GeForce sürücü ve optimizasyon merkezi"; Cat="Hardware"},
    @{Name="NVIDIA Control Panel"; Id="9NF8H0H7WMLT"; StoreId="9NF8H0H7WMLT"; NormalId="Nvidia.App"; HasDual="1"; Slug="nvidia"; Domain="nvidia.com"; Desc="NVIDIA grafik denetim masası"; Cat="Hardware"; RegistryName="NVIDIA Denetim Masası"; ExePath="C:\Program Files\NVIDIA Corporation\Control Panel Client\nvcplui.exe"},
    @{Name="AMD Radeon Software"; Id="AMD.RadeonSoftware"; Slug="amd"; Domain="amd.com"; IconUrl="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/amd.png"; Desc="AMD grafik kartı sürücü ve Radeon yazılımı"; Cat="Hardware"},
    @{Name="AMD Ryzen Chipset"; Id="AMD.ChipsetDriver"; Slug="amd"; Domain="amd.com"; IconUrl="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/amd.png"; Desc="Ryzen işlemciler için resmi çipset sürücüsü"; Cat="Hardware"},
    @{Name="Realtek Audio Control"; Id="Realtek.AudioControl"; NormalId="Realtek.AudioControl"; HasDual="1"; Slug="realtek"; Domain="realtek.com"; IconUrl="https://companieslogo.com/img/orig/2379.TW-3cbb6e43.png?t=1720244490"; DirectUrl="https://companieslogo.com/img/orig/2379.TW-3cbb6e43.png?t=1720244490"; Desc="Realtek dahili ses yöneticisi ve sürücü kontrolü"; Cat="Hardware"},
    @{Name="Intel Driver Support"; Id="Intel.DriverAndSupportAssistant"; Slug="intel"; Domain="intel.com"; IconUrl="https://img.utdstc.com/icon/43a/8e4/43a8e4b10837ae2f55595d88272bad6550d6da77329ccbecbb6f65457168aa4a:600"; DirectUrl="https://img.utdstc.com/icon/43a/8e4/43a8e4b10837ae2f55595d88272bad6550d6da77329ccbecbb6f65457168aa4a:600"; Desc="Intel sürücü ve sistem destek asistanı"; Cat="Hardware"},
    @{Name="Intel Graphics Software"; Id="9PLFNLNT3G5G"; StoreId="9PLFNLNT3G5G"; NormalId="Intel.DriverAndSupportAssistant"; HasDual="1"; Slug="intelgraphics"; Domain="intel.com"; Desc="Intel entegre ve Arc grafik kartı sürücü ve ayar yöneticisi"; Cat="Hardware"; RegistryName="Intel® Graphics Software"; ServiceName="IntelGraphicsSoftwareService"},
    @{Name="HP Support Assistant"; Id="HP.SupportAssistant"; NormalId="HP.SupportAssistant"; HasDual="1"; Slug="hp"; Domain="hp.com"; Desc="HP bilgisayar destek ve bakım yazılımı"; Cat="Hardware"},
    @{Name="Logitech G HUB"; Id="Logitech.GHUB"; Slug="logitech"; Domain="logitechg.com"; Desc="Logitech donanımları yönetim yazılımı"; Cat="Hardware"},
    @{Name="Razer Synapse"; Id="Razer.Synapse3"; NormalId="Razer.Synapse3"; HasDual="1"; Slug="razer"; Domain="razer.com"; IconUrl="https://www.google.com/s2/favicons?domain=razer.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=razer.com&sz=128"; Desc="Razer oyuncu ekipmanları yapılandırma aracı"; Cat="Hardware"},
    @{Name="Corsair iCUE"; Id="Corsair.iCUE.4"; Slug="corsair"; Domain="corsair.com"; IconUrl="$($global:corsairIconB64)"; DirectUrl="$($global:corsairIconB64)"; Desc="Corsair RGB ve donanım kontrolcüsü"; Cat="Hardware"},
    @{Name="SteelSeries GG"; Id="SteelSeries.GG"; Slug="steelseries"; Domain="steelseries.com"; IconUrl="https://www.nicepng.com/png/full/209-2090115_chicago-march-28-steelseries-logo-white.png"; DirectUrl="https://www.nicepng.com/png/full/209-2090115_chicago-march-28-steelseries-logo-white.png"; Desc="SteelSeries Sonar ve çevre birim yazılımı"; Cat="Hardware"},

    # Güvenlik & Antivirüs
    @{Name="Bitwarden"; Id="Bitwarden.Bitwarden"; StoreId="9PJSDV0VPK04"; NormalId="Bitwarden.Bitwarden"; HasDual="1"; Slug="bitwarden"; Domain="bitwarden.com"; Desc="Açık kaynaklı şifreli parola yöneticisi"; Cat="Security"},
    @{Name="Kaspersky"; Id="Kaspersky.Kaspersky"; Slug="kaspersky"; Domain="kaspersky.com"; IconUrl="https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4e/Kaspersky_icon.svg/330px-Kaspersky_icon.svg.png"; Desc="Gelişmiş antivirüs koruma paketi"; Cat="Security"},
    @{Name="Bitdefender"; Id="Bitdefender.Bitdefender"; StoreId="XP9K931FWBP5V5"; NormalId="Bitdefender.Bitdefender"; HasDual="1"; Slug="bitdefender"; Domain="bitdefender.com"; IconUrl="https://www.google.com/s2/favicons?domain=bitdefender.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=bitdefender.com&sz=128"; Desc="Bitdefender Total Security kalkanı"; Cat="Security"},
    @{Name="ESET NOD32"; Id="ESET.NOD32"; StoreId="XP9KF40VGV9PWM"; NormalId="ESET.NOD32"; HasDual="1"; Slug="eset"; Domain="eset.com"; IconUrl="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/eset.png"; Desc="ESET NOD32 Antivirus sistemi"; Cat="Security"},
    @{Name="McAfee"; Id="McAfee.TotalProtection"; Slug="mcafee"; Domain="mcafee.com"; IconUrl="https://www.google.com/s2/favicons?domain=mcafee.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=mcafee.com&sz=128"; Desc="McAfee Total Protection kalkanı"; Cat="Security"},
    @{Name="Malwarebytes"; Id="Malwarebytes.Malwarebytes"; NormalId="Malwarebytes.Malwarebytes"; HasDual="1"; Slug="malwarebytes"; Domain="malwarebytes.com"; IconUrl="https://raw.githubusercontent.com/memstechtips/package-icons/main/icons/external/malwarebytes.malwarebytes.png"; DirectUrl="https://raw.githubusercontent.com/memstechtips/package-icons/main/icons/external/malwarebytes.malwarebytes.png"; Desc="Zararlı yazılım ve virüs temizleyici"; Cat="Security"},
    @{Name="Avast Free Antivirus"; Id="AVAST.Avast"; StoreId="XPDNZJFNCR1B07"; NormalId="AVAST.Avast"; HasDual="1"; Slug="avast"; Domain="avast.com"; IconUrl="https://w1.pngwing.com/pngs/824/116/png-transparent-internet-logo-avast-antivirus-antivirus-software-computer-software-computer-security-iobit-uninstaller-computer-program-computer-security-software.png"; DirectUrl="https://w1.pngwing.com/pngs/824/116/png-transparent-internet-logo-avast-antivirus-antivirus-software-computer-software-computer-security-iobit-uninstaller-computer-program-computer-security-software.png"; Desc="Temel antivirüs koruması"; Cat="Security"},

    # Sistem, USB, Araçlar & Belgeler
    @{Name="Ventoy"; Id="Ventoy.Ventoy"; Slug="ventoy"; Domain="ventoy.net"; Desc="Çoklu ISO önyüklemeli format USB aracı"; Cat="Tools"},
    @{Name="Rufus"; Id="Rufus.Rufus"; StoreId="9PC3H3V7Q9CH"; NormalId="Rufus.Rufus"; HasDual="1"; Slug="rufus"; Domain="rufus.ie"; Desc="Önyüklenebilir format USB hazırlama programı"; Cat="Tools"},
    @{Name="Microsoft PC Manager"; Id="9PM860492SZD"; StoreId="9PM860492SZD"; DownloadUrl="https://aka.ms/PCManagerOOBE"; HasDual="1"; Slug="pcmanager"; Domain="microsoft.com"; IconUrl="https://store-images.s-microsoft.com/image/apps.8039.14298090620665013.d1d2f3d6-b14f-46af-9d3d-ab1fb90b7003.f91cf4db-2647-4592-a9a6-c6b98e46e15e"; DirectUrl="https://store-images.s-microsoft.com/image/apps.8039.14298090620665013.d1d2f3d6-b14f-46af-9d3d-ab1fb90b7003.f91cf4db-2647-4592-a9a6-c6b98e46e15e"; Desc="Resmi Windows sistem optimizasyon aracı"; Cat="Tools"; RegistryName="Microsoft PC Manager"},
    @{Name="Microsoft PowerToys"; Id="Microsoft.PowerToys"; StoreId="9MZ95KL8MR0L"; NormalId="Microsoft.PowerToys"; HasDual="1"; Slug="microsoft"; Domain="microsoft.com"; IconUrl="https://rewtech.se/wp-content/uploads/2023/11/MicrosoftPowerToyslogo.png"; Desc="Windows gelişmiş üretkenlik araç seti"; Cat="Tools"},
    @{Name="Lightshot"; Id="Skillbrains.Lightshot"; Slug="lightshot"; Domain="app.prntscr.com"; Desc="Hızlı ekran görüntüsü alma aracı"; Cat="Tools"},
    @{Name="Flameshot"; Id="Flameshot.Flameshot"; Slug="flameshot"; Domain="flameshot.org"; IconUrl="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/flameshot.png"; Desc="Gelişmiş ekran yakalama aracı"; Cat="Tools"},
    @{Name="ShareX"; Id="ShareX.ShareX"; StoreId="9NBLGGH4Z1SP"; NormalId="ShareX.ShareX"; HasDual="1"; Slug="sharex"; Domain="getsharex.com"; IconUrl="https://www.google.com/s2/favicons?domain=getsharex.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=getsharex.com&sz=128"; Desc="Ekran yakalama ve paylaşım aracı"; Cat="Tools"},
    @{Name="Everything"; Id="voidtools.Everything"; Slug="voidtools"; Domain="voidtools.com"; Desc="Bilgisayarda anında dosya arama motoru"; Cat="Tools"},
    @{Name="TreeSize Free"; Id="JAMSoftware.TreeSize.Free"; StoreId="XP9M26RSCLNT88"; NormalId="JAMSoftware.TreeSize.Free"; HasDual="1"; Slug="treesize"; Domain="jam-software.com"; Desc="Diskte büyük dosyaları bulur"; Cat="Tools"},
    @{Name="CapCut"; Id="ByteDance.CapCut"; StoreId="XP9KN75RRB9NHS"; NormalId="ByteDance.CapCut"; HasDual="1"; Slug="capcut"; Domain="capcut.com"; Desc="Video düzenleme ve kurgu uygulaması"; Cat="Tools"},
    @{Name="Adobe Creative Cloud"; Id="Adobe.CreativeCloud"; StoreId="XPDLPKWG9SW2WD"; NormalId="Adobe.CreativeCloud"; HasDual="1"; Slug="adobecreativecloud"; Domain="adobe.com"; IconUrl="https://images-eds-ssl.xboxlive.com/image?url=4rt9.lXDC4H_93laV1_eHM0OYfiFeMI2p9MWie0CvL99U4GA1gf6_kayTt_kBblFwHwo8BW8JXlqfnYxKPmmBTIRfn4ye72ghGVGS6nE9FscSZc4L3RuzKSX9QFxvR1OjHpLEyDYlJsRqNwAjNhHAvB4KT78T0S0eCzFKazKzyI-&format=source"; DirectUrl="https://images-eds-ssl.xboxlive.com/image?url=4rt9.lXDC4H_93laV1_eHM0OYfiFeMI2p9MWie0CvL99U4GA1gf6_kayTt_kBblFwHwo8BW8JXlqfnYxKPmmBTIRfn4ye72ghGVGS6nE9FscSZc4L3RuzKSX9QFxvR1OjHpLEyDYlJsRqNwAjNhHAvB4KT78T0S0eCzFKazKzyI-&format=source"; Desc="Adobe uygulama yönetim merkezi"; Cat="Tools"},
    @{Name="Adobe Acrobat Reader"; Id="Adobe.Acrobat.Reader.64-bit"; StoreId="XPDP273C0XHQH2"; NormalId="Adobe.Acrobat.Reader.64-bit"; HasDual="1"; Slug="adobereader"; Domain="adobe.com"; IconUrl="https://img.utdstc.com/icon/048/0de/0480de0d0f5df4170e0ea3518934216c693a4b43c66732a2304f924d7ef7bd1c:600"; DirectUrl="https://img.utdstc.com/icon/048/0de/0480de0d0f5df4170e0ea3518934216c693a4b43c66732a2304f924d7ef7bd1c:600"; Desc="Resmi Adobe PDF okuyucu"; Cat="Tools"},
    @{Name="Blender 3D"; Id="BlenderFoundation.Blender"; StoreId="9PP3C07GTVRH"; NormalId="BlenderFoundation.Blender"; HasDual="1"; Slug="blender"; Domain="blender.org"; Desc="Profesyonel 3D modelleme aracı"; Cat="Tools"},
    @{Name="GIMP"; Id="GIMP.GIMP"; StoreId="9PNSJCLXDZ0V"; NormalId="GIMP.GIMP"; HasDual="1"; Slug="gimp"; Domain="gimp.org"; Desc="Açık kaynaklı fotoğraf düzenleme yazılımı"; Cat="Tools"},
    @{Name="HandBrake"; Id="HandBrake.HandBrake"; NormalId="HandBrake.HandBrake"; HasDual="1"; Slug="handbrake"; Domain="handbrake.fr"; Desc="Video dönüştürme ve optimize etme aracı"; Cat="Tools"},
    @{Name="7-Zip"; Id="7zip.7zip"; Slug="7zip"; Domain="7-zip.org"; Desc="Yüksek sıkıştırma oranlı arşivleyici"; Cat="Tools"},
    @{Name="WinRAR"; Id="RARLab.WinRAR"; Slug="rarlab"; Domain="rarlab.com"; IconUrl="https://www.google.com/s2/favicons?domain=win-rar.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=win-rar.com&sz=128"; Desc="Klasik RAR ve ZIP arşiv yöneticisi"; Cat="Tools"},
    @{Name="PeaZip"; Id="Giorgiotani.Peazip"; NormalId="Giorgiotani.Peazip"; HasDual="1"; Slug="peazip"; Domain="peazip.github.io"; IconUrl="https://www.google.com/s2/favicons?domain=peazip.github.io&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=peazip.github.io&sz=128"; Desc="Modern açık kaynak arşiv yöneticisi"; Cat="Tools"},
    @{Name="JDownloader 2"; Id="AppWork.JDownloader"; Slug="jdownloader"; Domain="jdownloader.org"; Desc="Otomatik indirme yöneticisi"; Cat="Tools"},
    @{Name="uTorrent"; Id="BitTorrent.uTorrent"; Slug="utorrent"; Domain="utorrent.com"; IconUrl="https://upload.wikimedia.org/wikipedia/commons/9/9f/UTorrent_%28logo%29.png"; Desc="Klasik torrent istemcisi"; Cat="Tools"},
        @{Name="Chrome Remote Desktop"; Id="Google.ChromeRemoteDesktopHost"; Slug="chromeremotedesktop"; Domain="google.com"; Desc="Google Chrome uzaktan masaüstü ve bilgisayar kontrol aracı"; Cat="Tools"},
    @{Name="Cloudflare WARP"; Id="Cloudflare.Warp"; Slug="cloudflare"; Domain="cloudflare.com"; Desc="Daha hızlı ve gizli internet için resmi Cloudflare DNS ve WARP VPN tüneli"; Cat="Tools"},
    @{Name="SplitWire Turkey"; Id="cagritaskn.SplitWireTurkey"; Slug="splitwire"; Domain="github.com"; DownloadUrl="https://github.com/cagritaskn/SplitWire-Turkey/releases/latest/download/SplitWire-Turkey-Setup-Windows-1.5.5.exe"; Desc="Discord ve internet kısıtlamaları için WireSock & DPI bypass aracı"; Cat="Tools"},
@{Name="AnyDesk"; Id="AnyDeskSoftwareGmbH.AnyDesk"; NormalId="AnyDeskSoftwareGmbH.AnyDesk"; HasDual="1"; Slug="anydesk"; Domain="anydesk.com"; Desc="Hızlı uzak masaüstü bağlantısı"; Cat="Tools"},
    @{Name="TeamViewer"; Id="TeamViewer.TeamViewer"; StoreId="XPDM17HK323C4X"; NormalId="TeamViewer.TeamViewer"; HasDual="1"; Slug="teamviewer"; Domain="teamviewer.com"; IconUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/team-viewer.png"; DirectUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/team-viewer.png"; Desc="Uzak destek ve yönetim istemcisi"; Cat="Tools"},
    @{Name="TeamViewer QuickSupport"; Id="TeamViewer.TeamViewer.QuickSupport"; Slug="teamviewer"; Domain="teamviewer.com"; IconUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/team-viewer.png"; DirectUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/team-viewer.png"; Desc="Hızlı uzaktan yardım istemcisi"; Cat="Tools"},
    @{Name="TeamViewer Host"; Id="TeamViewer.TeamViewer.Host"; Slug="teamviewer"; Domain="teamviewer.com"; IconUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/team-viewer.png"; DirectUrl="https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/team-viewer.png"; Desc="Sürekli uzaktan erişim servisi"; Cat="Tools"},
    @{Name="LocalSend"; Id="LocalSend.LocalSend"; NormalId="LocalSend.LocalSend"; HasDual="1"; Slug="localsend"; Domain="localsend.org"; IconUrl="https://www.google.com/s2/favicons?domain=localsend.org&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=localsend.org&sz=128"; Desc="Yerel ağ üzerinden güvenli dosya paylaşımı"; Cat="Tools"},
    @{Name="Revo Uninstaller"; Id="RevoUninstaller.RevoUninstaller"; StoreId="XPFFVD4CMXN8VN"; NormalId="RevoUninstaller.RevoUninstaller"; HasDual="1"; Slug="revo"; Domain="revouninstaller.com"; IconUrl="https://images-eds-ssl.xboxlive.com/image?url=4rt9.lXDC4H_93laV1_eHHFT949fUipzkiFOBH3fAiZZUCdYojwUyX2aTonS1aIwMrx6NUIsHfUHSLzjGJFxxsTUvdo4G.Xe2IuamE4B6xQ1hrBajab7aZV0MxWNLJYCnBmbUDdWZIkKHXEOAj_iPeToTRzFZcenPkNeZlstP6s-&format=source"; DirectUrl="https://images-eds-ssl.xboxlive.com/image?url=4rt9.lXDC4H_93laV1_eHHFT949fUipzkiFOBH3fAiZZUCdYojwUyX2aTonS1aIwMrx6NUIsHfUHSLzjGJFxxsTUvdo4G.Xe2IuamE4B6xQ1hrBajab7aZV0MxWNLJYCnBmbUDdWZIkKHXEOAj_iPeToTRzFZcenPkNeZlstP6s-&format=source"; Desc="Kalıntısız program kaldırıcı"; Cat="Tools"},
    @{Name="CCleaner"; Id="Piriform.CCleaner"; StoreId="XPFCWP0SQWXM3V"; NormalId="Piriform.CCleaner"; HasDual="1"; Slug="ccleaner"; Domain="ccleaner.com"; IconUrl="https://www.google.com/s2/favicons?domain=ccleaner.com&sz=128"; DirectUrl="https://www.google.com/s2/favicons?domain=ccleaner.com&sz=128"; Desc="Gereksiz temizleme aracı"; Cat="Tools"},

    # .NET Kütüphaneleri
        @{Name="Java Runtime Environment"; Id="Oracle.JavaRuntimeEnvironment"; Slug="java"; Domain="oracle.com"; Desc="Java uygulamaları ve oyunlar (Minecraft vb.) için resmi çalışma ortamı (JRE 8)"; Cat="Runtimes"},
@{Name=".NET Framework 3.5"; Id="Microsoft.DotNet.Framework.DeveloperPack_3"; Slug="dotnet"; Domain="microsoft.com"; Desc="Eski Windows programları için gerekli temel kütüphane"; Cat="Runtimes"},
    @{Name=".NET Framework 4.8.1"; Id="Microsoft.DotNet.Framework.DeveloperPack_4"; Slug="dotnet"; Domain="microsoft.com"; Desc="Standart Windows runtime kütüphanesi"; Cat="Runtimes"},
    @{Name=".NET Desktop Runtime 6.0 (x64)"; Id="Microsoft.DotNet.DesktopRuntime.6"; Slug="dotnet"; Domain="microsoft.com"; Desc=".NET 6 masaüstü uygulamaları için runtime"; Cat="Runtimes"},
    @{Name=".NET Desktop Runtime 7.0 (x64)"; Id="Microsoft.DotNet.DesktopRuntime.7"; Slug="dotnet"; Domain="microsoft.com"; Desc=".NET 7 masaüstü uygulamaları için runtime"; Cat="Runtimes"},
    @{Name=".NET Desktop Runtime 8.0 (x64)"; Id="Microsoft.DotNet.DesktopRuntime.8"; NormalId="Microsoft.DotNet.DesktopRuntime.8"; HasDual="1"; Slug="dotnet"; Domain="microsoft.com"; Desc=".NET 8 masaüstü çalışma ortamı"; Cat="Runtimes"},
    @{Name=".NET Desktop Runtime 9.0 (x64)"; Id="Microsoft.DotNet.DesktopRuntime.9"; Slug="dotnet"; Domain="microsoft.com"; Desc="En güncel .NET 9 masaüstü çalışma zamanı"; Cat="Runtimes"},
    @{Name="ASP.NET Core Runtime 8.0 (x64)"; Id="Microsoft.DotNet.AspNetCore.8"; Slug="dotnet"; Domain="microsoft.com"; Desc="Web tabanlı .NET 8 bileşenleri"; Cat="Runtimes"},
    @{Name="ASP.NET Core Runtime 9.0 (x64)"; Id="Microsoft.DotNet.AspNetCore.9"; Slug="dotnet"; Domain="microsoft.com"; Desc="Web tabanlı .NET 9 bileşenleri"; Cat="Runtimes"},

    # Visual C++ Kütüphaneleri
    @{Name="Visual C++ 2015-2022 (x64)"; Id="Microsoft.VCRedist.2015+.x64"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="Oyunlar için zorunlu DLL kütüphanesi (x64)"; Cat="Runtimes"},
    @{Name="Visual C++ 2015-2022 (x86)"; Id="Microsoft.VCRedist.2015+.x86"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="32-bit oyunlar için C++ DLL paketi (x86)"; Cat="Runtimes"},
    @{Name="Visual C++ 2013 (x64)"; Id="Microsoft.VCRedist.2013.x64"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="2013 dönemi kütüphanesi (x64)"; Cat="Runtimes"},
    @{Name="Visual C++ 2013 (x86)"; Id="Microsoft.VCRedist.2013.x86"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="32-bit 2013 kütüphanesi (x86)"; Cat="Runtimes"},
    @{Name="Visual C++ 2012 (x64)"; Id="Microsoft.VCRedist.2012.x64"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="2012 dönemi kütüphaneleri (x64)"; Cat="Runtimes"},
    @{Name="Visual C++ 2012 (x86)"; Id="Microsoft.VCRedist.2012.x86"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="32-bit 2012 kütüphaneleri (x86)"; Cat="Runtimes"},
    @{Name="Visual C++ 2010 (x64)"; Id="Microsoft.VCRedist.2010.x64"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="Eski yazılımlar için kütüphane (x64)"; Cat="Runtimes"},
    @{Name="Visual C++ 2010 (x86)"; Id="Microsoft.VCRedist.2010.x86"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="Eski yazılımlar için kütüphane (x86)"; Cat="Runtimes"},
    @{Name="Visual C++ 2008 (x64)"; Id="Microsoft.VCRedist.2008.x64"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="Eski sistem bileşenleri (x64)"; Cat="Runtimes"},
    @{Name="Visual C++ 2008 (x86)"; Id="Microsoft.VCRedist.2008.x86"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="Eski sistem bileşenleri (x86)"; Cat="Runtimes"},
    @{Name="Visual C++ 2005 (x64)"; Id="Microsoft.VCRedist.2005.x64"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="2005 dönemi klasik kütüphanesi (x64)"; Cat="Runtimes"},
    @{Name="Visual C++ 2005 (x86)"; Id="Microsoft.VCRedist.2005.x86"; Slug="visual_cpp"; Domain=""; DirectUrl=""; Desc="2005 dönemi klasik kütüphanesi (x86)"; Cat="Runtimes"}
)
$apps = $global:apps

# --- YÜKLÜ & GÜNCELLEME KONTROLÜ (GÜVENLİ VE HIZLI YÖNTEM) ---
$global:verifiedInstalledIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$global:verifiedInstalledNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$global:upgradableMap = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$global:installedMap = @{}
$global:storeInstalledProductIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$global:storeInstalledNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# Store uygulama ID helper
function Is-StoreAppId([string]$id) {
    return ($id -and ($id -match '^[A-Z0-9]{12}$' -or $id -match '^XP[A-Z0-9]{12}$'))
}

function Refresh-InstalledStatus {
    $global:verifiedInstalledIds.Clear()
    $global:verifiedInstalledNames.Clear()
    $global:upgradableMap.Clear()
    $global:installedMap.Clear()
    $global:storeInstalledProductIds.Clear()
    $global:storeInstalledNames.Clear()

    # Microsoft Store uygulamalarını AppxPackage ile tara (güvenli, hatasız)
    try {
        $storeApps = Get-AppxPackage -ErrorAction SilentlyContinue
        if ($storeApps) {
            foreach ($pkg in $storeApps) {
                if ($pkg.Name) {
                    [void]$global:storeInstalledNames.Add($pkg.Name)
                }
            }
        }
    } catch {}

    # Battle.net registry DisplayVersion düzeltmesi (Blizzard yazmadığı için winget sahte güncelleme çıkarıyordu)
    $bnetKey = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Battle.net"
    $bnetExe = "C:\Program Files (x86)\Battle.net\Battle.net.exe"
    if ((Test-Path $bnetKey) -and (Test-Path $bnetExe)) {
        $bnetVer = (Get-Item $bnetExe -ErrorAction SilentlyContinue).VersionInfo.FileVersion
        if ($bnetVer) {
            Set-ItemProperty -Path $bnetKey -Name "DisplayVersion" -Value $bnetVer -ErrorAction SilentlyContinue
        }
    }

    $regPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
        $global:uninstallStrings = @{}
    $global:quietUninstallStrings = @{}
    foreach ($path in $regPaths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.DisplayName) {
                $name = $_.DisplayName.Trim()
                $ver = if ($_.DisplayVersion) { $_.DisplayVersion.Trim() } else { "Yüklü" }
                $global:installedMap[$name] = $ver
                if ($_.QuietUninstallString) {
                    $global:quietUninstallStrings[$name] = $_.QuietUninstallString
                }
                if ($_.UninstallString) {
                    $global:uninstallStrings[$name] = $_.UninstallString
                }
            }
        }
    }

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $global:wingetExe
        $psi.Arguments = "list --accept-source-agreements"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8

        $p = [System.Diagnostics.Process]::Start($psi)
        $wOut = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit()

        $lines = $wOut -split "`r?`n"
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("---") -or $line.StartsWith("Name")) { continue }

            foreach ($app in $global:apps) {
                if ($app.Id -and $line -match "(?:\s|^)$([regex]::Escape($app.Id))(?:\s|$)") {
                    [void]$global:verifiedInstalledIds.Add($app.Id)
                }
                if ($app.Name -and $line -match [regex]::Escape($app.Name)) {
                    [void]$global:verifiedInstalledNames.Add($app.Name)
                }
            }
        }
    } catch {}

    try {
        $psiUp = New-Object System.Diagnostics.ProcessStartInfo
        $psiUp.FileName = $global:wingetExe
        $psiUp.Arguments = "upgrade --accept-source-agreements"
        $psiUp.UseShellExecute = $false
        $psiUp.CreateNoWindow = $true
        $psiUp.RedirectStandardOutput = $true
        $psiUp.StandardOutputEncoding = [System.Text.Encoding]::UTF8

        $pUp = [System.Diagnostics.Process]::Start($psiUp)
        $wUpOut = $pUp.StandardOutput.ReadToEnd()
        $pUp.WaitForExit()

        $upLines = $wUpOut -split "`r?`n"
        foreach ($line in $upLines) {
            if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("---") -or $line.StartsWith("Name")) { continue }
            foreach ($app in $global:apps) {
                # Sadece tam ID eşleşmesi (whitespace sınırları ile)
                if ($app.Id -and $line -match "(?:\s|^)$([regex]::Escape($app.Id))(?:\s|$)") {
                    if ($app.Id -eq "Blizzard.BattleNet" -and (Test-Path $bnetExe)) { continue }
                    [void]$global:upgradableMap.Add($app.Id)
                    [void]$global:verifiedInstalledIds.Add($app.Id)
                }
            }
        }
    } catch {}
}

function Get-AppUninstallCommand([string]$appName, [string]$id) {
    if ($global:quietUninstallStrings) {
        foreach ($k in $global:quietUninstallStrings.Keys) {
            if ($k -eq $appName -or $k.IndexOf($appName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                return @{ Cmd = $global:quietUninstallStrings[$k]; IsQuiet = $true }
            }
        }
    }
    if ($global:uninstallStrings) {
        foreach ($k in $global:uninstallStrings.Keys) {
            if ($k -eq $appName -or $k.IndexOf($appName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                return @{ Cmd = $global:uninstallStrings[$k]; IsQuiet = $false }
            }
        }
    }
    return $null
}

function Is-AppActuallyInstalled([string]$appName, [string]$id, [string]$exePath = "", [string]$registryName = "") {
    if ($id -and $global:verifiedInstalledIds.Contains($id)) { return $true }
    if ($appName -and $global:verifiedInstalledNames.Contains($appName)) { return $true }

    # 1. Intel Graphics Software (Servis, Appx ve Registry eşleşmeleri)
    if ($appName -like "*Intel*Graphic*" -or $id -eq "9PLFNLNT3G5G") {
        if ($global:storeInstalledNames.Contains("AppUp.IntelArcSoftware") -or
            $global:storeInstalledNames.Contains("AppUp.IntelGraphicsExperience") -or
            $global:storeInstalledNames.Contains("AppUp.IntelGraphicsControlPanel") -or
            (Get-Service -Name "IntelGraphicsSoftwareService" -ErrorAction SilentlyContinue)) {
            return $true
        }
    }

    # 2. XBOX (Microsoft.GamingApp ve XboxApp)
    if ($appName -match '^(?:XBOX|Xbox)$' -or $id -eq "9MV0B5HZVK9Z") {
        if ($global:storeInstalledNames.Contains("Microsoft.GamingApp") -or
            $global:storeInstalledNames.Contains("Microsoft.XboxApp") -or
            $global:storeInstalledNames.Contains("Microsoft.XboxGamingOverlay")) {
            return $true
        }
    }

    # 3. NVIDIA Control Panel (Store ve klasik nvcplui.exe)
    if ($appName -like "*NVIDIA Control Panel*" -or $id -eq "9NF8H0H7WMLT") {
        if ($global:storeInstalledNames.Contains("NVIDIACorp.NVIDIAControlPanel") -or
            (Test-Path "C:\Program Files\NVIDIA Corporation\Control Panel Client\nvcplui.exe")) {
            return $true
        }
    }

    # 4. Realtek Audio Control
    if ($appName -like "*Realtek Audio*" -or $id -like "*Realtek*") {
        if ($global:storeInstalledNames.Contains("RealtekSemiconductorCorp.RealtekAudioControl")) {
            return $true
        }
    }

    # 5. Microsoft PC Manager
    if ($appName -like "*PC Manager*" -or $id -eq "9PM860492SZD") {
        foreach ($pkg in $global:storeInstalledNames) {
            if ($pkg -like "*PCManager*" -or $pkg -like "*Microsoft.PCManager*") { return $true }
        }
    }

    # 6. WhatsApp (Store UWP veya klasik masaüstü)
    if ($appName -eq "WhatsApp" -or $id -eq "WhatsApp.WhatsApp" -or $id -eq "9NKSQGP7F2NH") {
        if ($global:storeInstalledNames.Contains("5319275A.WhatsAppDesktop") -or
            (Test-Path "$env:LOCALAPPDATA\WhatsApp\WhatsApp.exe")) {
            return $true
        }
    }

    # 7. Microsoft PowerToys
    if ($appName -like "*PowerToys*" -or $id -like "*PowerToys*" -or $id -eq "9MZ95KL8MR0L") {
        if ($global:storeInstalledNames.Contains("Microsoft.PowerToys.SparseApp") -or
            (Test-Path "$env:LOCALAPPDATA\PowerToys\PowerToys.exe") -or
            (Test-Path "C:\Program Files\PowerToys\PowerToys.exe")) {
            return $true
        }
    }

    # 6. ExePath doğrudan dosya yolu kontrolü
    if ($exePath -and $exePath -notmatch '\*') {
        if (Test-Path $exePath) { return $true }
    }
    if ($exePath -and $exePath -match '\*') {
        $found = Get-Item $exePath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $true }
    }

    $clean = $appName -replace '\s*\((?:x64|x86)\)', '' -replace '\s*Uygulaması', ''
    $normApp = ($appName -replace '[\s\-_+]', '').ToLower()
    foreach ($entry in $global:installedMap.Keys) {
        if ($entry -eq $appName -or $entry -eq $clean) {
            return $true
        }
        if ($registryName -and $entry.IndexOf($registryName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
        if ($entry.IndexOf($appName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
        if ($clean.Length -ge 5 -and $entry.IndexOf($clean, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
        $normEntry = ($entry -replace '[\s\-_+]', '').ToLower()
        if ($normEntry -eq $normApp -or ($normApp.Length -ge 5 -and $normEntry.Contains($normApp))) {
            return $true
        }
        # Reverse: app adı registry entry'yi içeriyor mu
        if ($normApp.Length -ge 5 -and $normApp.Contains(($normEntry -replace '[0-9\.]', '').TrimEnd()) -and $normEntry.Length -ge 5) {
            return $true
        }
    }

    # 7. Microsoft Store uygulamaları için genel AppxPackage eşleşmesi
    if ($id -and ($id -match '^[A-Z0-9]{12}$' -or $id -eq "Microsoft.PowerToys")) {
        if ($registryName -and $global:storeInstalledNames.Contains($registryName)) {
            return $true
        }
        if ($registryName) {
            foreach ($pkgName in $global:storeInstalledNames) {
                if ($pkgName.IndexOf($registryName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                    $registryName.IndexOf($pkgName, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    return $true
                }
            }
        }
        $cleanName = ($appName -replace '[\s\-_Uygulaması]', '').ToLower()
        if ($cleanName.Length -ge 5) {
            foreach ($pkgName in $global:storeInstalledNames) {
                $cleanPkg = ($pkgName -replace '[\s\-_]', '').ToLower()
                if ($cleanPkg.Length -ge 5 -and ($cleanPkg -eq $cleanName -or $cleanPkg.StartsWith($cleanName) -or $cleanName.StartsWith($cleanPkg))) {
                    return $true
                }
            }
        }
    }

    return $false
}


function Has-AppUpdate([string]$id) {
    if ($id -and $global:upgradableMap.Contains($id)) { return $true }
    return $false
}

Refresh-InstalledStatus

$xamlRaw = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Manager Pro — 2026 Edition"
        Height="950" Width="1540"
        MinHeight="800" MinWidth="1280"
        WindowStartupLocation="CenterScreen"
        Background="{DynamicResource WindowBg}"
        Foreground="{DynamicResource TextMain}"
        FontFamily="Segoe UI Semibold"
        ResizeMode="CanResize">

    <Window.Resources>
        <SolidColorBrush x:Key="WindowBg" Color="#0B0E14"/>
        <SolidColorBrush x:Key="SidebarBg" Color="#11161F"/>
        <SolidColorBrush x:Key="PanelBg" Color="#151C28"/>
        <SolidColorBrush x:Key="CardBg" Color="#1A2332"/>
        <SolidColorBrush x:Key="BorderColor" Color="#232E40"/>
        <SolidColorBrush x:Key="CardBorder" Color="#253246"/>
        <SolidColorBrush x:Key="TextMain" Color="#F3F4F6"/>
        <SolidColorBrush x:Key="TextMuted" Color="#8C9BB0"/>
        <SolidColorBrush x:Key="AccentColor" Color="#22C55E"/>
        <SolidColorBrush x:Key="NavHoverBg" Color="#1A38BDF8"/>
        <SolidColorBrush x:Key="HeaderBtnHover" Color="#2A374E"/>

        <SolidColorBrush x:Key="DisabledBtnBg" Color="#252F40"/>
        <SolidColorBrush x:Key="DisabledBtnFg" Color="#5E6F88"/>
        <SolidColorBrush x:Key="ScrollThumb" Color="#334155"/>
        <SolidColorBrush x:Key="ScrollThumbHover" Color="#475569"/>

        <Style TargetType="{x:Type ScrollBar}">
            <Setter Property="Stylus.IsPressAndHoldEnabled" Value="false"/>
            <Setter Property="Stylus.IsFlicksEnabled" Value="false"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="MinWidth" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ScrollBar}">
                        <Grid x:Name="Bg" SnapsToDevicePixels="true">
                            <Track x:Name="PART_Track" IsDirectionReversed="true" IsEnabled="{TemplateBinding IsMouseOver}">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="{x:Static ScrollBar.LineUpCommand}" Opacity="0" Focusable="false"/>
                                </Track.DecreaseRepeatButton>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="{x:Static ScrollBar.LineDownCommand}" Opacity="0" Focusable="false"/>
                                </Track.IncreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Margin="1,0,1,0">
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="{x:Type Thumb}">
                                                <Border x:Name="thumbBorder" Background="{DynamicResource ScrollThumb}" CornerRadius="3"/>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="true">
                                                        <Setter TargetName="thumbBorder" Property="Background" Value="{DynamicResource ScrollThumbHover}"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernNavBtn" TargetType="Button">
            <Setter Property="Height" Value="38"/>
            <Setter Property="Margin" Value="6,2"/>
            <Setter Property="Padding" Value="14,0"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{DynamicResource TextMuted}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="b" Background="{TemplateBinding Background}" CornerRadius="10" Padding="{TemplateBinding Padding}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="b" Property="Background" Value="{DynamicResource NavHoverBg}"/>
                                <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernHeaderBtn" TargetType="Button">
            <Setter Property="Height" Value="36"/>
            <Setter Property="Padding" Value="16,0"/>
            <Setter Property="Background" Value="{DynamicResource CardBg}"/>
            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="b" Background="{TemplateBinding Background}" CornerRadius="18" Padding="{TemplateBinding Padding}">
                            <ContentPresenter VerticalAlignment="Center" HorizontalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="b" Property="Background" Value="{DynamicResource HeaderBtnHover}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="GlossyActionBtn" TargetType="Button">
            <Setter Property="Height" Value="44"/>
            <Setter Property="Padding" Value="22,0"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="12.5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="btnBorder" Background="{TemplateBinding Background}" CornerRadius="22" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="btnBorder" Property="Background" Value="{DynamicResource DisabledBtnBg}"/>
                                <Setter Property="Foreground" Value="{DynamicResource DisabledBtnFg}"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="btnBorder" Property="Opacity" Value="0.9"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="230"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="340"/>
        </Grid.ColumnDefinitions>

        <!-- SOL MENÜ -->
        <Border Grid.Column="0" Background="{DynamicResource SidebarBg}" BorderBrush="{DynamicResource BorderColor}" BorderThickness="0,0,1,0">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="84"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="88"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Margin="18,18,12,0">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <Border Width="38" Height="38" CornerRadius="12" Background="#22C55E" VerticalAlignment="Center">
                            <TextBlock Text="⚡" FontSize="19" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="White"/>
                        </Border>
                        <StackPanel Margin="10,0,0,0" VerticalAlignment="Center">
                            <TextBlock Text="SYSTEM MANAGER" FontSize="13.5" FontWeight="Bold" Foreground="{DynamicResource TextMain}"/>
                            <TextBlock Text="2026 EDITION PRO" FontSize="9" FontWeight="Bold" Foreground="#22C55E" Margin="0,1,0,0"/>
                        </StackPanel>
                    </StackPanel>
                </StackPanel>

                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="6,2,6,0">
                        <TextBlock Text="KÜTÜPHANE" FontSize="9.5" FontWeight="Bold" Foreground="{DynamicResource TextMuted}" Margin="14,6,0,6"/>

                        <Button Name="btnNavAll" Style="{StaticResource ModernNavBtn}" Content="▣    Tüm Uygulamalar"/>
                        <Button Name="btnNavInstalled" Style="{StaticResource ModernNavBtn}" Content="✓    Yüklü Olanlar"/>
                        <Button Name="btnNavUpdates" Style="{StaticResource ModernNavBtn}" Content="⚡    Güncellenecekler"/>
                        <Button Name="btnNavBrowsers" Style="{StaticResource ModernNavBtn}" Content="◎    Tarayıcı &amp; İletişim"/>
                        <Button Name="btnNavGames" Style="{StaticResource ModernNavBtn}" Content="◆    Oyun &amp; Medya"/>
                        <Button Name="btnNavDev" Style="{StaticResource ModernNavBtn}" Content="⌘    Geliştirici &amp; AI"/>
                        <Button Name="btnNavHardware" Style="{StaticResource ModernNavBtn}" Content="◈    Donanım &amp; Sürücü"/>
                        <Button Name="btnNavSecurity" Style="{StaticResource ModernNavBtn}" Content="🛡    Güvenlik &amp; Kalkan"/>
                        <Button Name="btnNavRuntimes" Style="{StaticResource ModernNavBtn}" Content="{}    .NET &amp; Visual C++"/>
                        <Button Name="btnNavTools" Style="{StaticResource ModernNavBtn}" Content="🛠    Sistem &amp; Araçlar"/>

                        <Separator Margin="14,10,14,6" Background="{DynamicResource BorderColor}"/>

                        <TextBlock Text="SİSTEM EYLEMLERİ" FontSize="9.5" FontWeight="Bold" Foreground="{DynamicResource TextMuted}" Margin="14,4,0,6"/>
                        <Button Name="btnOpenDiskCleaner" Style="{StaticResource ModernNavBtn}" Content="🧹    Sistem &amp; Disk Temizleyici"/>
                        <Button Name="btnOpenDefenderScan" Style="{StaticResource ModernNavBtn}" Content="🛡️    Virüs &amp; Tehdit Koruması"/>
                        <Button Name="btnOpenDriverHub" Style="{StaticResource ModernNavBtn}" Content="🚗    Sürücü Yöneticisi"/>
                        <Button Name="btnOpenToolsModal" Style="{StaticResource ModernNavBtn}" Content="⚙    Gelişmiş Araçlar"/>
                        <Button Name="btnRefresh" Style="{StaticResource ModernNavBtn}" Content="↻    Durumu Yenile"/>
                    </StackPanel>
                </ScrollViewer>

                <Border Grid.Row="2" Background="{DynamicResource CardBg}" Margin="10,6,10,12" CornerRadius="12" BorderBrush="{DynamicResource BorderColor}" BorderThickness="1">
                    <StackPanel Margin="12,10">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Ellipse Width="8" Height="8" Fill="#22C55E" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <TextBlock Name="txtWingetStatus" Text="WinGet Engine Aktif" FontSize="11" FontWeight="Bold" Foreground="#22C55E"/>
                        </StackPanel>
                        <TextBlock Name="txtSelectedCount" Text="0 program sırada" FontSize="10" Foreground="{DynamicResource TextMuted}" Margin="16,3,0,0"/>
                    </StackPanel>
                </Border>
            </Grid>
        </Border>

        <!-- ORTA PANEL -->
        <Grid Grid.Column="1" Margin="20,16,16,16">
            <Grid.RowDefinitions>
                <RowDefinition Height="60"/>
                <RowDefinition Height="48"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="86"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0">
                <StackPanel VerticalAlignment="Center">
                    <TextBlock Name="txtHeaderTitle" Text="Tüm Uygulamalar" FontSize="21" FontWeight="Bold" Foreground="{DynamicResource TextMain}"/>
                    <TextBlock Text="Yeşil rozetler sisteminizde zaten kurulu olanları belirtir." FontSize="11" Foreground="{DynamicResource TextMuted}" Margin="0,2,0,0"/>
                </StackPanel>

                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Button Name="btnSourcePrefToggle" Style="{StaticResource ModernHeaderBtn}" Content="📦 Kaynak: Her Zaman Sor" Margin="0,0,8,0" Cursor="Hand" ToolTip="Çift kaynaklı (Web / Store) uygulamalar için tercih edilen indirme modunu ayarlar veya değiştirir."/>
                    <Button Name="btnSelectUpdates" Style="{StaticResource ModernHeaderBtn}" Content="⚡ Güncelle" Margin="0,0,8,0"/>
                    <Button Name="btnTheme" Style="{StaticResource ModernHeaderBtn}" Content="☼ Açık Tema" Width="106"/>
                </StackPanel>
            </Grid>

            <!-- Arama Alanı -->
            <Grid Grid.Row="1" Margin="0,4,0,8">
                <Border Background="{DynamicResource PanelBg}" BorderBrush="{DynamicResource BorderColor}" BorderThickness="1" CornerRadius="18" Width="360" HorizontalAlignment="Left">
                    <Grid Margin="12,0,10,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>

                        <TextBlock Grid.Column="0" Text="🔍" FontSize="12.5" Foreground="{DynamicResource TextMuted}" VerticalAlignment="Center" Margin="0,0,8,0" IsHitTestVisible="False"/>
                        <TextBlock Grid.Column="1" Name="txtPlaceholder" Text="Uygulama veya paket ara..." Foreground="{DynamicResource TextMuted}" VerticalAlignment="Center" IsHitTestVisible="False" FontSize="11.5"/>
                        <TextBox Grid.Column="1" Name="txtSearch" Background="Transparent" Foreground="{DynamicResource TextMain}" BorderThickness="0" VerticalContentAlignment="Center" FontSize="11.5" CaretBrush="{DynamicResource TextMain}"/>

                        <Button Grid.Column="2" Name="btnClearSearch" Content="✕" Width="20" Height="20" Background="{DynamicResource CardBg}" Foreground="{DynamicResource TextMuted}" BorderThickness="0" Cursor="Hand" Visibility="Collapsed">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}" CornerRadius="10">
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                    </Grid>
                </Border>
                <TextBlock Name="txtVisibleCount" Text="0 uygulama listelendi" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="{DynamicResource TextMuted}" FontSize="11"/>
            </Grid>

            <!-- 3'lü Kompakt Kütüphane -->
            <Border Grid.Row="2" Name="cardContainerBorder" Background="{DynamicResource PanelBg}" BorderBrush="{DynamicResource BorderColor}" BorderThickness="1" CornerRadius="14" Padding="12">
                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel Name="categoriesContainerPanel"/>
                </ScrollViewer>
            </Border>

            <!-- Alt Durum Çubuğu -->
            <Border Grid.Row="3" Background="{DynamicResource PanelBg}" BorderBrush="{DynamicResource BorderColor}" BorderThickness="1" CornerRadius="14" Margin="0,10,0,0" Padding="16,10">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <StackPanel Grid.Column="0" VerticalAlignment="Center">
                        <TextBlock Name="txtStatus" Text="● Sistem hazır. Sıraya paket ekleyebilirsiniz." FontSize="11.5" Foreground="{DynamicResource TextMuted}"/>
                        <StackPanel Margin="0,8,18,0">
                            <ProgressBar Name="mainProgress" Height="8" Minimum="0" Maximum="100" Value="0" Background="{DynamicResource BorderColor}" Foreground="#22C55E" BorderThickness="0">
                                <ProgressBar.Template>
                                    <ControlTemplate TargetType="ProgressBar">
                                        <Grid>
                                            <Border Background="{TemplateBinding Background}" CornerRadius="4"/>
                                            <Border Name="PART_Track" CornerRadius="4"/>
                                            <Border Name="PART_Indicator" HorizontalAlignment="Left" CornerRadius="4">
                                                <Border.Background>
                                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                                        <GradientStop Color="#10B981" Offset="0.0"/>
                                                        <GradientStop Color="#34D399" Offset="0.5"/>
                                                        <GradientStop Color="#059669" Offset="1.0"/>
                                                    </LinearGradientBrush>
                                                </Border.Background>
                                            </Border>
                                        </Grid>
                                    </ControlTemplate>
                                </ProgressBar.Template>
                            </ProgressBar>
                            <TextBlock Name="txtProgress" Text="0%" FontSize="9.5" Foreground="{DynamicResource TextMuted}" HorizontalAlignment="Right" Margin="0,4,0,0"/>
                        </StackPanel>
                    </StackPanel>

                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button Name="btnInstall" Style="{StaticResource GlossyActionBtn}" Content="Seçilenleri Kur" Background="#22C55E" Margin="0,0,8,0" IsEnabled="False"/>
                        <Button Name="btnUpgrade" Style="{StaticResource GlossyActionBtn}" Content="Güncelle" Background="#3B82F6" Margin="0,0,8,0" IsEnabled="False"/>
                        <Button Name="btnUninstall" Style="{StaticResource GlossyActionBtn}" Content="Kaldır" Background="#EF4444" IsEnabled="False"/>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>

        <!-- SAĞ KURULUM SIRASI -->
        <Border Grid.Column="2" Background="{DynamicResource SidebarBg}" BorderBrush="{DynamicResource BorderColor}" BorderThickness="1,0,0,0">
            <Grid Margin="14,18,14,18">
                <Grid.RowDefinitions>
                    <RowDefinition Height="50"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Grid Grid.Row="0">
                    <StackPanel VerticalAlignment="Center">
                        <TextBlock Name="lblQueueHeader" Text="Kurulum Sırası (0)" FontSize="13" FontWeight="Bold" Foreground="{DynamicResource TextMain}"/>
                        <TextBlock Text="Sürükleyip bırakarak sıralayın" FontSize="9.5" Foreground="{DynamicResource TextMuted}" Margin="0,1,0,0"/>
                    </StackPanel>
                    <Button Name="btnClearQueue" Content="Temizle (✕)" Width="80" Height="26" HorizontalAlignment="Right" VerticalAlignment="Center" Background="#EF4444" Foreground="#FFFFFF" BorderThickness="0" FontWeight="Bold" FontSize="10" Cursor="Hand">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border Background="{TemplateBinding Background}" CornerRadius="13">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                </Grid>

                <Border Grid.Row="1" Background="{DynamicResource WindowBg}" CornerRadius="12" BorderBrush="{DynamicResource BorderColor}" BorderThickness="1" Padding="6">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                        <StackPanel Name="queueStackPanel" AllowDrop="True"/>
                    </ScrollViewer>
                </Border>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$cleanXaml = $xamlRaw.Trim().Trim([char]0xFEFF)
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($cleanXaml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Kontrol Tanımları
$categoriesContainerPanel = $window.FindName("categoriesContainerPanel")
$cardContainerBorder = $window.FindName("cardContainerBorder")
$queueStackPanel = $window.FindName("queueStackPanel")
$lblQueueHeader = $window.FindName("lblQueueHeader")
$global:btnPrefSourcePill = $window.FindName("btnPrefSourcePill")
$global:btnSourcePrefToggle = $window.FindName("btnSourcePrefToggle")

function Update-PrefSourceButton {
    $btnList = @($global:btnPrefSourcePill, $global:btnSourcePrefToggle)
    foreach ($btn in $btnList) {
        if (-not $btn) { continue }
        if ($global:preferredInstallSource -eq "Normal") {
            $btn.Content = "Kaynak: Normal (Web)"
            $btn.Foreground = Brush("#38BDF8")
        } elseif ($global:preferredInstallSource -eq "Store") {
            $btn.Content = "Kaynak: Microsoft Store"
            $btn.Foreground = Brush("#C084FC")
        } else {
            $btn.Content = "Kaynak: Her Zaman Sor"
            $btn.Foreground = Brush("#94A3B8")
        }
    }
}

function global:Update-CardSourceBadge($card, [string]$source) {
    if (-not $card -or -not $card.Tag) { return }
    $state = $card.Tag
    if (-not $state.SourceBadge -or -not $state.SourceBadgeText) { return }
    # Yuklu olan uygulamalarin rozeti kurulu gercek duruma gore kilitlidir, degistirilemez!
    if ($state.IsInstalled) { return }

    if ($source -eq "Store") {
        # Soft pastel purple / indigo
        $state.SourceBadge.Background = if ($global:isDark) { Brush("#2A2458") } else { Brush("#EDE9FE") }
        $state.SourceBadge.BorderBrush = if ($global:isDark) { Brush("#7C3AED") } else { Brush("#DDD6FE") }
        $state.SourceBadgeText.Text = "Store"
        $state.SourceBadgeText.Foreground = if ($global:isDark) { Brush("#D8B4FE") } else { Brush("#6D28D9") }
        if ($state.SourceBadgeImg) {
            if ($global:bmpStoreLogo) {
                $state.SourceBadgeImg.Source = $global:bmpStoreLogo
            }
            $state.SourceBadgeImg.Visibility = [System.Windows.Visibility]::Visible
        }
    } else {
        # Soft pastel sky / cyan
        $state.SourceBadge.Background = if ($global:isDark) { Brush("#0C3247") } else { Brush("#E0F2FE") }
        $state.SourceBadge.BorderBrush = if ($global:isDark) { Brush("#0284C7") } else { Brush("#BAE6FD") }
        $state.SourceBadgeText.Text = "Normal"
        $state.SourceBadgeText.Foreground = if ($global:isDark) { Brush("#7DD3FC") } else { Brush("#0369A1") }
        if ($state.SourceBadgeImg) {
            if ($global:bmpGlobeLogo) {
                $state.SourceBadgeImg.Source = $global:bmpGlobeLogo
            }
            $state.SourceBadgeImg.Visibility = [System.Windows.Visibility]::Visible
        }
    }
}

$CycleSourcePrefHandler = {
    if ($global:preferredInstallSource -eq "Ask") {
        $global:preferredInstallSource = "Normal"
    } elseif ($global:preferredInstallSource -eq "Normal") {
        $global:preferredInstallSource = "Store"
    } else {
        $global:preferredInstallSource = "Ask"
    }
    Save-UserSettings
    Update-PrefSourceButton

    # Sag ustteki kaynak tercihi degistiginde tum cift kaynakli uygulamalar:
    # "Store" secildiyse -> hepsi Store rozetine guncellenir
    # "Normal" veya "Her Zaman Sor" secildiyse -> hepsi standart Normal rozetine guncellenir (ve Her Zaman Sor aciksa kart secildiginde pencere sorar)
    $targetPref = if ($global:preferredInstallSource -eq "Store") { "Store" } else { "Normal" }
    if ($global:allCards) {
        foreach ($c in $global:allCards) {
            if ($c.Tag -and $c.Tag.App) {
                $a = $c.Tag.App
                $isDual = ($a.HasDual -eq "1") -or ($a.StoreId -and ($a.NormalId -or $a.DownloadUrl))
                if ($isDual) {
                    $a.SelectedSource = $targetPref
                    Update-CardSourceBadge $c $targetPref
                }
            }
        }
    }
    Render-QueuePanel
}

if ($global:btnSourcePrefToggle) {
    $global:btnSourcePrefToggle.Add_Click($CycleSourcePrefHandler)
}
if ($global:btnPrefSourcePill) {
    $global:btnPrefSourcePill.Add_Click($CycleSourcePrefHandler)
}
Update-PrefSourceButton

$txtStatus = $window.FindName("txtStatus")
$txtSearch = $window.FindName("txtSearch")
$txtPlaceholder = $window.FindName("txtPlaceholder")
$btnClearSearch = $window.FindName("btnClearSearch")
$txtHeaderTitle = $window.FindName("txtHeaderTitle")
$txtSelectedCount = $window.FindName("txtSelectedCount")
$txtVisibleCount = $window.FindName("txtVisibleCount")
$txtWingetStatus = $window.FindName("txtWingetStatus")
$mainProgress = $window.FindName("mainProgress")
$txtProgress = $window.FindName("txtProgress")

$btnInstall = $window.FindName("btnInstall")
$btnUpgrade = $window.FindName("btnUpgrade")
$btnUninstall = $window.FindName("btnUninstall")
$btnTheme = $window.FindName("btnTheme")
$btnRefresh = $window.FindName("btnRefresh")
$btnSelectUpdates = $window.FindName("btnSelectUpdates")
$btnClearQueue = $window.FindName("btnClearQueue")
$btnOpenDiskCleaner = $window.FindName("btnOpenDiskCleaner")
$btnOpenDefenderScan = $window.FindName("btnOpenDefenderScan")

$btnOpenDriverHub = $window.FindName("btnOpenDriverHub")
$btnOpenToolsModal = $window.FindName("btnOpenToolsModal")

$navButtons = @{
    "All"       = $window.FindName("btnNavAll")
    "Installed" = $window.FindName("btnNavInstalled")
    "Updates"   = $window.FindName("btnNavUpdates")
    "Browsers"  = $window.FindName("btnNavBrowsers")
    "Games"    = $window.FindName("btnNavGames")
    "Dev"      = $window.FindName("btnNavDev")
    "Hardware" = $window.FindName("btnNavHardware")
    "Security" = $window.FindName("btnNavSecurity")
    "Runtimes" = $window.FindName("btnNavRuntimes")
    "Tools"    = $window.FindName("btnNavTools")
}

$global:allCards = [System.Collections.ArrayList]::new()
$global:allGroupWrappers = [System.Collections.ArrayList]::new()
$global:selectedQueue = [System.Collections.ArrayList]::new()
$global:currentCategory = "All"
$global:isDark = $true
$global:isBusy = $false
$global:draggedItem = $null

# function Brush moved to top

function Set-Status([string]$message, [string]$kind = "INFO") {
    $txtStatus.Text = "● $message"
    switch ($kind) {
        "OK"   { $txtStatus.Foreground = Brush("#22C55E") }
        "WARN" { $txtStatus.Foreground = Brush("#F59E0B") }
        "ERR"  { $txtStatus.Foreground = Brush("#EF4444") }
        default { $txtStatus.Foreground = if ($global:isDark) { Brush("#8C9BB0") } else { Brush("#64748B") } }
    }
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

function Set-ProgressValue([int]$targetValue) {
    if ($targetValue -lt 0) { $targetValue = 0 }
    if ($targetValue -gt 100) { $targetValue = 100 }

    $current = [int]$mainProgress.Value
    if ($targetValue -gt $current) {
        $diff = $targetValue - $current
        $step = [Math]::Max(1, [int]($diff / 8))
        for ($v = $current; $v -lt $targetValue; $v += $step) {
            $mainProgress.Value = $v
            $txtProgress.Text = "$v%"
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
            Start-Sleep -Milliseconds 15
        }
    }
    $mainProgress.Value = $targetValue
    $txtProgress.Text = "$targetValue%"
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
}

# --- BİLDİRİM & ONAY PENCERELERİ ---
function Show-ModernConfirmDialog([string]$title, [string]$operation, [array]$itemList) {
    $dialog = New-Object System.Windows.Window
    $dialog.Title = $title
    $dialog.Width = 470
    $dialog.Height = 310
    $dialog.WindowStartupLocation = "CenterOwner"
    try { if ($window -and $window.IsVisible) { $dialog.Owner = $window } } catch {}
    $dialog.Background = if ($global:isDark) { Brush("#11161F") } else { Brush("#FFFFFF") }
    $dialog.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    $dialog.ResizeMode = "NoResize"
    $dialog.WindowStyle = "ToolWindow"

    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Margin = New-Object System.Windows.Thickness(22)

    $tHeader = New-Object System.Windows.Controls.TextBlock
    $tHeader.Text = "$operation İşlem Onayı"
    $tHeader.FontSize = 15
    $tHeader.FontWeight = "Bold"
    $tHeader.Foreground = Brush("#3B82F6")
    [void]$sp.Children.Add($tHeader)

    $tSub = New-Object System.Windows.Controls.TextBlock
    $tSub.Text = "Aşağıdaki $($itemList.Count) uygulama için [$operation] işlemi yürütülecektir:"
    $tSub.FontSize = 11
    $tSub.Foreground = if ($global:isDark) { Brush("#8C9BB0") } else { Brush("#64748B") }
    $tSub.Margin = New-Object System.Windows.Thickness(0,6,0,10)
    [void]$sp.Children.Add($tSub)

    $listBorder = New-Object System.Windows.Controls.Border
    $listBorder.Background = if ($global:isDark) { Brush("#151C28") } else { Brush("#F1F5F9") }
    $listBorder.BorderBrush = if ($global:isDark) { Brush("#232E40") } else { Brush("#CBD5E1") }
    $listBorder.BorderThickness = New-Object System.Windows.Thickness(1)
    $listBorder.CornerRadius = New-Object System.Windows.CornerRadius(8)
    $listBorder.Height = 110
    $listBorder.Padding = New-Object System.Windows.Thickness(10)

    $scroller = New-Object System.Windows.Controls.ScrollViewer
    $scroller.VerticalScrollBarVisibility = "Auto"
    $listText = New-Object System.Windows.Controls.TextBlock
    $listText.Text = ($itemList | ForEach-Object { "• " + $_.Tag.App.Name }) -join "`n"
    $listText.FontSize = 11
    $listText.Foreground = if ($global:isDark) { Brush("#E2E8F0") } else { Brush("#1E293B") }
    $scroller.Content = $listText
    $listBorder.Child = $scroller
    [void]$sp.Children.Add($listBorder)

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = "Horizontal"
    $btnPanel.HorizontalAlignment = "Right"
    $btnPanel.Margin = New-Object System.Windows.Thickness(0,16,0,0)

    $btnCancel = New-Object System.Windows.Controls.Button
    $btnCancel.Content = "İptal"
    $btnCancel.Width = 85
    $btnCancel.Height = 34
    $btnCancel.Background = if ($global:isDark) { Brush("#232E40") } else { Brush("#E2E8F0") }
    $btnCancel.Foreground = if ($global:isDark) { Brush("#E2E8F0") } else { Brush("#334155") }
    $btnCancel.FontWeight = "Bold"
    $btnCancel.Margin = New-Object System.Windows.Thickness(0,0,10,0)
    $btnCancel.BorderThickness = New-Object System.Windows.Thickness(0)
    $btnCancel.Cursor = "Hand"
    $btnCancel.Template = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="17"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>')

    $btnApprove = New-Object System.Windows.Controls.Button
    $btnApprove.Content = "Evet, Başlat"
    $btnApprove.Width = 110
    $btnApprove.Height = 34
    $btnApprove.Background = Brush("#22C55E")
    $btnApprove.Foreground = Brush("#FFFFFF")
    $btnApprove.FontWeight = "Bold"
    $btnApprove.BorderThickness = New-Object System.Windows.Thickness(0)
    $btnApprove.Cursor = "Hand"
    $btnApprove.Template = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="17"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>')

    $script:dialogResult = $false
    $btnCancel.Add_Click({ $dialog.Close() })
    $btnApprove.Add_Click({
        $script:dialogResult = $true
        $dialog.Close()
    })

    [void]$btnPanel.Children.Add($btnCancel)
    [void]$btnPanel.Children.Add($btnApprove)
    [void]$sp.Children.Add($btnPanel)

    $dialog.Content = $sp
    [void]$dialog.ShowDialog()
    return $script:dialogResult
}

function Show-ModernAlert([string]$title, [string]$message, [string]$kind = "WARN") {
    $alertWin = New-Object System.Windows.Window
    $alertWin.Title = $title
    $alertWin.Width = 440
    $alertWin.SizeToContent = [System.Windows.SizeToContent]::Height
    $alertWin.WindowStartupLocation = "CenterOwner"
    try {
        if ($global:currentToolsWin -and $global:currentToolsWin.IsVisible) {
            $alertWin.Owner = $global:currentToolsWin
        } elseif ($window -and $window.IsVisible) {
            $alertWin.Owner = $window
        }
    } catch {}
    $alertWin.Background = if ($global:isDark) { Brush("#11161F") } else { Brush("#FFFFFF") }
    $alertWin.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    $alertWin.ResizeMode = "NoResize"
    $alertWin.WindowStyle = "ToolWindow"

    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Margin = New-Object System.Windows.Thickness(20, 18, 20, 18)

    $gridHead = New-Object System.Windows.Controls.Grid
    $colIco = New-Object System.Windows.Controls.ColumnDefinition; $colIco.Width = [System.Windows.GridLength]::Auto
    $colTxt = New-Object System.Windows.Controls.ColumnDefinition; $colTxt.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$gridHead.ColumnDefinitions.Add($colIco); [void]$gridHead.ColumnDefinitions.Add($colTxt)

    $ico = New-Object System.Windows.Controls.TextBlock
    $ico.Text = if ($kind -eq "ERR") { [char]0x26A0 } else { [char]0x2139 }
    $ico.FontSize = 24
    $ico.Margin = New-Object System.Windows.Thickness(0,0,12,0)
    [System.Windows.Controls.Grid]::SetColumn($ico, 0)
    [void]$gridHead.Children.Add($ico)

    $tBox = New-Object System.Windows.Controls.StackPanel
    $tTitle = New-Object System.Windows.Controls.TextBlock
    $tTitle.Text = $title
    $tTitle.FontSize = 13.5
    $tTitle.FontWeight = "Bold"
    $tTitle.Foreground = if ($kind -eq "ERR") { Brush("#EF4444") } else { Brush("#3B82F6") }

    $tMsg = New-Object System.Windows.Controls.TextBlock
    $tMsg.Text = $message
    $tMsg.FontSize = 11
    $tMsg.Foreground = if ($global:isDark) { Brush("#8C9BB0") } else { Brush("#64748B") }
    $tMsg.TextWrapping = "Wrap"
    $tMsg.Margin = New-Object System.Windows.Thickness(0,4,0,0)

    [void]$tBox.Children.Add($tTitle)
    [void]$tBox.Children.Add($tMsg)
    [System.Windows.Controls.Grid]::SetColumn($tBox, 1)
    [void]$gridHead.Children.Add($tBox)
    [void]$sp.Children.Add($gridHead)

    $btnOk = New-Object System.Windows.Controls.Button
    $btnOk.Content = "Tamam"
    $btnOk.Width = 90
    $btnOk.Height = 32
    $btnOk.Background = if ($global:isDark) { Brush("#232E40") } else { Brush("#E2E8F0") }
    $btnOk.Foreground = if ($global:isDark) { Brush("#FFFFFF") } else { Brush("#1E293B") }
    $btnOk.FontWeight = "Bold"
    $btnOk.HorizontalAlignment = "Right"
    $btnOk.Margin = New-Object System.Windows.Thickness(0,14,0,0)
    $btnOk.BorderThickness = New-Object System.Windows.Thickness(0)
    $btnOk.Cursor = "Hand"
    $btnOk.Template = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="16"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>')
    $btnOk.Add_Click({ $alertWin.Close() })
    [void]$sp.Children.Add($btnOk)

    $alertWin.Content = $sp
    [void]$alertWin.ShowDialog()
}


# --- SÜRÜKLE-BIRAK SAĞ PANEL ---



function Render-QueuePanel {
    $queueStackPanel.Children.Clear()
    $count = $global:selectedQueue.Count
    $lblQueueHeader.Text = "Kurulum Sırası ($count)"
    Update-PrefSourceButton
    $txtSelectedCount.Text = "$count program sırada"

    for ($i = 0; $i -lt $count; $i++) {
        $card = $global:selectedQueue[$i]
        $state = $card.Tag

        $row = New-Object System.Windows.Controls.Border
        $row.Background = if ($global:isDark) { Brush("#151C28") } else { Brush("#FFFFFF") }
        $row.BorderBrush = if ($global:isDark) { Brush("#253246") } else { Brush("#E2E8F0") }
        $row.BorderThickness = New-Object System.Windows.Thickness(1)
        $row.CornerRadius = New-Object System.Windows.CornerRadius(10)
        $row.Margin = New-Object System.Windows.Thickness(0,2,0,6)
        $row.Padding = New-Object System.Windows.Thickness(10,5,10,5)
        $row.Height = 48
        $row.Tag = $card
        try { $state.QueueRow = $row } catch {}
        $row.Cursor = "Hand"

        $scaleTrans = New-Object System.Windows.Media.ScaleTransform(1.0, 1.0)
        $row.RenderTransform = $scaleTrans
        $row.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)

        $row.Add_PreviewMouseLeftButtonDown({
            param($s, $e)
            $orig = $e.OriginalSource
            # Silme butonu veya kaynak degistirme rozetine tiklanmissa suruklemeyi tetikleme
            if ($orig -is [System.Windows.Controls.Button] -or 
                ($orig.Tag -and $orig.Tag.IsSourceToggle) -or 
                ($orig.Parent -and $orig.Parent.Tag -and $orig.Parent.Tag.IsSourceToggle) -or 
                ($orig -is [System.Windows.Controls.TextBlock] -and $orig.Text -match '⇄')) {
                return
            }
            $st = $s.RenderTransform
            if ($st -is [System.Windows.Media.ScaleTransform]) {
                $st.ScaleX = 0.94
                $st.ScaleY = 0.94
            }
            $s.Opacity = 0.65
            $global:draggedItem = $s.Tag
            [System.Windows.DragDrop]::DoDragDrop($s, $s.Tag, [System.Windows.DragDropEffects]::Move)
            if ($st -is [System.Windows.Media.ScaleTransform]) {
                $st.ScaleX = 1.0
                $st.ScaleY = 1.0
            }
            $s.Opacity = 1.0
        })

        $row.AllowDrop = $true
        $row.Add_DragOver({
            param($s, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true
            $sourceCard = $global:draggedItem
            $targetCard = $s.Tag
            if ($sourceCard -and $targetCard -and ($sourceCard -ne $targetCard)) {
                $idxSource = $global:selectedQueue.IndexOf($sourceCard)
                $idxTarget = $global:selectedQueue.IndexOf($targetCard)
                if ($idxSource -ge 0 -and $idxTarget -ge 0) {
                    $global:selectedQueue.RemoveAt($idxSource)
                    $global:selectedQueue.Insert($idxTarget, $sourceCard)
                    Render-QueuePanel
                }
            }
        })

        $grid = New-Object System.Windows.Controls.Grid
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::Auto
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $c3 = New-Object System.Windows.Controls.ColumnDefinition; $c3.Width = [System.Windows.GridLength]::Auto
        [void]$grid.ColumnDefinitions.Add($c1); [void]$grid.ColumnDefinitions.Add($c2); [void]$grid.ColumnDefinitions.Add($c3)

        $img = New-Object System.Windows.Controls.Image
        $img.Width = 22
        $img.Height = 22
        $img.Margin = New-Object System.Windows.Thickness(0,0,10,0)
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        $img.Source = $state.IconSource
        [System.Windows.Controls.Grid]::SetColumn($img, 0)
        [void]$grid.Children.Add($img)

        $nameSp = New-Object System.Windows.Controls.StackPanel
        $nameSp.VerticalAlignment = "Center"

        $txt = New-Object System.Windows.Controls.TextBlock
        $txt.Text = $state.App.Name
        $txt.FontSize = 11.5
        $txt.FontWeight = "Bold"
        $txt.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
        $txt.TextTrimming = "CharacterEllipsis"
        [void]$nameSp.Children.Add($txt)

        $badgeSp = New-Object System.Windows.Controls.StackPanel
        $badgeSp.Orientation = "Horizontal"
        $badgeSp.Margin = New-Object System.Windows.Thickness(0, 2, 0, 0)

        $srcBadge = New-Object System.Windows.Controls.Border
        $srcBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $srcBadge.Padding = New-Object System.Windows.Thickness(5, 1, 5, 1)

        $srcTxt = New-Object System.Windows.Controls.TextBlock
        $srcTxt.FontSize = 9.5
        $srcTxt.FontWeight = "SemiBold"

        $isStoreChosen = ($state.App.SelectedSource -eq "Store") -or ($state.App.Id -match '^[A-Z0-9]{12,14}$' -and -not $state.App.NormalId)
        $isDual = ($state.App.HasDual -eq "1") -or ($state.App.StoreId -and ($state.App.NormalId -or $state.App.DownloadUrl -or ($state.App.Id -and $state.App.Id -ne $state.App.StoreId)))

        if ($isStoreChosen) {
            $srcBadge.Background = if ($global:isDark) { Brush("#2E1065") } else { Brush("#F3E8FF") }
            $srcBadge.BorderBrush = Brush("#7C3AED")
            $srcBadge.BorderThickness = New-Object System.Windows.Thickness(1)
            $srcTxt.Text = "🛍️ Microsoft Store"
            $srcTxt.Foreground = if ($global:isDark) { Brush("#C084FC") } else { Brush("#7C3AED") }
        } elseif ($isDual -or $state.App.SelectedSource -eq "Normal") {
            $srcBadge.Background = if ($global:isDark) { Brush("#082F49") } else { Brush("#E0F2FE") }
            $srcBadge.BorderBrush = Brush("#0284C7")
            $srcBadge.BorderThickness = New-Object System.Windows.Thickness(1)
            $srcTxt.Text = "🌐 Standart (Web)"
            $srcTxt.Foreground = if ($global:isDark) { Brush("#38BDF8") } else { Brush("#0284C7") }
        } else {
            $srcBadge.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#F1F5F9") }
            $srcBadge.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
            $srcBadge.BorderThickness = New-Object System.Windows.Thickness(1)
            $srcTxt.Text = "⚡ WinGet Paket"
            $srcTxt.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
        }

        if ($isDual) {
            $srcBadge.Cursor = "Hand"
            $srcBadge.ToolTip = "Kaynağı değiştirmek için tıklayın (Web ⇄ Store)"
            $srcTxt.Text += " ⇄"

            $srcToggleData = @{ App = $state.App; Card = $card; IsSourceToggle = $true }
            $srcBadge.Tag = $srcToggleData
            $srcTxt.Tag = $srcToggleData

            # Hover efektleri
            $srcBadge.Add_MouseEnter({
                param($s, $e)
                $appRef = $s.Tag.App
                if ($appRef.SelectedSource -eq "Store") {
                    $s.Background = Brush("#3B0764"); $s.BorderBrush = Brush("#A855F7")
                } else {
                    $s.Background = Brush("#0369A1"); $s.BorderBrush = Brush("#38BDF8")
                }
            })
            $srcBadge.Add_MouseLeave({
                param($s, $e)
                $appRef = $s.Tag.App
                if ($appRef.SelectedSource -eq "Store") {
                    $s.Background = if ($global:isDark) { Brush("#2E1065") } else { Brush("#F3E8FF") }
                    $s.BorderBrush = Brush("#7C3AED")
                } else {
                    $s.Background = if ($global:isDark) { Brush("#082F49") } else { Brush("#E0F2FE") }
                    $s.BorderBrush = Brush("#0284C7")
                }
            })

            $queueBadgeClick = {
                param($s, $e)
                $e.Handled = $true
                $tCard = $s.Tag.Card
                $tApp = $s.Tag.App
                if ($tApp.SelectedSource -eq "Store") {
                    $tApp.SelectedSource = "Normal"
                } else {
                    $tApp.SelectedSource = "Store"
                }
                Update-CardSourceBadge $tCard $tApp.SelectedSource
                Render-QueuePanel
            }
            $srcBadge.Add_PreviewMouseLeftButtonDown($queueBadgeClick)
            $srcTxt.Add_PreviewMouseLeftButtonDown($queueBadgeClick)
        }
        $srcBadge.Child = $srcTxt
        [void]$badgeSp.Children.Add($srcBadge)
        [void]$nameSp.Children.Add($badgeSp)

        [System.Windows.Controls.Grid]::SetColumn($nameSp, 1)
        [void]$grid.Children.Add($nameSp)

        $btnDel = New-Object System.Windows.Controls.Button
        $btnDel.Content = "✕"
        $btnDel.FontSize = 10.5
        $btnDel.Width = 24
        $btnDel.Height = 24
        $btnDel.Background = Brush("#EF4444")
        $btnDel.Foreground = Brush("#FFFFFF")
        $btnDel.BorderThickness = New-Object System.Windows.Thickness(0)
        $btnDel.Cursor = "Hand"
        $btnDel.Tag = $card
        $btnDel.Template = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="12"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>')

        $btnDel.Add_PreviewMouseLeftButtonDown({
            param($sender, $e)
            $e.Handled = $true
            Toggle-CardSelection $sender.Tag
        })
        [System.Windows.Controls.Grid]::SetColumn($btnDel, 2)
        [void]$grid.Children.Add($btnDel)

        $row.Child = $grid
        [void]$queueStackPanel.Children.Add($row)
    }

    Update-ActionButtonGuards
}

# --- AKILLİ BUTON KONTROLLERİ ---
function Update-ActionButtonGuards {
    $count = $global:selectedQueue.Count
    if ($global:isBusy) {
        $btnInstall.IsEnabled = $false
        $btnUpgrade.IsEnabled = $false
        $btnUninstall.IsEnabled = $false
        return
    }

    if ($count -eq 0) {
        $btnInstall.IsEnabled = $false
        $btnUpgrade.IsEnabled = $false
        $btnUninstall.IsEnabled = $false
        $btnInstall.Content = "Seçilenleri Kur"
        $btnUpgrade.Content = "Güncelle"
        $btnUninstall.Content = "Kaldır"
        Set-Status "Sistem hazır. Sıraya paket ekleyebilirsiniz."
        return
    }

    $canInstallCount = 0
    $canUpgradeCount = 0
    $canUninstallCount = 0

    foreach ($card in $global:selectedQueue) {
        $state = $card.Tag
        $isInst = $state.IsInstalled
        $hasUp = $state.HasUpdate

        if (-not $isInst) {
            $canInstallCount++
        }
        if ($isInst -and $hasUp) {
            $canUpgradeCount++
        }
        if ($isInst) {
            $canUninstallCount++
        }
    }

    # 1. Kur Butonu: Sadece henüz kurulu olmayan paketler seçiliyse aktif olur
    if ($canInstallCount -gt 0) {
        $btnInstall.IsEnabled = $true
        $btnInstall.Content = "Seçilenleri Kur ($canInstallCount)"
    } else {
        $btnInstall.IsEnabled = $false
        $btnInstall.Content = "Kur"
    }

    # 2. Güncelle Butonu: Sadece yüklü VE yeni güncellemesi bulunan uygulamalar için aktif olur
    if ($canUpgradeCount -gt 0) {
        $btnUpgrade.IsEnabled = $true
        $btnUpgrade.Content = "⚡ Güncelle ($canUpgradeCount)"
    } else {
        $btnUpgrade.IsEnabled = $false
        $btnUpgrade.Content = "Güncelle"
    }

    # 3. Kaldır Butonu: Sadece bilgisayarda gerçekten yüklü olan uygulamalar için aktif olur
    if ($canUninstallCount -gt 0) {
        $btnUninstall.IsEnabled = $true
        $btnUninstall.Content = "Kaldır ($canUninstallCount)"
    } else {
        $btnUninstall.IsEnabled = $false
        $btnUninstall.Content = "Kaldır"
    }

    # Akıllı durum özeti
    if ($canUpgradeCount -gt 0) {
        Set-Status "$count uygulama sırada ($canUpgradeCount yeni güncelleme mevcut)." "WARN"
    } elseif ($canInstallCount -gt 0 -and $canUninstallCount -eq 0) {
        Set-Status "$count uygulama sırada ($canInstallCount kurulabilir paket)." "OK"
    } elseif ($canUninstallCount -gt 0 -and $canInstallCount -eq 0) {
        Set-Status "$count uygulama sırada ($canUninstallCount kaldırılabilir yüklü paket)." "WARN"
    } else {
        Set-Status "$count uygulama sırada ($canInstallCount kurulabilir, $canUninstallCount kaldırılabilir)." "OK"
    }
}

## --- KAYNAK SEÇİM DİYALOĞU (MODERN & TERCİHİ HATIRLA DESTEKLİ) ---
function Show-SourceSelectDialog($app, $iconSource = $null) {
    $script:tempSelSource = $null

    $dlg = New-Object System.Windows.Window
    $dlg.Title = "$($app.Name) - Kurulum Kaynağı Seçimi"
    $dlg.Width = 490
    $dlg.Height = 295
    $dlg.WindowStartupLocation = "CenterScreen"
    $dlg.ResizeMode = "NoResize"
    $dlg.WindowStyle = "None"
    $dlg.AllowsTransparency = $true
    $dlg.Background = [System.Windows.Media.Brushes]::Transparent
    $dlg.ShowInTaskbar = $false
    $dlg.Topmost = $true
    try { $dlg.Resources = $window.Resources } catch {}

    $mainBorder = New-Object System.Windows.Controls.Border
    $mainBorder.CornerRadius = New-Object System.Windows.CornerRadius(14)
    $mainBorder.Background = if ($global:isDark) { Brush("#0F172A") } else { Brush("#FFFFFF") }
    $mainBorder.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $mainBorder.BorderThickness = New-Object System.Windows.Thickness(1.5)
    $mainBorder.Padding = New-Object System.Windows.Thickness(20, 18, 20, 16)

    $mainGrid = New-Object System.Windows.Controls.Grid
    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::Auto
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::Auto
    [void]$mainGrid.RowDefinitions.Add($r0); [void]$mainGrid.RowDefinitions.Add($r1); [void]$mainGrid.RowDefinitions.Add($r2)

    # 1. Başlık & Logo Alanı
    $headGrid = New-Object System.Windows.Controls.Grid
    $hCol0 = New-Object System.Windows.Controls.ColumnDefinition; $hCol0.Width = [System.Windows.GridLength]::Auto
    $hCol1 = New-Object System.Windows.Controls.ColumnDefinition; $hCol1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$headGrid.ColumnDefinitions.Add($hCol0); [void]$headGrid.ColumnDefinitions.Add($hCol1)

    $iconBox = New-Object System.Windows.Controls.Border
    $iconBox.Width = 38; $iconBox.Height = 38
    $iconBox.CornerRadius = New-Object System.Windows.CornerRadius(8)
    $iconBox.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#F1F5F9") }
    $iconBox.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $iconBox.BorderThickness = New-Object System.Windows.Thickness(1)
    $iconBox.Margin = New-Object System.Windows.Thickness(0, 0, 12, 0)

    $resolvedIcon = if ($iconSource) { $iconSource } else {
        $dUrl = if ($app.DirectUrl) { $app.DirectUrl } else { $app.IconUrl }
        Get-WpfIconSource $app.Slug $app.Domain $dUrl $app.Name
    }
    if ($resolvedIcon) {
        $icImg = New-Object System.Windows.Controls.Image
        $icImg.Width = 26; $icImg.Height = 26
        $icImg.Source = $resolvedIcon
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($icImg, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        $iconBox.Child = $icImg
    } else {
        $icFallback = New-Object System.Windows.Controls.TextBlock
        $icFallback.Text = if ($app.Name.Length -ge 1) { $app.Name.Substring(0,1).ToUpper() } else { "📦" }
        $icFallback.FontSize = 15; $icFallback.FontWeight = "Bold"
        $icFallback.HorizontalAlignment = "Center"; $icFallback.VerticalAlignment = "Center"
        $icFallback.Foreground = Brush("#38BDF8")
        $iconBox.Child = $icFallback
    }
    [System.Windows.Controls.Grid]::SetColumn($iconBox, 0)
    [void]$headGrid.Children.Add($iconBox)

    $tBox = New-Object System.Windows.Controls.StackPanel
    $tBox.VerticalAlignment = "Center"
    $tTitle = New-Object System.Windows.Controls.TextBlock
    $tTitle.Text = "$($app.Name) - Kurulum Kaynağı"
    $tTitle.FontWeight = "Bold"; $tTitle.FontSize = 13.5
    $tTitle.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    [void]$tBox.Children.Add($tTitle)

    $tSub = New-Object System.Windows.Controls.TextBlock
    $tSub.Text = "Bu uygulamayı standart web dağıtımı veya Microsoft Store ile kurabilirsiniz."
    $tSub.FontSize = 10.5
    $tSub.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    $tSub.Margin = New-Object System.Windows.Thickness(0, 1, 0, 0)
    [void]$tBox.Children.Add($tSub)
    [System.Windows.Controls.Grid]::SetColumn($tBox, 1)
    [void]$headGrid.Children.Add($tBox)

    [System.Windows.Controls.Grid]::SetRow($headGrid, 0)
    [void]$mainGrid.Children.Add($headGrid)

    # 2. Seçenek Kartları
    $optSp = New-Object System.Windows.Controls.StackPanel
    $optSp.Margin = New-Object System.Windows.Thickness(0, 12, 0, 10)
    [System.Windows.Controls.Grid]::SetRow($optSp, 1)
    [void]$mainGrid.Children.Add($optSp)

    # SEÇENEK 1: STANDART / NORMAL KURULUM (Web & Win32)
    $btnNormal = New-Object System.Windows.Controls.Border
    $btnNormal.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $btnNormal.Background = if ($global:isDark) { Brush("#131D2E") } else { Brush("#F0F9FF") }
    $btnNormal.BorderBrush = if ($global:isDark) { Brush("#1E3A8A") } else { Brush("#BAE6FD") }
    $btnNormal.BorderThickness = New-Object System.Windows.Thickness(1.2)
    $btnNormal.Padding = New-Object System.Windows.Thickness(12, 9, 12, 9)
    $btnNormal.Margin = New-Object System.Windows.Thickness(0, 0, 0, 8)
    $btnNormal.Cursor = "Hand"

    $nGrid = New-Object System.Windows.Controls.Grid
    $nCol0 = New-Object System.Windows.Controls.ColumnDefinition; $nCol0.Width = [System.Windows.GridLength]::Auto
    $nCol1 = New-Object System.Windows.Controls.ColumnDefinition; $nCol1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$nGrid.ColumnDefinitions.Add($nCol0); [void]$nGrid.ColumnDefinitions.Add($nCol1)

    $nIconBorder = New-Object System.Windows.Controls.Border
    $nIconBorder.Width = 34; $nIconBorder.Height = 34
    $nIconBorder.VerticalAlignment = "Center"
    $nIconBorder.Margin = New-Object System.Windows.Thickness(0, 0, 12, 0)

    # Temiz, imleçsiz 3D Fluent Dünya Logosu
    $webLogoFile = if (Test-Path "c:\projem\logolar\globe_with_meridians_3d.png") {
        "c:\projem\logolar\globe_with_meridians_3d.png"
    } elseif (Test-Path "c:\projem\logolar\modern_web_installer.png") {
        "c:\projem\logolar\modern_web_installer.png"
    } else {
        ""
    }

    $webLogoLoaded = $false
    if ($webLogoFile -and (Test-Path $webLogoFile)) {
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.UriSource = [Uri]$webLogoFile
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.EndInit()
            $bmp.Freeze()
            $nImg = New-Object System.Windows.Controls.Image
            $nImg.Width = 30; $nImg.Height = 30
            $nImg.Source = $bmp
            [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($nImg, [System.Windows.Media.BitmapScalingMode]::HighQuality)
            $nIconBorder.Child = $nImg
            $webLogoLoaded = $true
        } catch {}
    }
    if (-not $webLogoLoaded) {
        $nIcon = New-Object System.Windows.Controls.TextBlock
        $nIcon.Text = "🌐"; $nIcon.FontSize = 20; $nIcon.VerticalAlignment = "Center"
        $nIconBorder.Child = $nIcon
    }
    [System.Windows.Controls.Grid]::SetColumn($nIconBorder, 0)
    [void]$nGrid.Children.Add($nIconBorder)

    $nTexts = New-Object System.Windows.Controls.StackPanel
    $nTexts.VerticalAlignment = "Center"
    $nTitle = New-Object System.Windows.Controls.TextBlock
    $nTitle.Text = "Standart / Normal Kurulum (Web & Win32)"
    $nTitle.FontWeight = "Bold"; $nTitle.FontSize = 11.5
    $nTitle.Foreground = Brush("#38BDF8")
    [void]$nTexts.Children.Add($nTitle)
    $nDesc = New-Object System.Windows.Controls.TextBlock
    $nDesc.Text = "Resmi geliştirici sitesi ve WinGet paket deposu üzerinden kurulur."
    $nDesc.FontSize = 10
    $nDesc.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    [void]$nTexts.Children.Add($nDesc)
    [System.Windows.Controls.Grid]::SetColumn($nTexts, 1)
    [void]$nGrid.Children.Add($nTexts)
    $btnNormal.Child = $nGrid

    # SEÇENEK 2: MICROSOFT STORE KURULUMU (UWP / MSIX)
    $btnStore = New-Object System.Windows.Controls.Border
    $btnStore.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $btnStore.Background = if ($global:isDark) { Brush("#1F1833") } else { Brush("#FAF5FF") }
    $btnStore.BorderBrush = if ($global:isDark) { Brush("#6B21A8") } else { Brush("#E9D5FF") }
    $btnStore.BorderThickness = New-Object System.Windows.Thickness(1.2)
    $btnStore.Padding = New-Object System.Windows.Thickness(12, 9, 12, 9)
    $btnStore.Cursor = "Hand"

    $sGrid = New-Object System.Windows.Controls.Grid
    $sCol0 = New-Object System.Windows.Controls.ColumnDefinition; $sCol0.Width = [System.Windows.GridLength]::Auto
    $sCol1 = New-Object System.Windows.Controls.ColumnDefinition; $sCol1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$sGrid.ColumnDefinitions.Add($sCol0); [void]$sGrid.ColumnDefinitions.Add($sCol1)

    $sIconBorder = New-Object System.Windows.Controls.Border
    $sIconBorder.Width = 34; $sIconBorder.Height = 34
    $sIconBorder.VerticalAlignment = "Center"
    $sIconBorder.Margin = New-Object System.Windows.Thickness(0, 0, 12, 0)

    $storeLogoFile = if (Test-Path "c:\projem\logolar\microsoft_store.png") {
        "c:\projem\logolar\microsoft_store.png"
    } elseif (Test-Path "c:\projem\logolar\ms_store.png") {
        "c:\projem\logolar\ms_store.png"
    } else {
        ""
    }

    $storeLogoLoaded = $false
    if ($storeLogoFile -and (Test-Path $storeLogoFile)) {
        try {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.UriSource = [Uri]$storeLogoFile
            $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.EndInit()
            $bmp.Freeze()
            $sImg = New-Object System.Windows.Controls.Image
            $sImg.Width = 30; $sImg.Height = 30
            $sImg.Source = $bmp
            [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($sImg, [System.Windows.Media.BitmapScalingMode]::HighQuality)
            $sIconBorder.Child = $sImg
            $storeLogoLoaded = $true
        } catch {}
    }
    if (-not $storeLogoLoaded) {
        $sIcon = New-Object System.Windows.Controls.TextBlock
        $sIcon.Text = "🛍️"; $sIcon.FontSize = 20; $sIcon.VerticalAlignment = "Center"
        $sIconBorder.Child = $sIcon
    }
    [System.Windows.Controls.Grid]::SetColumn($sIconBorder, 0)
    [void]$sGrid.Children.Add($sIconBorder)

    $sTexts = New-Object System.Windows.Controls.StackPanel
    $sTexts.VerticalAlignment = "Center"
    $sTitle = New-Object System.Windows.Controls.TextBlock
    $sTitle.Text = "Microsoft Store Kurulumu (UWP / MSIX)"
    $sTitle.FontWeight = "Bold"; $sTitle.FontSize = 11.5
    $sTitle.Foreground = Brush("#C084FC")
    [void]$sTexts.Children.Add($sTitle)
    $sDesc = New-Object System.Windows.Controls.TextBlock
    $sDesc.Text = "Resmi Microsoft Mağazası entegrasyonuyla güvenli ve otomatik güncellemeli kurulur."
    $sDesc.FontSize = 10
    $sDesc.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    [void]$sTexts.Children.Add($sDesc)
    [System.Windows.Controls.Grid]::SetColumn($sTexts, 1)
    [void]$sGrid.Children.Add($sTexts)
    $btnStore.Child = $sGrid

    [void]$optSp.Children.Add($btnNormal)
    [void]$optSp.Children.Add($btnStore)

    # 3. Alt Satır: "Seçimimi Hatırla" Checkbox & Vazgeç Butonu
    $botGrid = New-Object System.Windows.Controls.Grid
    $bCol0 = New-Object System.Windows.Controls.ColumnDefinition; $bCol0.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $bCol1 = New-Object System.Windows.Controls.ColumnDefinition; $bCol1.Width = [System.Windows.GridLength]::Auto
    [void]$botGrid.ColumnDefinitions.Add($bCol0); [void]$botGrid.ColumnDefinitions.Add($bCol1)

    $chkRemember = New-Object System.Windows.Controls.CheckBox
    $chkRemember.Content = "Seçimimi hatırla (Bir daha sorma)"
    $chkRemember.FontSize = 11
    $chkRemember.FontWeight = "Medium"
    $chkRemember.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#475569") }
    $chkRemember.VerticalAlignment = "Center"
    $chkRemember.Cursor = "Hand"
    $remTooltip = New-Object System.Windows.Controls.ToolTip
    $remTooltip.Content = "İşaretlenirse, çift kaynaklı tüm uygulamalar otomatik olarak bu tercihle eklenir. Sağ paneldeki butonla tercihinizi istediğiniz an sıfırlayabilirsiniz."
    $remTooltip.Background = Brush("#0F172A")
    $remTooltip.Foreground = Brush("#38BDF8")
    $chkRemember.ToolTip = $remTooltip
    [System.Windows.Controls.Grid]::SetColumn($chkRemember, 0)
    [void]$botGrid.Children.Add($chkRemember)

    $btnCancel = New-Object System.Windows.Controls.Border
    $btnCancel.CornerRadius = New-Object System.Windows.CornerRadius(7)
    $btnCancel.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
    $btnCancel.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $btnCancel.BorderThickness = New-Object System.Windows.Thickness(1)
    $btnCancel.Padding = New-Object System.Windows.Thickness(16, 6, 16, 6)
    $btnCancel.Cursor = "Hand"
    $btnCancelTxt = New-Object System.Windows.Controls.TextBlock
    $btnCancelTxt.Text = "✕ İptal"
    $btnCancelTxt.FontSize = 11.5
    $btnCancelTxt.FontWeight = "SemiBold"
    $btnCancelTxt.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#475569") }
    $btnCancelTxt.HorizontalAlignment = "Center"
    $btnCancel.Child = $btnCancelTxt

    $btnCancel.Add_MouseEnter({
        param($s, $e)
        $s.Background = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    })
    $btnCancel.Add_MouseLeave({
        param($s, $e)
        $s.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
    })
    $btnCancel.Add_MouseLeftButtonUp({
        param($s, $e)
        $script:tempSelSource = $null
        $dlg.Close()
    })
    [System.Windows.Controls.Grid]::SetColumn($btnCancel, 1)
    [void]$botGrid.Children.Add($btnCancel)

    [System.Windows.Controls.Grid]::SetRow($botGrid, 2)
    [void]$mainGrid.Children.Add($botGrid)

    # Click Handlers with Remember logic
    $btnNormal.Add_MouseEnter({
        param($s, $e)
        $s.Background = if ($global:isDark) { Brush("#0C4A6E") } else { Brush("#BAE6FD") }
    })
    $btnNormal.Add_MouseLeave({
        param($s, $e)
        $s.Background = if ($global:isDark) { Brush("#131D2E") } else { Brush("#F0F9FF") }
    })
    $btnNormal.Add_MouseLeftButtonUp({
        param($s, $e)
        $script:tempSelSource = "Normal"
        if ($chkRemember.IsChecked) {
            $global:preferredInstallSource = "Normal"
            Save-UserSettings
            if (Get-Command Update-PrefSourceButton -ErrorAction SilentlyContinue) { Update-PrefSourceButton }
        }
        $dlg.Close()
    })

    $btnStore.Add_MouseEnter({
        param($s, $e)
        $s.Background = if ($global:isDark) { Brush("#4C1D95") } else { Brush("#E9D5FF") }
    })
    $btnStore.Add_MouseLeave({
        param($s, $e)
        $s.Background = if ($global:isDark) { Brush("#1F1833") } else { Brush("#FAF5FF") }
    })
    $btnStore.Add_MouseLeftButtonUp({
        param($s, $e)
        $script:tempSelSource = "Store"
        if ($chkRemember.IsChecked) {
            $global:preferredInstallSource = "Store"
            Save-UserSettings
            if (Get-Command Update-PrefSourceButton -ErrorAction SilentlyContinue) { Update-PrefSourceButton }
        }
        $dlg.Close()
    })

    $mainBorder.Child = $mainGrid
    $dlg.Content = $mainBorder

    [void]$dlg.ShowDialog()
    return $script:tempSelSource
}

function Update-CardSourceBadge($card, [string]$source) {
    if (-not $card -or -not $card.Tag) { return }
    $state = $card.Tag
    if (-not $state.SourceBadge -or -not $state.SourceBadgeText) { return }
    # Yuklu olan uygulamalarin rozeti kurulu gercek duruma gore kilitlidir, degistirilemez!
    if ($state.IsInstalled) { return }

    if ($source -eq "Store") {
        # Soft pastel purple / indigo
        $state.SourceBadge.Background = if ($global:isDark) { Brush("#2A2458") } else { Brush("#EDE9FE") }
        $state.SourceBadge.BorderBrush = if ($global:isDark) { Brush("#7C3AED") } else { Brush("#DDD6FE") }
        $state.SourceBadgeText.Text = "Store"
        $state.SourceBadgeText.Foreground = if ($global:isDark) { Brush("#D8B4FE") } else { Brush("#6D28D9") }
        if ($state.SourceBadgeImg -and $global:bmpStoreLogo) {
            $state.SourceBadgeImg.Source = $global:bmpStoreLogo
            $state.SourceBadgeImg.Visibility = [System.Windows.Visibility]::Visible
        }
    } else {
        # Soft pastel sky / cyan
        $state.SourceBadge.Background = if ($global:isDark) { Brush("#0C3247") } else { Brush("#E0F2FE") }
        $state.SourceBadge.BorderBrush = if ($global:isDark) { Brush("#0284C7") } else { Brush("#BAE6FD") }
        $state.SourceBadgeText.Text = "Normal"
        $state.SourceBadgeText.Foreground = if ($global:isDark) { Brush("#7DD3FC") } else { Brush("#0369A1") }
        if ($state.SourceBadgeImg -and $global:bmpGlobeLogo) {
            $state.SourceBadgeImg.Source = $global:bmpGlobeLogo
            $state.SourceBadgeImg.Visibility = [System.Windows.Visibility]::Visible
        }
    }
}

# --- SEÇİM MOTORU ---
function Toggle-CardSelection($card) {
    if (-not $card -or -not $card.Tag) { return }
    $state = $card.Tag
    $app = $state.App

    if (-not $state.IsSelected) {
        # YUKLU OLANLARDA: Kaynak secim diyalogu gosterilmez, degistirilemez!
        if (-not $state.IsInstalled) {
            $hasDualSource = ($app.HasDual -eq "1") -or ($app.StoreId -and ($app.NormalId -or $app.DownloadUrl))
            if ($hasDualSource) {
                if ($global:preferredInstallSource -eq "Normal") {
                    # Sag ustte Normal secildiyse sorulmadan Normal yap
                    $chosenSource = "Normal"
                    $app.SelectedSource = $chosenSource
                    Update-CardSourceBadge $card $chosenSource
                } elseif ($global:preferredInstallSource -eq "Store") {
                    # Sag ustte Store secildiyse sorulmadan Store yap
                    $chosenSource = "Store"
                    $app.SelectedSource = $chosenSource
                    Update-CardSourceBadge $card $chosenSource
                } else {
                    # Sag ustte 'Her Zaman Sor' aciksa: Resim 3'teki gibi Show-SourceSelectDialog sor!
                    $chosenSource = Show-SourceSelectDialog $app $state.IconSource
                    if (-not $chosenSource) { return }
                    $app.SelectedSource = $chosenSource
                    Update-CardSourceBadge $card $chosenSource
                }
            } else {
                $isPureStore = ($app.StoreOnly -eq "1") -or ($app.StoreId -and -not $app.NormalId) -or ($app.Id -match '^[A-Z0-9]{12,14}$')
                if ($isPureStore) {
                    $app.SelectedSource = "Store"
                } else {
                    $app.SelectedSource = "Normal"
                }
            }
        }

        $state.IsSelected = $true
        $card.Background = if ($global:isDark) { Brush("#1B293C") } else { Brush("#E0F2FE") }
        $card.BorderBrush = Brush("#38BDF8")
        $state.CheckBadge.Background = Brush("#38BDF8")
        $state.CheckMark.Foreground = Brush("#FFFFFF")
        $state.CheckMark.Visibility = [System.Windows.Visibility]::Visible
        if (!$global:selectedQueue.Contains($card)) {
            [void]$global:selectedQueue.Add($card)
        }
    } else {
        $state.IsSelected = $false
        $card.Background = if ($global:isDark) { Brush("#1A2332") } else { Brush("#EDF2F7") }
        $card.BorderBrush = if ($global:isDark) { Brush("#253246") } else { Brush("#CBD5E1") }
        $state.CheckBadge.Background = if ($global:isDark) { Brush("#253246") } else { Brush("#CBD5E1") }
        $state.CheckMark.Visibility = [System.Windows.Visibility]::Collapsed
        [void]$global:selectedQueue.Remove($card)
    }
    Render-QueuePanel
}

# --- KOMPAKT KART ---
function New-CompactAppCard($app) {
    $exePath = if ($app.ExePath) { $app.ExePath } else { "" }
    $regName = if ($app.RegistryName) { $app.RegistryName } else { "" }
    $isInstalled = Is-AppActuallyInstalled $app.Name $app.Id $exePath $regName
    $hasUpdate = Has-AppUpdate $app.Id
    $isStoreApp = ($app.StoreOnly -eq "1") -or ($app.StoreId -and -not $app.NormalId) -or (Is-StoreAppId $app.Id) -or ($app.StoreId -and (Is-StoreAppId $app.StoreId))

    $card = New-Object System.Windows.Controls.Border
    $card.Background = if ($global:isDark) { Brush("#1A2332") } else { Brush("#EDF2F7") }
    $card.BorderBrush = if ($global:isDark) { Brush("#253246") } else { Brush("#CBD5E1") }
    $card.BorderThickness = New-Object System.Windows.Thickness(1)
    $card.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $card.Margin = New-Object System.Windows.Thickness(4)
    $card.Padding = New-Object System.Windows.Thickness(8,6,8,6)
    $card.HorizontalAlignment = "Stretch"
    $card.Height = 64
    $card.Cursor = "Hand"

    # Grid: [logo(44)] [bilgi(*)] [ⓘ btn(22)] [check(24)]
    $grid = New-Object System.Windows.Controls.Grid
    $col0 = New-Object System.Windows.Controls.ColumnDefinition; $col0.Width = New-Object System.Windows.GridLength(44)
    $col1 = New-Object System.Windows.Controls.ColumnDefinition; $col1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $col2 = New-Object System.Windows.Controls.ColumnDefinition; $col2.Width = New-Object System.Windows.GridLength(22)
    $col3 = New-Object System.Windows.Controls.ColumnDefinition; $col3.Width = New-Object System.Windows.GridLength(24)
    [void]$grid.ColumnDefinitions.Add($col0)
    [void]$grid.ColumnDefinitions.Add($col1)
    [void]$grid.ColumnDefinitions.Add($col2)
    [void]$grid.ColumnDefinitions.Add($col3)

    # Logo
    $logoBorder = New-Object System.Windows.Controls.Border
    $logoBorder.Width = 36
    $logoBorder.Height = 36
    $logoBorder.CornerRadius = New-Object System.Windows.CornerRadius(8)
    $logoBorder.Background = if ($global:isDark) { Brush("#11161F") } else { Brush("#F1F5F9") }
    $logoBorder.VerticalAlignment = "Center"
    $logoBorder.HorizontalAlignment = "Left"

    $img = New-Object System.Windows.Controls.Image
    $img.Width = 24
    $img.Height = 24
    $img.HorizontalAlignment = "Center"
    $img.VerticalAlignment = "Center"
    [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::HighQuality)

    $directIconUrl = if ($app.DirectUrl) { $app.DirectUrl } else { $app.IconUrl }
    $iconBmp = Get-WpfIconSource $app.Slug $app.Domain $directIconUrl $app.Name
    if ($iconBmp) {
        $img.Source = $iconBmp
        $logoBorder.Child = $img
    } else {
        $fallback = New-Object System.Windows.Controls.TextBlock
        $fallback.Text = "📦"
        $fallback.FontSize = 14
        $fallback.HorizontalAlignment = "Center"
        $fallback.VerticalAlignment = "Center"
        $logoBorder.Child = $fallback
    }
    [System.Windows.Controls.Grid]::SetColumn($logoBorder, 0)
    [void]$grid.Children.Add($logoBorder)

    # Bilgi alanı (isim + badge)
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.VerticalAlignment = "Center"
    $stack.Margin = New-Object System.Windows.Thickness(2,0,2,0)

    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = $app.Name
    $title.FontSize = 11.5
    $title.FontWeight = "Bold"
    $title.Foreground = if ($isInstalled) { Brush("#22C55E") } elseif ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    $title.TextTrimming = "CharacterEllipsis"
    [void]$stack.Children.Add($title)

    # Ana durum badgesi + (Store uygulaması ise) store badgesi yan yana
    $badgeRow = New-Object System.Windows.Controls.StackPanel
    $badgeRow.Orientation = "Horizontal"
    $badgeRow.Margin = New-Object System.Windows.Thickness(0,2,0,0)

    $badge = New-Object System.Windows.Controls.Border
    $badge.CornerRadius = New-Object System.Windows.CornerRadius(4)
    $badge.HorizontalAlignment = "Left"
    $badge.Padding = New-Object System.Windows.Thickness(5,1,5,1)

    $badgeText = New-Object System.Windows.Controls.TextBlock
    $badgeText.FontSize = 8.5
    $badgeText.FontWeight = "Bold"

    if ($hasUpdate) {
        $badge.Background = if ($global:isDark) { Brush("#2A200B") } else { Brush("#FEF3C7") }
        $badgeText.Text = "Güncelleme Var"
        $badgeText.Foreground = if ($global:isDark) { Brush("#FBBF24") } else { Brush("#B45309") }
    } elseif ($isInstalled) {
        $badge.Background = if ($global:isDark) { Brush("#064E3B") } else { Brush("#DCFCE7") }
        $badgeText.Text = "Yüklü"
        $badgeText.Foreground = if ($global:isDark) { Brush("#34D399") } else { Brush("#15803D") }
    } else {
        $badge.Background = if ($global:isDark) { Brush("#1E2838") } else { Brush("#F1F5F9") }
        $badgeText.Text = "Hazır"
        $badgeText.Foreground = if ($global:isDark) { Brush("#8C9BB0") } else { Brush("#64748B") }
    }
    $badge.Child = $badgeText
    [void]$badgeRow.Children.Add($badge)

    # Kaynak Tespiti: Uygulama sistemde yuklu ise ne yuklu oldugunu tam tespit et
    $instSourceType = "None"
    if ($isInstalled) {
        $cleanSearch = $app.Name -replace '\s*', ''
        $hasStoreInst = $false
        if ($app.StoreId -or $app.StoreOnly -eq "1" -or ($app.HasDual -eq "1")) {
            $storePkg = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { 
                ($_.Name -like "*$cleanSearch*") -or 
                ($app.StoreId -and $_.PackageFamilyName -like "*$($app.StoreId)*") 
            } | Select-Object -First 1
            if ($storePkg) { $hasStoreInst = $true }
        }
        $nativeCmd = Get-AppUninstallCommand $app.Name $app.Id
        $exeExists = $false
        if ($app.ExePath) {
            try { if (Test-Path $app.ExePath) { $exeExists = $true } } catch {}
        }
        $hasNormalInst = ($nativeCmd -ne $null -and $nativeCmd.Cmd) -or $exeExists -or ($global:verifiedInstalledIds.Contains($app.Id))
        
        if ($hasStoreInst -and $hasNormalInst) {
            $instSourceType = "Both"
        } elseif ($hasStoreInst) {
            $instSourceType = "Store"
        } elseif ($hasNormalInst) {
            $instSourceType = "Normal"
        } else {
            $instSourceType = if ($isStoreApp) { "Store" } else { "Normal" }
        }
    }

    # Çift Kaynak (Store ve Normal) Seçim Rozeti veya Store Rozeti
    $hasDualSource = ($app.HasDual -eq "1") -or ($app.StoreId -and ($app.NormalId -or $app.DownloadUrl))
    if ($hasDualSource -and -not $isInstalled) {
        $app.SelectedSource = if ($global:preferredInstallSource -eq "Store") { "Store" } else { "Normal" }
    }

    $sourceBadge = $null
    $sourceBadgeText = $null

    # 1. EGER YUKLU ISE: Ne yuklu ise o gozukur ve degistirilemez! (Normal, Store veya 2'si birden)
    if ($isInstalled) {
        $sourceBadge = New-Object System.Windows.Controls.Border
        $sourceBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $sourceBadge.HorizontalAlignment = "Left"
        $sourceBadge.Padding = New-Object System.Windows.Thickness(5,1,6,1)
        $sourceBadge.Margin = New-Object System.Windows.Thickness(4,0,0,0)
        $sourceBadge.BorderThickness = New-Object System.Windows.Thickness(1)
        $sourceBadge.Cursor = "Arrow" # Degistirilemez kilitli imlec

        $sbSp = New-Object System.Windows.Controls.StackPanel
        $sbSp.Orientation = "Horizontal"
        $sbSp.VerticalAlignment = "Center"

        $sourceBadgeImg = New-Object System.Windows.Controls.Image
        $sourceBadgeImg.Width = 12; $sourceBadgeImg.Height = 12
        $sourceBadgeImg.Margin = New-Object System.Windows.Thickness(0,0,4,0)
        $sourceBadgeImg.VerticalAlignment = "Center"
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($sourceBadgeImg, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        [void]$sbSp.Children.Add($sourceBadgeImg)

        $sourceBadgeText = New-Object System.Windows.Controls.TextBlock
        $sourceBadgeText.FontSize = 8.5
        $sourceBadgeText.FontWeight = "Bold"
        $sourceBadgeText.VerticalAlignment = "Center"
        [void]$sbSp.Children.Add($sourceBadgeText)
        $sourceBadge.Child = $sbSp

        if ($instSourceType -eq "Both") {
            # Her ikisi de yuklu!
            $app.SelectedSource = "Both"
            $sourceBadge.Background = if ($global:isDark) { Brush("#1F2937") } else { Brush("#F1F5F9") }
            $sourceBadge.BorderBrush = if ($global:isDark) { Brush("#475569") } else { Brush("#CBD5E1") }
            $sourceBadgeText.Text = "Normal + Store"
            $sourceBadgeText.Foreground = if ($global:isDark) { Brush("#E2E8F0") } else { Brush("#334155") }
            if ($global:bmpGlobeLogo) { $sourceBadgeImg.Source = $global:bmpGlobeLogo }
            
            $srcTt = New-Object System.Windows.Controls.ToolTip
            $srcTt.Content = "Kurulu Durum: Bu uygulamanın hem Standart (Web) hem de Microsoft Store sürümü bilgisayarınızda yüklüdür."
            $srcTt.Background = Brush("#0F172A"); $srcTt.Foreground = Brush("#F8FAFC")
            $sourceBadge.ToolTip = $srcTt
        } elseif ($instSourceType -eq "Store") {
            # Sadece Store yuklu!
            $app.SelectedSource = "Store"
            $sourceBadge.Background = if ($global:isDark) { Brush("#2A2458") } else { Brush("#EDE9FE") }
            $sourceBadge.BorderBrush = if ($global:isDark) { Brush("#7C3AED") } else { Brush("#DDD6FE") }
            $sourceBadgeText.Text = "Store"
            $sourceBadgeText.Foreground = if ($global:isDark) { Brush("#D8B4FE") } else { Brush("#6D28D9") }
            if ($global:bmpStoreLogo) { $sourceBadgeImg.Source = $global:bmpStoreLogo }
            
            $srcTt = New-Object System.Windows.Controls.ToolTip
            $srcTt.Content = "Kurulu Durum: Bu uygulamanın Microsoft Store sürümü bilgisayarınızda yüklüdür."
            $srcTt.Background = Brush("#0F172A"); $srcTt.Foreground = Brush("#C084FC")
            $sourceBadge.ToolTip = $srcTt
        } else {
            # Sadece Normal yuklu!
            $app.SelectedSource = "Normal"
            $sourceBadge.Background = if ($global:isDark) { Brush("#0C3247") } else { Brush("#E0F2FE") }
            $sourceBadge.BorderBrush = if ($global:isDark) { Brush("#0284C7") } else { Brush("#BAE6FD") }
            $sourceBadgeText.Text = "Normal"
            $sourceBadgeText.Foreground = if ($global:isDark) { Brush("#7DD3FC") } else { Brush("#0369A1") }
            if ($global:bmpGlobeLogo) { $sourceBadgeImg.Source = $global:bmpGlobeLogo }
            
            $srcTt = New-Object System.Windows.Controls.ToolTip
            $srcTt.Content = "Kurulu Durum: Bu uygulamanın standart masaüstü (Web) sürümü bilgisayarınızda yüklüdür."
            $srcTt.Background = Brush("#0F172A"); $srcTt.Foreground = Brush("#38BDF8")
            $sourceBadge.ToolTip = $srcTt
        }

        # Tiklandiginda degistirilemez! (Kilitli)
        $sourceBadge.Add_MouseLeftButtonUp({ param($sb, $ev) $ev.Handled = $true })
        [void]$badgeRow.Children.Add($sourceBadge)

    } elseif ($hasDualSource) {
        # 2. YUKLU DEGILSE VE CIFT KAYNAKLI ISE: Normal veya Store secilebilir
        $sourceBadge = New-Object System.Windows.Controls.Border
        $sourceBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $sourceBadge.HorizontalAlignment = "Left"
        $sourceBadge.Padding = New-Object System.Windows.Thickness(5,1,6,1)
        $sourceBadge.Margin = New-Object System.Windows.Thickness(4,0,0,0)
        $sourceBadge.BorderThickness = New-Object System.Windows.Thickness(1)
        $sourceBadge.Cursor = "Hand"

        $sbSp = New-Object System.Windows.Controls.StackPanel
        $sbSp.Orientation = "Horizontal"
        $sbSp.VerticalAlignment = "Center"

        $sourceBadgeImg = New-Object System.Windows.Controls.Image
        $sourceBadgeImg.Width = 12; $sourceBadgeImg.Height = 12
        $sourceBadgeImg.Margin = New-Object System.Windows.Thickness(0,0,4,0)
        $sourceBadgeImg.VerticalAlignment = "Center"
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($sourceBadgeImg, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        [void]$sbSp.Children.Add($sourceBadgeImg)

        $sourceBadgeText = New-Object System.Windows.Controls.TextBlock
        $sourceBadgeText.FontSize = 8.5
        $sourceBadgeText.FontWeight = "Bold"
        $sourceBadgeText.VerticalAlignment = "Center"
        [void]$sbSp.Children.Add($sourceBadgeText)
        $sourceBadge.Child = $sbSp

        if (-not $app.SelectedSource) {
            $app.SelectedSource = "Normal"
        }

        if ($app.SelectedSource -eq "Store") {
            $sourceBadge.Background = if ($global:isDark) { Brush("#2A2458") } else { Brush("#EDE9FE") }
            $sourceBadge.BorderBrush = if ($global:isDark) { Brush("#7C3AED") } else { Brush("#DDD6FE") }
            $sourceBadgeText.Text = "Store"
            $sourceBadgeText.Foreground = if ($global:isDark) { Brush("#D8B4FE") } else { Brush("#6D28D9") }
            if ($global:bmpStoreLogo) { $sourceBadgeImg.Source = $global:bmpStoreLogo }
        } else {
            $sourceBadge.Background = if ($global:isDark) { Brush("#0C3247") } else { Brush("#E0F2FE") }
            $sourceBadge.BorderBrush = if ($global:isDark) { Brush("#0284C7") } else { Brush("#BAE6FD") }
            $sourceBadgeText.Text = "Normal"
            $sourceBadgeText.Foreground = if ($global:isDark) { Brush("#7DD3FC") } else { Brush("#0369A1") }
            if ($global:bmpGlobeLogo) { $sourceBadgeImg.Source = $global:bmpGlobeLogo }
        }

        $sourceBadge.Tag = @{ App = $app; Card = $card }
        $sourceBadge.Add_MouseLeftButtonUp({
            param($sb, $ev)
            $ev.Handled = $true
            $targetApp = $sb.Tag.App
            $targetCard = $sb.Tag.Card
            if ($targetApp.SelectedSource -eq "Store") {
                $targetApp.SelectedSource = "Normal"
            } else {
                $targetApp.SelectedSource = "Store"
            }
            Update-CardSourceBadge $targetCard $targetApp.SelectedSource
            Render-QueuePanel
        })

        $srcTt = New-Object System.Windows.Controls.ToolTip
        $srcTt.Content = "Kurulum Kaynağı: Normal (Web) veya Microsoft Store arasında seçim yapabilirsiniz. Değiştirmek için tıklayın."
        $srcTt.Background = Brush("#0F172A")
        $srcTt.Foreground = Brush("#38BDF8")
        $sourceBadge.ToolTip = $srcTt

        [void]$badgeRow.Children.Add($sourceBadge)

    } elseif ($isStoreApp) {
        # 3. YUKLU DEGILSE VE SADECE STORE ISE
        $storeBadge = New-Object System.Windows.Controls.Border
        $storeBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $storeBadge.HorizontalAlignment = "Left"
        $storeBadge.Padding = New-Object System.Windows.Thickness(5,1,6,1)
        $storeBadge.Margin = New-Object System.Windows.Thickness(4,0,0,0)
        $storeBadge.Background = if ($global:isDark) { Brush("#2A2458") } else { Brush("#EDE9FE") }
        $storeBadge.BorderBrush = if ($global:isDark) { Brush("#7C3AED") } else { Brush("#DDD6FE") }
        $storeBadge.BorderThickness = New-Object System.Windows.Thickness(1)
        $storeBadge.Cursor = "Hand"

        $sbStoreSp = New-Object System.Windows.Controls.StackPanel
        $sbStoreSp.Orientation = "Horizontal"
        $sbStoreSp.VerticalAlignment = "Center"

        $sbStoreImg = New-Object System.Windows.Controls.Image
        $sbStoreImg.Width = 12; $sbStoreImg.Height = 12
        $sbStoreImg.Margin = New-Object System.Windows.Thickness(0,0,4,0)
        $sbStoreImg.VerticalAlignment = "Center"
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($sbStoreImg, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        if ($global:bmpStoreLogo) { $sbStoreImg.Source = $global:bmpStoreLogo }
        [void]$sbStoreSp.Children.Add($sbStoreImg)

        $storeBadgeText = New-Object System.Windows.Controls.TextBlock
        $storeBadgeText.Text = "Sadece Store"
        $storeBadgeText.FontSize = 8.5
        $storeBadgeText.FontWeight = "Bold"
        $storeBadgeText.Foreground = if ($global:isDark) { Brush("#D8B4FE") } else { Brush("#6D28D9") }
        $storeBadgeText.VerticalAlignment = "Center"
        [void]$sbStoreSp.Children.Add($storeBadgeText)
        $storeBadge.Child = $sbStoreSp

        $storeTt = New-Object System.Windows.Controls.ToolTip
        $storeTt.Content = "Bu uygulama doğrudan Microsoft Store üzerinden kurulacaktır."
        $storeTt.Background = Brush("#0F172A")
        $storeTt.Foreground = Brush("#818CF8")
        $storeBadge.ToolTip = $storeTt

        [void]$badgeRow.Children.Add($storeBadge)
    }

    [void]$stack.Children.Add($badgeRow)
    [System.Windows.Controls.Grid]::SetColumn($stack, 1)
    [void]$grid.Children.Add($stack)

    # ⓘ Info butonu (tüm kartlarda)
    $infoBtn = New-Object System.Windows.Controls.Border
    $infoBtn.Width = 18
    $infoBtn.Height = 18
    $infoBtn.CornerRadius = New-Object System.Windows.CornerRadius(9)
    $infoBtn.Background = if ($global:isDark) { Brush("#1E3A5F") } else { Brush("#BFDBFE") }
    $infoBtn.VerticalAlignment = "Center"
    $infoBtn.HorizontalAlignment = "Center"
    $infoBtn.Cursor = "Hand"
    $infoBtn.Margin = New-Object System.Windows.Thickness(0,0,3,0)

    $infoTxt = New-Object System.Windows.Controls.TextBlock
    $infoTxt.Text = "i"
    $infoTxt.FontSize = 9.5
    $infoTxt.FontWeight = "Bold"
    $infoTxt.FontStyle = "Italic"
    $infoTxt.HorizontalAlignment = "Center"
    $infoTxt.VerticalAlignment = "Center"
    $infoTxt.Foreground = if ($global:isDark) { Brush("#60A5FA") } else { Brush("#1D4ED8") }
    $infoBtn.Child = $infoTxt

    # Değişkenleri Tag içine koy (closure sorununun kesin çözümü)
    $infoBtn.Tag = @{
        App       = $app
        IsStore   = $isStoreApp
        IsInst    = $isInstalled
        StoreId   = $app.Id
        IconSrc   = $img.Source
    }

    $infoBtn.Add_MouseLeftButtonUp({
        param($s, $ev)
        $ev.Handled = $true

        # Tag'dan değerleri oku
                $tagData     = $s.Tag
        $tApp        = $tagData.App
        $tIsStore    = $tagData.IsStore
        $tIsInst     = $tagData.IsInst
        $tStoreId    = $tagData.StoreId

        $kb = if ($global:appKnowledgeBase -and $global:appKnowledgeBase.ContainsKey($tApp.Name)) {
            $global:appKnowledgeBase[$tApp.Name]
        } else { $null }

        $catName = if ($global:categoryHeaders -and $tApp.Cat -and $global:categoryHeaders.ContainsKey($tApp.Cat)) {
            $global:categoryHeaders[$tApp.Cat]
        } else { "Genel Uygulama" }

        $infoWin = New-Object System.Windows.Window
        $infoWin.Title = $tApp.Name + " - Uygulama Detayli Bilgisi"
        $infoWin.Width = 530
        $infoWin.Height = 620
        $infoWin.WindowStartupLocation = "CenterScreen"
        $infoWin.ResizeMode = "NoResize"
        $infoWin.WindowStyle = "ToolWindow"
        $infoWin.Background = if ($global:isDark) { Brush("#0B0F17") } else { Brush("#FFFFFF") }
        $infoWin.Foreground = if ($global:isDark) { Brush("#F3F4F6") } else { Brush("#0F172A") }

        $gridMain = New-Object System.Windows.Controls.Grid
        $rowScroll = New-Object System.Windows.Controls.RowDefinition; $rowScroll.Height = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $rowAction = New-Object System.Windows.Controls.RowDefinition; $rowAction.Height = [System.Windows.GridLength]::Auto
        [void]$gridMain.RowDefinitions.Add($rowScroll); [void]$gridMain.RowDefinitions.Add($rowAction)

        $scroller = New-Object System.Windows.Controls.ScrollViewer
        $scroller.VerticalScrollBarVisibility = "Auto"
        $scroller.HorizontalScrollBarVisibility = "Disabled"
        $scroller.Margin = New-Object System.Windows.Thickness(20, 16, 20, 8)
        [System.Windows.Controls.Grid]::SetRow($scroller, 0)
        [void]$gridMain.Children.Add($scroller)

        $isp = New-Object System.Windows.Controls.StackPanel
        $scroller.Content = $isp

        # Header Grid: Logo (sol) + Isim ve Rozetler (sag)
        $headerGrid = New-Object System.Windows.Controls.Grid
        $hColLogo = New-Object System.Windows.Controls.ColumnDefinition; $hColLogo.Width = [System.Windows.GridLength]::Auto
        $hColText = New-Object System.Windows.Controls.ColumnDefinition; $hColText.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        [void]$headerGrid.ColumnDefinitions.Add($hColLogo); [void]$headerGrid.ColumnDefinitions.Add($hColText)

        $logoBorder = New-Object System.Windows.Controls.Border
        $logoBorder.Width = 48; $logoBorder.Height = 48
        $logoBorder.CornerRadius = New-Object System.Windows.CornerRadius(10)
        $logoBorder.Background = if ($global:isDark) { Brush("#131B26") } else { Brush("#F1F5F9") }
        $logoBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#CBD5E1") }
        $logoBorder.BorderThickness = New-Object System.Windows.Thickness(1)
        $logoBorder.Margin = New-Object System.Windows.Thickness(0, 0, 14, 0)

        $directIconUrl = if ($tApp.DirectUrl) { $tApp.DirectUrl } else { $tApp.IconUrl }
        $appIconSrc = if ($tagData.IconSrc) { $tagData.IconSrc } else {
            Get-WpfIconSource $tApp.Slug $tApp.Domain $directIconUrl $tApp.Name
        }
        if ($appIconSrc) {
            $logoImg = New-Object System.Windows.Controls.Image
            $logoImg.Width = 34; $logoImg.Height = 34
            $logoImg.Source = $appIconSrc
            $logoBorder.Child = $logoImg
        } else {
            $fallback = New-Object System.Windows.Controls.TextBlock
            $fallback.Text = if ($tApp.Name.Length -ge 1) { $tApp.Name.Substring(0,1).ToUpper() } else { "-" }
            $fallback.FontSize = 18; $fallback.FontWeight = "Bold"
            $fallback.HorizontalAlignment = "Center"; $fallback.VerticalAlignment = "Center"
            $fallback.Foreground = Brush("#38BDF8")
            $logoBorder.Child = $fallback
        }
        [System.Windows.Controls.Grid]::SetColumn($logoBorder, 0)
        [void]$headerGrid.Children.Add($logoBorder)

        $headTextSp = New-Object System.Windows.Controls.StackPanel
        [System.Windows.Controls.Grid]::SetColumn($headTextSp, 1)

        $iTitle = New-Object System.Windows.Controls.TextBlock
        $iTitle.Text = $tApp.Name
        $iTitle.FontSize = 16.5
        $iTitle.FontWeight = "Bold"
        $iTitle.Foreground = if ($global:isDark) { Brush("#60A5FA") } else { Brush("#1D4ED8") }
        [void]$headTextSp.Children.Add($iTitle)

        $badgeSp = New-Object System.Windows.Controls.WrapPanel
        $badgeSp.Margin = New-Object System.Windows.Thickness(0, 4, 0, 0)

        # Durum rozeti
        $statusBadge = New-Object System.Windows.Controls.Border
        $statusBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $statusBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
        $statusBadge.Margin = New-Object System.Windows.Thickness(0, 0, 6, 4)
        $statusBadge.Background = if ($tIsInst) { if ($global:isDark) { Brush("#064E3B") } else { Brush("#DCFCE7") } } else { if ($global:isDark) { Brush("#1F2937") } else { Brush("#F1F5F9") } }
        $statusTxt = New-Object System.Windows.Controls.TextBlock
        $statusTxt.Text = if ($tIsInst) { "$([char]0x25CF) Bilgisayarinizda Yuklu" } else { "$([char]0x25CB) Kurulu Degil" }
        $statusTxt.FontSize = 10; $statusTxt.FontWeight = "Bold"
        $statusTxt.Foreground = if ($tIsInst) { if ($global:isDark) { Brush("#34D399") } else { Brush("#16A34A") } } else { Brush("#9CA3AF") }
        $statusBadge.Child = $statusTxt
        [void]$badgeSp.Children.Add($statusBadge)

        # Kategori rozeti
        $catBadge = New-Object System.Windows.Controls.Border
        $catBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $catBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
        $catBadge.Margin = New-Object System.Windows.Thickness(0, 0, 6, 4)
        $catBadge.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
        $catTxt = New-Object System.Windows.Controls.TextBlock
        $catTxt.Text = $catName
        $catTxt.FontSize = 10; $catTxt.FontWeight = "SemiBold"
        $catTxt.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#475569") }
        $catBadge.Child = $catTxt
        [void]$badgeSp.Children.Add($catBadge)

        # Store rozeti
        if ($tIsStore -or $tApp.StoreId) {
            $storeBadge = New-Object System.Windows.Controls.Border
            $storeBadge.CornerRadius = New-Object System.Windows.CornerRadius(4)
            $storeBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
            $storeBadge.Margin = New-Object System.Windows.Thickness(0, 0, 6, 4)
            $storeBadge.Background = if ($global:isDark) { Brush("#2E1065") } else { Brush("#EDE9FE") }
            $storeTxt = New-Object System.Windows.Controls.TextBlock
            $storeTxt.Text = "MS Store"
            $storeTxt.FontSize = 10; $storeTxt.FontWeight = "Bold"
            $storeTxt.Foreground = if ($global:isDark) { Brush("#C084FC") } else { Brush("#7C3AED") }
            $storeBadge.Child = $storeTxt
            [void]$badgeSp.Children.Add($storeBadge)
        }

        [void]$headTextSp.Children.Add($badgeSp)
        [void]$headerGrid.Children.Add($headTextSp)
        [void]$isp.Children.Add($headerGrid)

        # Ayirici cizgi
        $div = New-Object System.Windows.Controls.Border
        $div.Height = 1
        $div.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
        $div.Margin = New-Object System.Windows.Thickness(0, 12, 0, 12)
        [void]$isp.Children.Add($div)

        # NE ISE YARAR Karti
        $descBorder = New-Object System.Windows.Controls.Border
        $descBorder.Background = if ($global:isDark) { Brush("#131B26") } else { Brush("#F8FAFC") }
        $descBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
        $descBorder.BorderThickness = New-Object System.Windows.Thickness(1)
        $descBorder.CornerRadius = New-Object System.Windows.CornerRadius(8)
        $descBorder.Padding = New-Object System.Windows.Thickness(14, 12, 14, 12)
        $descBorder.Margin = New-Object System.Windows.Thickness(0, 0, 0, 10)

        $descInner = New-Object System.Windows.Controls.StackPanel
        $descLbl = New-Object System.Windows.Controls.TextBlock
        $descLbl.Text = "NE ISE YARAR? (DETAYLI ACIKLAMA)"
        $descLbl.FontSize = 9.5; $descLbl.FontWeight = "Bold"
        $descLbl.Foreground = Brush("#38BDF8")
        $descLbl.Margin = New-Object System.Windows.Thickness(0, 0, 0, 6)
        [void]$descInner.Children.Add($descLbl)

        $fullDetails = if ($kb -and $kb.Details) { $kb.Details } elseif ($tApp.Desc) { $tApp.Desc } else { "Bu uygulama hakkinda detayli aciklama bulunmuyor." }
        $descContent = New-Object System.Windows.Controls.TextBlock
        $descContent.Text = $fullDetails
        $descContent.FontSize = 11.5
        $descContent.LineHeight = 18
        $descContent.Foreground = if ($global:isDark) { Brush("#E2E8F0") } else { Brush("#1E293B") }
        $descContent.TextWrapping = "Wrap"
        [void]$descInner.Children.Add($descContent)
        $descBorder.Child = $descInner
        [void]$isp.Children.Add($descBorder)

        # ONE CIKAN OZELLIKLER Karti
        if ($kb -and $kb.Features -and $kb.Features.Count -gt 0) {
            $featBorder = New-Object System.Windows.Controls.Border
            $featBorder.Background = if ($global:isDark) { Brush("#131B26") } else { Brush("#F8FAFC") }
            $featBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
            $featBorder.BorderThickness = New-Object System.Windows.Thickness(1)
            $featBorder.CornerRadius = New-Object System.Windows.CornerRadius(8)
            $featBorder.Padding = New-Object System.Windows.Thickness(14, 12, 14, 12)
            $featBorder.Margin = New-Object System.Windows.Thickness(0, 0, 0, 10)

            $featInner = New-Object System.Windows.Controls.StackPanel
            $featLbl = New-Object System.Windows.Controls.TextBlock
            $featLbl.Text = "ONE CIKAN OZELLIKLER VE KULLANIM ALANLARI"
            $featLbl.FontSize = 9.5; $featLbl.FontWeight = "Bold"
            $featLbl.Foreground = Brush("#10B981")
            $featLbl.Margin = New-Object System.Windows.Thickness(0, 0, 0, 8)
            [void]$featInner.Children.Add($featLbl)

            foreach ($feat in $kb.Features) {
                $fRow = New-Object System.Windows.Controls.Grid
                $fColBullet = New-Object System.Windows.Controls.ColumnDefinition; $fColBullet.Width = [System.Windows.GridLength]::Auto
                $fColText = New-Object System.Windows.Controls.ColumnDefinition; $fColText.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
                [void]$fRow.ColumnDefinitions.Add($fColBullet); [void]$fRow.ColumnDefinitions.Add($fColText)
                $fRow.Margin = New-Object System.Windows.Thickness(0, 0, 0, 5)

                $fBullet = New-Object System.Windows.Controls.TextBlock
                $fBullet.Text = "- "
                $fBullet.FontSize = 13; $fBullet.FontWeight = "Bold"
                $fBullet.Foreground = Brush("#10B981")
                [System.Windows.Controls.Grid]::SetColumn($fBullet, 0)
                [void]$fRow.Children.Add($fBullet)

                $fTxt = New-Object System.Windows.Controls.TextBlock
                $fTxt.Text = $feat
                $fTxt.FontSize = 11; $fTxt.TextWrapping = "Wrap"
                $fTxt.Foreground = if ($global:isDark) { Brush("#CBD5E1") } else { Brush("#334155") }
                [System.Windows.Controls.Grid]::SetColumn($fTxt, 1)
                [void]$fRow.Children.Add($fTxt)

                [void]$featInner.Children.Add($fRow)
            }
            $featBorder.Child = $featInner
            [void]$isp.Children.Add($featBorder)
        }

        # PAKET VE SISTEM BILGILERI Karti
        $metaBorder = New-Object System.Windows.Controls.Border
        $metaBorder.Background = if ($global:isDark) { Brush("#101722") } else { Brush("#F1F5F9") }
        $metaBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
        $metaBorder.BorderThickness = New-Object System.Windows.Thickness(1)
        $metaBorder.CornerRadius = New-Object System.Windows.CornerRadius(8)
        $metaBorder.Padding = New-Object System.Windows.Thickness(14, 10, 14, 10)
        $metaBorder.Margin = New-Object System.Windows.Thickness(0, 0, 0, 8)

        $metaSp = New-Object System.Windows.Controls.StackPanel

        $idVal = if ($tApp.Id) { $tApp.Id } else { "-" }
        $idLine = New-Object System.Windows.Controls.TextBlock
        $idLine.FontSize = 10.5
        $idLine.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
        $idLine.Text = "Paket Kimligi: " + $idVal
        [void]$metaSp.Children.Add($idLine)

        if ($tApp.Domain) {
            $domLine = New-Object System.Windows.Controls.TextBlock
            $domLine.FontSize = 10.5
            $domLine.Foreground = if ($global:isDark) { Brush("#38BDF8") } else { Brush("#0284C7") }
            $domLine.Margin = New-Object System.Windows.Thickness(0, 3, 0, 0)
            $domLine.Text = "Resmi Web: https://" + $tApp.Domain
            [void]$metaSp.Children.Add($domLine)
        }

        $metaBorder.Child = $metaSp
        [void]$isp.Children.Add($metaBorder)

        # Alt Sabit Aksiyon Bar
        $footerBorder = New-Object System.Windows.Controls.Border
        $footerBorder.Background = if ($global:isDark) { Brush("#0E141E") } else { Brush("#F8FAFC") }
        $footerBorder.BorderBrush = if ($global:isDark) { Brush("#1F2937") } else { Brush("#E2E8F0") }
        $footerBorder.BorderThickness = New-Object System.Windows.Thickness(0, 1, 0, 0)
        $footerBorder.Padding = New-Object System.Windows.Thickness(20, 10, 20, 12)
        [System.Windows.Controls.Grid]::SetRow($footerBorder, 1)
        [void]$gridMain.Children.Add($footerBorder)

        $footerSp = New-Object System.Windows.Controls.StackPanel
        $footerBorder.Child = $footerSp

        $actualStoreId = if ($tApp.StoreId) { $tApp.StoreId } elseif ($tIsStore) { $tStoreId } else { $null }
        $hasNormalOption = $tApp.NormalId -or $tApp.DownloadUrl -or (-not $tIsStore)

        # 1. Normal / Web Indirme Butonu
        if ($hasNormalOption) {
            $iNormalBtn = New-Object System.Windows.Controls.Button
            $iNormalBtn.Content = "Normal / Web Kaynagindan Kur"
            $iNormalBtn.Height = 34
            $iNormalBtn.FontSize = 11
            $iNormalBtn.FontWeight = "Bold"
            $iNormalBtn.Background = Brush("#0F3A5D")
            $iNormalBtn.Foreground = Brush("#38BDF8")
            $iNormalBtn.BorderThickness = New-Object System.Windows.Thickness(0)
            $iNormalBtn.Cursor = "Hand"
            $iNormalBtn.Margin = New-Object System.Windows.Thickness(0, 0, 0, 6)
            $iNormalBtn.Template = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="16"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>')
            
            $iNormalBtn.Tag = @{ WinRef = $infoWin; App = $tApp }
            $iNormalBtn.Add_Click({
                param($nb, $ne)
                $data = $nb.Tag
                $curApp = $data.App
                if ($curApp.DownloadUrl) {
                    Start-Process $curApp.DownloadUrl
                } elseif ($curApp.NormalId) {
                    Start-Process -FilePath $global:wingetExe -ArgumentList "install --id $($curApp.NormalId) --accept-source-agreements --accept-package-agreements"
                } elseif ($curApp.Id) {
                    Start-Process -FilePath $global:wingetExe -ArgumentList "install --id $($curApp.Id) --accept-source-agreements --accept-package-agreements"
                }
                $data.WinRef.Close()
            })
            [void]$footerSp.Children.Add($iNormalBtn)
        }

        # 2. Microsoft Store Butonu
        if ($actualStoreId) {
            $iStoreBtn = New-Object System.Windows.Controls.Button
            $iStoreBtn.Content = "Microsoft Store'dan Ac ve Indir"
            $iStoreBtn.Height = 34
            $iStoreBtn.FontSize = 11
            $iStoreBtn.FontWeight = "Bold"
            $iStoreBtn.Background = Brush("#312E81")
            $iStoreBtn.Foreground = Brush("#FFFFFF")
            $iStoreBtn.BorderThickness = New-Object System.Windows.Thickness(0)
            $iStoreBtn.Cursor = "Hand"
            $iStoreBtn.Margin = New-Object System.Windows.Thickness(0, 0, 0, 6)
            $iStoreBtn.Template = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="16"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>')
            
            $iStoreBtn.Tag = @{ WinRef = $infoWin; SID = $actualStoreId }
            $iStoreBtn.Add_Click({
                param($sb, $se)
                $d = $sb.Tag
                try { Start-Process "ms-windows-store://pdp/?ProductId=$($d.SID)" }
                catch { Start-Process "https://www.microsoft.com/store/apps/$($d.SID)" }
                $d.WinRef.Close()
            })
            [void]$footerSp.Children.Add($iStoreBtn)
        }

        # Hover efektleri: Normal ve Store butonlari
        if ($iNormalBtn) {
            $iNormalBtn.Add_MouseEnter({ param($s,$e) $s.Background = Brush("#0284C7") })
            $iNormalBtn.Add_MouseLeave({ param($s,$e) $s.Background = Brush("#0F3A5D") })
        }
        if ($iStoreBtn) {
            $iStoreBtn.Add_MouseEnter({ param($s,$e) $s.Background = Brush("#6D28D9") })
            $iStoreBtn.Add_MouseLeave({ param($s,$e) $s.Background = Brush("#312E81") })
        }

        # Kapat butonu (Modern Hover Destekli)
        $iCloseBtn = New-Object System.Windows.Controls.Button
        $iCloseBtn.Content = "✕ Kapat"
        $iCloseBtn.Width = 95
        $iCloseBtn.Height = 32
        $iCloseBtn.Background = if ($global:isDark) { Brush("#21262D") } else { Brush("#E2E8F0") }
        $iCloseBtn.Foreground = if ($global:isDark) { Brush("#FFFFFF") } else { Brush("#1E293B") }
        $iCloseBtn.FontWeight = "Bold"
        $iCloseBtn.HorizontalAlignment = "Right"
        $iCloseBtn.Margin = New-Object System.Windows.Thickness(0, 4, 0, 0)
        $iCloseBtn.BorderThickness = New-Object System.Windows.Thickness(0)
        $iCloseBtn.Cursor = "Hand"
        $iCloseBtn.Template = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="14"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate>')
        $iCloseBtn.Tag = $infoWin
        $iCloseBtn.Add_MouseEnter({
            param($s,$e)
            $s.Background = if ($global:isDark) { Brush("#374151") } else { Brush("#CBD5E1") }
        })
        $iCloseBtn.Add_MouseLeave({
            param($s,$e)
            $s.Background = if ($global:isDark) { Brush("#21262D") } else { Brush("#E2E8F0") }
        })
        $iCloseBtn.Add_Click({ param($cb, $ce) $cb.Tag.Close() })
        [void]$footerSp.Children.Add($iCloseBtn)

        $infoWin.Content = $gridMain
        [void]$infoWin.ShowDialog()
    })


    # Mouse hover efekti
    $infoBtn.Add_MouseEnter({
        param($s, $ev)
        $s.Background = Brush("#2563EB")
        $s.Child.Foreground = Brush("#FFFFFF")
    })
    $infoBtn.Add_MouseLeave({
        param($s, $ev)
        $s.Background = if ($global:isDark) { Brush("#1E3A5F") } else { Brush("#BFDBFE") }
        $s.Child.Foreground = if ($global:isDark) { Brush("#60A5FA") } else { Brush("#1D4ED8") }
    })

    [System.Windows.Controls.Grid]::SetColumn($infoBtn, 2)
    [void]$grid.Children.Add($infoBtn)

    # Check badge
    $checkBadge = New-Object System.Windows.Controls.Border
    $checkBadge.Width = 18
    $checkBadge.Height = 18
    $checkBadge.CornerRadius = New-Object System.Windows.CornerRadius(6)
    $checkBadge.Background = if ($global:isDark) { Brush("#253246") } else { Brush("#E2E8F0") }
    $checkBadge.VerticalAlignment = "Center"
    $checkBadge.HorizontalAlignment = "Right"

    $checkMark = New-Object System.Windows.Controls.TextBlock
    $checkMark.Text = "✓"
    $checkMark.FontSize = 10.5
    $checkMark.FontWeight = "Bold"
    $checkMark.HorizontalAlignment = "Center"
    $checkMark.VerticalAlignment = "Center"
    $checkMark.Visibility = [System.Windows.Visibility]::Collapsed
    $checkBadge.Child = $checkMark

    [System.Windows.Controls.Grid]::SetColumn($checkBadge, 3)
    [void]$grid.Children.Add($checkBadge)

    # Kart tooltip (hızlı ön izleme)
    if ($app.Desc) {
        $ttPanel = New-Object System.Windows.Controls.StackPanel
        $ttName = New-Object System.Windows.Controls.TextBlock
        $ttName.Text = $app.Name
        $ttName.FontSize = 12
        $ttName.FontWeight = "Bold"
        $ttName.Foreground = [System.Windows.Media.Brushes]::White
        $ttName.Margin = New-Object System.Windows.Thickness(0, 0, 0, 4)
        [void]$ttPanel.Children.Add($ttName)

        if ($isStoreApp) {
            $ttStoreLine = New-Object System.Windows.Controls.TextBlock
            $ttStoreLine.Text = "⊞ Microsoft Store uygulaması"
            $ttStoreLine.FontSize = 9.5
            $ttStoreLine.Foreground = Brush("#818CF8")
            $ttStoreLine.Margin = New-Object System.Windows.Thickness(0, 0, 0, 4)
            [void]$ttPanel.Children.Add($ttStoreLine)
        }

        $ttDesc = New-Object System.Windows.Controls.TextBlock
        $ttDesc.Text = $app.Desc
        $ttDesc.FontSize = 11
        $ttDesc.Foreground = [System.Windows.Media.Brushes]::LightSkyBlue
        $ttDesc.TextWrapping = "Wrap"
        $ttDesc.MaxWidth = 270
        [void]$ttPanel.Children.Add($ttDesc)

        $ttHint = New-Object System.Windows.Controls.TextBlock
        $ttHint.Text = "[ ⓘ ] tıkla → detaylı bilgi"
        $ttHint.FontSize = 9
        $ttHint.Foreground = Brush("#6B7280")
        $ttHint.Margin = New-Object System.Windows.Thickness(0, 5, 0, 0)
        [void]$ttPanel.Children.Add($ttHint)

        $tt = New-Object System.Windows.Controls.ToolTip
        $tt.Background = [System.Windows.Media.Brushes]::Black
        $tt.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.Color]::FromRgb(56, 189, 248))
        $tt.BorderThickness = New-Object System.Windows.Thickness(1)
        $tt.Padding = New-Object System.Windows.Thickness(10, 8, 10, 8)
        $tt.Content = $ttPanel
        [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($card, 400)
        [System.Windows.Controls.ToolTipService]::SetShowDuration($card, 8000)
        $card.ToolTip = $tt
    }

    $card.Child = $grid

    $cardState = [PSCustomObject]@{
        Card            = $card
        App             = $app
        Category        = $app.Cat
        CheckBadge      = $checkBadge
        CheckMark       = $checkMark
        BadgeText       = $badgeText
        IconSource      = $img.Source
        IsInstalled     = $isInstalled
        HasUpdate       = $hasUpdate
        IsSelected      = $false
        QueueRow        = $null
        SourceBadge     = $sourceBadge
        SourceBadgeText = $sourceBadgeText
        SourceBadgeImg  = $sourceBadgeImg
    }
    $card.Tag = $cardState

    $card.Add_MouseLeftButtonUp({
        param($s, $e)
        # ⓘ butonuna tıklanınca kart seçimini tetikleme
        if ($e.OriginalSource -is [System.Windows.Controls.TextBlock] -and
            $e.OriginalSource.Parent -is [System.Windows.Controls.Border] -and
            $e.OriginalSource.Text -eq "i") {
            return
        }
        Toggle-CardSelection $s
    })

    [void]$global:allCards.Add($card)
    return $card
}

# --- KATEGORİLİ LİSTELEME ---

function Render-Cards {
    $categoriesContainerPanel.Children.Clear()
    $global:allCards.Clear()
    $global:allGroupWrappers.Clear()
    $global:selectedQueue.Clear()

    $catKeys = @("Browsers", "Games", "Dev", "Hardware", "Security", "Tools", "Runtimes")

    foreach ($cat in $catKeys) {
        $catApps = @($apps | Where-Object { $_.Cat -eq $cat })
        if ($catApps.Count -eq 0) { continue }

        $groupBorder = New-Object System.Windows.Controls.Border
        $groupBorder.Margin = New-Object System.Windows.Thickness(0,0,0,16)
        $groupBorder.Tag = $cat

        $spGroup = New-Object System.Windows.Controls.StackPanel

        $lblTitle = New-Object System.Windows.Controls.TextBlock
        $lblTitle.Text = $categoryHeaders[$cat]
        $lblTitle.FontSize = 13.5
        $lblTitle.FontWeight = "Bold"
        $lblTitle.Foreground = Brush("#38BDF8")
        $lblTitle.Margin = New-Object System.Windows.Thickness(4,0,0,8)
        [void]$spGroup.Children.Add($lblTitle)

        $wrap = New-Object System.Windows.Controls.Primitives.UniformGrid
        $wrap.Columns = 3
        $wrap.VerticalAlignment = "Top" 

        foreach ($app in $catApps) {
            $card = New-CompactAppCard $app
            [void]$wrap.Children.Add($card)
        }

        [void]$spGroup.Children.Add($wrap)
        $groupBorder.Child = $spGroup

        [void]$categoriesContainerPanel.Children.Add($groupBorder)
        [void]$global:allGroupWrappers.Add($groupBorder)
    }

    Set-CategoryFilter $global:currentCategory $txtHeaderTitle.Text
    Render-QueuePanel
}

function Set-CategoryFilter([string]$category, [string]$title) {
    $global:currentCategory = $category
    $txtHeaderTitle.Text = $title

    foreach ($k in $navButtons.Keys) {
        if ($navButtons[$k]) {
            $navButtons[$k].Background = Brush("Transparent")
            $navButtons[$k].Foreground = Brush("#8C9BB0")
        }
    }
    if ($navButtons[$category]) {
        $navButtons[$category].Background = if ($global:isDark) { Brush("#1A2332") } else { Brush("#E2E8F0") }
        $navButtons[$category].Foreground = if ($global:isDark) { Brush("#FFFFFF") } else { Brush("#0F172A") }
    }

    if ($category -eq "Updates") {
        # Yalnızca güncellemesi olanları sağa seç ve kuyruklayalım
        foreach ($card in $global:allCards) {
            $state = $card.Tag
            if ($state.IsInstalled -and $state.HasUpdate) {
                if (-not $state.IsSelected) {
                    $state.IsSelected = $true
                    $card.Background = if ($global:isDark) { Brush("#1B293C") } else { Brush("#E0F2FE") }
                    $card.BorderBrush = Brush("#38BDF8")
                    $state.CheckBadge.Background = Brush("#38BDF8")
                    $state.CheckMark.Foreground = Brush("#FFFFFF")
                    $state.CheckMark.Visibility = [System.Windows.Visibility]::Visible
                    if (-not $global:selectedQueue.Contains($card)) {
                        [void]$global:selectedQueue.Add($card)
                    }
                }
            } else {
                if ($state.IsSelected) {
                    $state.IsSelected = $false
                    $card.Background = if ($global:isDark) { Brush("#1A2332") } else { Brush("#EDF2F7") }
                    $card.BorderBrush = if ($global:isDark) { Brush("#253246") } else { Brush("#CBD5E1") }
                    $state.CheckBadge.Background = if ($global:isDark) { Brush("#253246") } else { Brush("#CBD5E1") }
                    $state.CheckMark.Visibility = [System.Windows.Visibility]::Collapsed
                    [void]$global:selectedQueue.Remove($card)
                }
            }
        }
        Render-QueuePanel
    }

    Apply-Filters
}

function Apply-Filters {
    $q = $txtSearch.Text.Trim().ToLowerInvariant()
    $txtPlaceholder.Visibility = if ([string]::IsNullOrEmpty($q)) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    $btnClearSearch.Visibility = if ([string]::IsNullOrEmpty($q)) { [System.Windows.Visibility]::Collapsed } else { [System.Windows.Visibility]::Visible }

    $totalVisible = 0

    foreach ($group in $global:allGroupWrappers) {
        $groupCat = $group.Tag
        $catMatch = ($global:currentCategory -in @("All", "Installed", "Updates") -or $groupCat -eq $global:currentCategory)

        if (-not $catMatch) {
            $group.Visibility = [System.Windows.Visibility]::Collapsed
            continue
        }

        $sp = $group.Child
        $wrap = $sp.Children[1]
        $visibleInGroup = 0

        foreach ($card in $wrap.Children) {
            $state = $card.Tag
            $textMatch = ([string]::IsNullOrWhiteSpace($q) -or
                $state.App.Name.ToLowerInvariant().Contains($q) -or
                $state.App.Desc.ToLowerInvariant().Contains($q))

            $filterMatch = $true
            if ($global:currentCategory -eq "Installed") {
                $filterMatch = $state.IsInstalled
            } elseif ($global:currentCategory -eq "Updates") {
                $filterMatch = ($state.IsInstalled -and $state.HasUpdate)
            }

            if ($textMatch -and $filterMatch) {
                $card.Visibility = [System.Windows.Visibility]::Visible
                $visibleInGroup++
                $totalVisible++
            } else {
                $card.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }

        if ($visibleInGroup -gt 0) {
            $group.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $group.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }

    $txtVisibleCount.Text = "$totalVisible uygulama listelendi"
}

# --- TAM DURUM YENİLEME (RESETLEME) MOTORU ---
function Trigger-FullStateRefresh {
    $cardContainerBorder.Opacity = 0.2
    Set-Status "Sistem taranıyor ve kütüphane yenileniyor..." "WARN"
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

    Start-Sleep -Milliseconds 250
    Refresh-InstalledStatus

    $global:selectedQueue.Clear()
    Render-Cards
    Set-ProgressValue 0

    $cardContainerBorder.Opacity = 1.0
    Set-Status "Sistem hazır. Paket listesi ve durumu yenilendi." "OK"
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

# --- İŞLEM YÜRÜTME MOTORU (GELİŞMİŞ ÇIKIŞ VE HATA KONTROLÜ) ---
function Show-BatchConfirmDialog([string]$operation, $queueToProcess) {
    if (-not $queueToProcess -or $queueToProcess.Count -eq 0) { return $false }

    $opTitle = ""
    $opVerb = ""
    $opAccent = "#10B981"
    $opIcon = "🚀"

    switch ($operation) {
        "Kur" {
            $opTitle = "Toplu Kurulum Onayı"
            $opVerb = "bilgisayarınıza kurulacaktır"
            $opAccent = "#10B981"
            $opIcon = "🚀"
        }
        "Guncelle" {
            $opTitle = "Toplu Güncelleme Onayı"
            $opVerb = "en güncel sürüme yükseltilecektir"
            $opAccent = "#0284C7"
            $opIcon = "🔄"
        }
        "Kaldir" {
            $opTitle = "Toplu Kaldırma Onayı"
            $opVerb = "bilgisayarınızdan KALDIRILACAKTIR"
            $opAccent = "#EF4444"
            $opIcon = "🗑️"
        }
    }

    $cWin = New-Object System.Windows.Window
    $cWin.Title = $opTitle
    $cWin.Width = 520
    $cWin.Height = 520
    $cWin.WindowStartupLocation = "CenterScreen"
    $cWin.ResizeMode = "NoResize"
    $cWin.WindowStyle = "None"
    $cWin.AllowsTransparency = $true
    $cWin.Background = [System.Windows.Media.Brushes]::Transparent
    $cWin.ShowInTaskbar = $true

    $mBorder = New-Object System.Windows.Controls.Border
    $mBorder.CornerRadius = New-Object System.Windows.CornerRadius(12)
    $mBorder.Background = if ($global:isDark) { Brush("#0A0F1A") } else { Brush("#FFFFFF") }
    $mBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#CBD5E1") }
    $mBorder.BorderThickness = New-Object System.Windows.Thickness(1.5)
    $mBorder.Padding = New-Object System.Windows.Thickness(20)

    $mGrid = New-Object System.Windows.Controls.Grid
    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::Auto # Header
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star) # List
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::Auto # Buttons
    [void]$mGrid.RowDefinitions.Add($r0); [void]$mGrid.RowDefinitions.Add($r1); [void]$mGrid.RowDefinitions.Add($r2)

    # 1. HEADER
    $headSp = New-Object System.Windows.Controls.StackPanel
    $headSp.Margin = New-Object System.Windows.Thickness(0, 0, 0, 14)

    $hTopSp = New-Object System.Windows.Controls.StackPanel
    $hTopSp.Orientation = "Horizontal"
    $hIcoT = New-Object System.Windows.Controls.TextBlock; $hIcoT.Text = "$opIcon "; $hIcoT.FontSize = 20
    $hTitleT = New-Object System.Windows.Controls.TextBlock; $hTitleT.Text = $opTitle; $hTitleT.FontSize = 17; $hTitleT.FontWeight = "Bold"
    $hTitleT.Foreground = Brush($opAccent)
    [void]$hTopSp.Children.Add($hIcoT); [void]$hTopSp.Children.Add($hTitleT)
    [void]$headSp.Children.Add($hTopSp)

    $hDescT = New-Object System.Windows.Controls.TextBlock
    $hDescT.Text = "Seçilen $($queueToProcess.Count) uygulama $opVerb.`nYanlışlıkla işlem yapılmasını önlemek adına lütfen listeyi kontrol ediniz."
    $hDescT.FontSize = 11.5
    $hDescT.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    $hDescT.Margin = New-Object System.Windows.Thickness(0, 6, 0, 0)
    $hDescT.TextWrapping = "Wrap"
    [void]$headSp.Children.Add($hDescT)

    [System.Windows.Controls.Grid]::SetRow($headSp, 0)
    [void]$mGrid.Children.Add($headSp)

    # 2. SCROLLABLE APP LIST WITH LOGOS
    $listBorder = New-Object System.Windows.Controls.Border
    $listBorder.Background = if ($global:isDark) { Brush("#111827") } else { Brush("#F8FAFC") }
    $listBorder.BorderBrush = if ($global:isDark) { Brush("#1F2937") } else { Brush("#E2E8F0") }
    $listBorder.BorderThickness = New-Object System.Windows.Thickness(1)
    $listBorder.CornerRadius = New-Object System.Windows.CornerRadius(8)
    $listBorder.Padding = New-Object System.Windows.Thickness(8)

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.VerticalScrollBarVisibility = "Auto"
    $itemsSp = New-Object System.Windows.Controls.StackPanel

    foreach ($card in $queueToProcess) {
        $st = $card.Tag
        $app = $st.App

        $rowB = New-Object System.Windows.Controls.Border
        $rowB.Background = if ($global:isDark) { Brush("#182234") } else { Brush("#FFFFFF") }
        $rowB.BorderBrush = if ($global:isDark) { Brush("#23324A") } else { Brush("#E2E8F0") }
        $rowB.BorderThickness = New-Object System.Windows.Thickness(1)
        $rowB.CornerRadius = New-Object System.Windows.CornerRadius(6)
        $rowB.Padding = New-Object System.Windows.Thickness(8, 6, 8, 6)
        $rowB.Margin = New-Object System.Windows.Thickness(0, 0, 0, 6)

        $rowGrid = New-Object System.Windows.Controls.Grid
        $rc0 = New-Object System.Windows.Controls.ColumnDefinition; $rc0.Width = New-Object System.Windows.GridLength(32)
        $rc1 = New-Object System.Windows.Controls.ColumnDefinition; $rc1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $rc2 = New-Object System.Windows.Controls.ColumnDefinition; $rc2.Width = [System.Windows.GridLength]::Auto
        [void]$rowGrid.ColumnDefinitions.Add($rc0); [void]$rowGrid.ColumnDefinitions.Add($rc1); [void]$rowGrid.ColumnDefinitions.Add($rc2)

        # Logo
        $logoImg = New-Object System.Windows.Controls.Image
        $logoImg.Width = 22; $logoImg.Height = 22
        $logoImg.HorizontalAlignment = "Left"; $logoImg.VerticalAlignment = "Center"
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($logoImg, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        if ($st.IconSource) {
            $logoImg.Source = $st.IconSource
        }
        [System.Windows.Controls.Grid]::SetColumn($logoImg, 0)
        [void]$rowGrid.Children.Add($logoImg)

        # Name & Category
        $infoSp = New-Object System.Windows.Controls.StackPanel
        $infoSp.VerticalAlignment = "Center"
        $nameT = New-Object System.Windows.Controls.TextBlock; $nameT.Text = $app.Name; $nameT.FontSize = 12; $nameT.FontWeight = "SemiBold"
        $nameT.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
        $catT = New-Object System.Windows.Controls.TextBlock; $catT.Text = $app.Cat; $catT.FontSize = 9.5
        $catT.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
        [void]$infoSp.Children.Add($nameT); [void]$infoSp.Children.Add($catT)
        [System.Windows.Controls.Grid]::SetColumn($infoSp, 1)
        [void]$rowGrid.Children.Add($infoSp)

        # Source / Status tag
        $tagB = New-Object System.Windows.Controls.Border
        $tagB.CornerRadius = New-Object System.Windows.CornerRadius(4)
        $tagB.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
        $tagB.VerticalAlignment = "Center"
        $tagT = New-Object System.Windows.Controls.TextBlock; $tagT.FontSize = 9; $tagT.FontWeight = "Bold"
        
        $srcVal = if ($app.SelectedSource) { $app.SelectedSource } else { "Normal" }
        if ($srcVal -eq "Store") {
            $tagB.Background = if ($global:isDark) { Brush("#2A2458") } else { Brush("#EDE9FE") }
            $tagT.Text = "Store"
            $tagT.Foreground = if ($global:isDark) { Brush("#D8B4FE") } else { Brush("#6D28D9") }
        } elseif ($srcVal -eq "Both") {
            $tagB.Background = if ($global:isDark) { Brush("#1F2937") } else { Brush("#F1F5F9") }
            $tagT.Text = "Normal + Store"
            $tagT.Foreground = if ($global:isDark) { Brush("#CBD5E1") } else { Brush("#334155") }
        } else {
            $tagB.Background = if ($global:isDark) { Brush("#0C3247") } else { Brush("#E0F2FE") }
            $tagT.Text = "Normal"
            $tagT.Foreground = if ($global:isDark) { Brush("#7DD3FC") } else { Brush("#0369A1") }
        }
        $tagB.Child = $tagT
        [System.Windows.Controls.Grid]::SetColumn($tagB, 2)
        [void]$rowGrid.Children.Add($tagB)

        $rowB.Child = $rowGrid
        [void]$itemsSp.Children.Add($rowB)
    }

    $scroll.Content = $itemsSp
    $listBorder.Child = $scroll
    [System.Windows.Controls.Grid]::SetRow($listBorder, 1)
    [void]$mGrid.Children.Add($listBorder)

    # 3. ACTION BUTTONS (Evet / Hayır)
    $btnGrid = New-Object System.Windows.Controls.Grid
    $btnGrid.Margin = New-Object System.Windows.Thickness(0, 16, 0, 0)
    $bc0 = New-Object System.Windows.Controls.ColumnDefinition; $bc0.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $bc1 = New-Object System.Windows.Controls.ColumnDefinition; $bc1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$btnGrid.ColumnDefinitions.Add($bc0); [void]$btnGrid.ColumnDefinitions.Add($bc1)

    $btnTpl = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.88"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.75"/></Trigger></ControlTemplate.Triggers></ControlTemplate>')

    $script:confirmResult = $false

    # Hayır / İptal
    $btnNo = New-Object System.Windows.Controls.Button
    $btnNo.Content = "✕ Hayır, İptal Et"
    $btnNo.Padding = New-Object System.Windows.Thickness(14, 8, 14, 8)
    $btnNo.FontSize = 12
    $btnNo.FontWeight = "SemiBold"
    $btnNo.Cursor = "Hand"
    $btnNo.Template = $btnTpl
    $btnNo.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#EDF2F7") }
    $btnNo.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#475569") }
    $btnNo.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $btnNo.BorderThickness = New-Object System.Windows.Thickness(1)
    $btnNo.Margin = New-Object System.Windows.Thickness(0, 0, 6, 0)
    $btnNo.Add_Click({
        $script:confirmResult = $false
        $cWin.Close()
    })
    [System.Windows.Controls.Grid]::SetColumn($btnNo, 0)
    [void]$btnGrid.Children.Add($btnNo)

    # Evet / Onayla
    $btnYes = New-Object System.Windows.Controls.Button
    $btnYes.Content = "✓ Evet, Başlat"
    $btnYes.Padding = New-Object System.Windows.Thickness(14, 8, 14, 8)
    $btnYes.FontSize = 12.5
    $btnYes.FontWeight = "Bold"
    $btnYes.Cursor = "Hand"
    $btnYes.Template = $btnTpl
    $btnYes.Background = Brush($opAccent)
    $btnYes.Foreground = Brush("#FFFFFF")
    $btnYes.BorderThickness = New-Object System.Windows.Thickness(0)
    $btnYes.Margin = New-Object System.Windows.Thickness(6, 0, 0, 0)
    $btnYes.Add_Click({
        $script:confirmResult = $true
        $cWin.Close()
    })
    [System.Windows.Controls.Grid]::SetColumn($btnYes, 1)
    [void]$btnGrid.Children.Add($btnYes)

    [System.Windows.Controls.Grid]::SetRow($btnGrid, 2)
    [void]$mGrid.Children.Add($btnGrid)

    $mBorder.Child = $mGrid
    $cWin.Content = $mBorder
    [void]$cWin.ShowDialog()

    return $script:confirmResult
}

function Invoke-BatchOperation([string]$operation) {
    if ($global:isBusy -or $global:selectedQueue.Count -eq 0) { return }

    # Seçilenler arasından bu işleme gerçekten uygun olanları al
    $queueToProcess = @()
    switch ($operation) {
        "Kur" {
            $queueToProcess = @($global:selectedQueue | Where-Object { -not $_.Tag.IsInstalled })
        }
        "Guncelle" {
            $queueToProcess = @($global:selectedQueue | Where-Object { $_.Tag.IsInstalled -and $_.Tag.HasUpdate })
        }
        "Kaldir" {
            $queueToProcess = @($global:selectedQueue | Where-Object { $_.Tag.IsInstalled })
        }
    }

    if ($queueToProcess.Count -eq 0) {
        Show-ModernAlert "Uyarı" "Seçilenler arasında [$operation] işlemi yapılabilecek uygun bir uygulama bulunmuyor." "WARN"
        return
    }

    # Guvenlik ve Yanlislik Onleme: Islem Onay Penceresi (Evet / Hayir + Program Logolari)
    $userConfirmed = Show-BatchConfirmDialog $operation $queueToProcess
    if (-not $userConfirmed) {
        Set-Status "İşlem kullanıcı tarafından iptal edildi." "INFO"
        return
    }

    $global:isBusy = $true
    $global:rebootRequired = $false
    $global:rebootReasonApps = @()

    Update-ActionButtonGuards
    Set-ProgressValue 0

    $total = $queueToProcess.Count
    $done = 0
    $successCount = 0
    $failedCount = 0
    $failedApps = @()

    $runWinget = {
        param([string[]]$argsList)
        $argString = ($argsList | ForEach-Object {
            if ($_ -match '[\s&+]') { '"' + $_.Replace('"','\"') + '"' } else { $_ }
        }) -join " "

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $global:wingetExe
        $psi.Arguments = $argString
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
        $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8

        $proc = [System.Diagnostics.Process]::Start($psi)
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()

        $loop = 0
        while (-not $proc.HasExited) {
            # Olası bir otomatik yeniden başlatma emrini hemen iptal et
            & shutdown.exe /a 2>$null

            $loop++
            # Tek bir uygulamanın ilerlemesini %0'dan %90'a kadar kademeli canlı ilerlet
            if ($loop % 2 -eq 0 -and $mainProgress.Value -lt 90) {
                $mainProgress.Value = [Math]::Min(90, $mainProgress.Value + 2)
                $txtProgress.Text = "$([int]$mainProgress.Value)%"
            }

            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
            Start-Sleep -Milliseconds 120
        }
        $proc.WaitForExit()
        & shutdown.exe /a 2>$null

        $stdout = if ($outTask.IsCompleted -or $outTask.Wait(2000)) { $outTask.Result } else { "" }
        $stderr = if ($errTask.IsCompleted -or $errTask.Wait(2000)) { $errTask.Result } else { "" }

        return @{
            ExitCode = $proc.ExitCode
            Output   = $stdout
            Error    = $stderr
        }
    }

    try {
        foreach ($card in $queueToProcess) {
            $state = $card.Tag
            $app = $state.App

            # Her yeni uygulama için ilerleme çubuğunu %0'a sıfırla
            Set-ProgressValue 0

            # İşleniyor görünümü (Ana Kart)
            $card.Background = Brush("#451A03")
            $card.BorderBrush = Brush("#F59E0B")
            $state.BadgeText.Text = "İşleniyor..."
            $state.BadgeText.Foreground = Brush("#F59E0B")

            # İşleniyor görünümü (Sağ Kurulum Sırası Listesi)
            if ($state.QueueRow) {
                $state.QueueRow.Background = if ($global:isDark) { Brush("#451A03") } else { Brush("#FEF3C7") }
                $state.QueueRow.BorderBrush = Brush("#F59E0B")
            }

            Set-Status "[$($done + 1)/$total] $operation yürütülüyor: $($app.Name)..." "WARN"
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)

            $locArgs = if ($app.InstallLocation) { @("-l", $app.InstallLocation) } else { @() }
            $res = $null
            switch ($operation) {
                "Kur" {
                    $useStore = ($app.SelectedSource -eq "Store") -or ($app.Id -match '^[A-Z0-9]{12,14}$' -and -not $app.NormalId -and -not $app.DownloadUrl)
                    $effectiveStoreId = if ($app.StoreId) { $app.StoreId } elseif ($app.Id -match '^[A-Z0-9]{12,14}$') { $app.Id } else { $null }

                    if ($app.WebUrl) {
                        Set-Status "$($app.Name) platformu açılıyor ve masaüstü kısayolu oluşturuluyor..." "WARN"
                        try {
                            Start-Process "ms-windows-store://search/?query=$([Uri]::EscapeDataString($app.Name))" -ErrorAction SilentlyContinue
                        } catch {}
                        try {
                            Start-Process $app.WebUrl
                            $res = @{ ExitCode = 0; Output = "$($app.Name) web ve mağaza entegrasyonu tamamlandı."; Error = "" }
                        } catch {
                            $res = @{ ExitCode = -1; Output = ""; Error = $_.Exception.Message }
                        }
                    } elseif ($useStore) {
                        if ($effectiveStoreId) {
                            Set-Status "[$($done + 1)/$total] $($app.Name) [Microsoft Store] kuruluyor..." "WARN"
                            $argsStore = @("install", "--id", $effectiveStoreId, "--source", "msstore", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity")
                            $res = & $runWinget $argsStore
                            if ($res.ExitCode -ne 0) {
                                try {
                                    Start-Process "ms-windows-store://pdp/?ProductId=$effectiveStoreId"
                                    $res = @{ ExitCode = 0; Output = "Microsoft Store sayfası açıldı."; Error = "" }
                                } catch {
                                    $res = @{ ExitCode = -1; Output = ""; Error = "Store açılamadı." }
                                }
                            }
                        } else {
                            Set-Status "[$($done + 1)/$total] $($app.Name) [Microsoft Store] aranıyor ve açılıyor..." "WARN"
                            try {
                                Start-Process "ms-windows-store://search/?query=$([Uri]::EscapeDataString($app.Name))"
                                $res = @{ ExitCode = 0; Output = "Microsoft Store arama sayfası açıldı."; Error = "" }
                            } catch {
                                $res = @{ ExitCode = -1; Output = ""; Error = "Store açılamadı." }
                            }
                        }
                    } elseif ($app.DownloadUrl) {
                        Set-Status "$($app.Name) resmi kaynaktan indiriliyor..." "WARN"
                        $tmpExe = Join-Path $env:TEMP "$($app.Slug)_setup.exe"
                        try {
                            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                            $wc = New-Object System.Net.WebClient
                            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                            $wc.DownloadFile($app.DownloadUrl, $tmpExe)
                            Set-Status "$($app.Name) kuruluyor..." "WARN"
                            $p = Start-Process -FilePath $tmpExe -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" -PassThru -Wait
                            $res = @{ ExitCode = $p.ExitCode; Output = "Doğrudan kurulum tamamlandı."; Error = "" }
                        } catch {
                            $res = @{ ExitCode = -1; Output = ""; Error = $_.Exception.Message }
                        }
                    } else {
                        $targetId = if ($app.NormalId) { $app.NormalId } else { $app.Id }
                        $args1 = @("install", "--id", $targetId, "--exact", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity") + $locArgs
                        $res = & $runWinget $args1
                        $full = "$($res.Output)`n$($res.Error)"
                        if ($res.ExitCode -ne 0 -and $full -match 'Install location is required' -and $locArgs.Count -eq 0) {
                            $fallbackLoc = "C:\Program Files (x86)\$($app.Name)"
                            $args1 = @("install", "--id", $targetId, "--exact", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity", "-l", $fallbackLoc)
                            $res = & $runWinget $args1
                            $full = "$($res.Output)`n$($res.Error)"
                        }
                        if ($res.ExitCode -ne 0 -and $res.ExitCode -ne 3010 -and $res.ExitCode -ne 1641 -and -not ($full -match 'existing package already installed|Zaten yüklü')) {
                            $args2 = @("install", "--id", $targetId, "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity") + $locArgs
                            $res2 = & $runWinget $args2
                            $res = $res2
                        }
                    }
                }
                "Guncelle" {
                    $args1 = @("upgrade", "--id", $app.Id, "--exact", "--include-unknown", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity") + $locArgs
                    $res = & $runWinget $args1
                    $full = "$($res.Output)`n$($res.Error)"
                    if ($res.ExitCode -ne 0 -and $full -match 'Install location is required' -and $locArgs.Count -eq 0) {
                        $fallbackLoc = "C:\Program Files (x86)\$($app.Name)"
                        $args1 = @("upgrade", "--id", $app.Id, "--exact", "--include-unknown", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity", "-l", $fallbackLoc)
                        $res = & $runWinget $args1
                        $full = "$($res.Output)`n$($res.Error)"
                    }
                    if ($res.ExitCode -ne 0 -and $res.ExitCode -ne 3010 -and $res.ExitCode -ne 1641 -and $res.ExitCode -ne -1978335189 -and -not ($full -match 'No applicable update found|Güncelleştirme bulunamadı|already at the latest version')) {
                        $args2 = @("upgrade", "--id", $app.Id, "--include-unknown", "--accept-source-agreements", "--accept-package-agreements", "--disable-interactivity") + $locArgs
                        $res2 = & $runWinget $args2
                        $res = $res2
                    }
                }
                                "Kaldir" {
                    # Otomatik tespit: Bilgisayarda gercekte ne kurulu?
                    $cleanSearch = $app.Name -replace '\s*', ''
                    $storePkg = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { 
                        ($_.Name -like "*$cleanSearch*") -or 
                        ($app.StoreId -and $_.PackageFamilyName -like "*$($app.StoreId)*") 
                    } | Select-Object -First 1

                    $nativeUninst = Get-AppUninstallCommand $app.Name $app.Id
                    $exeExists = $false
                    if ($app.ExePath) {
                        try { if (Test-Path $app.ExePath) { $exeExists = $true } } catch {}
                    }
                    $hasNormalInstalled = ($nativeUninst -ne $null -and $nativeUninst.Cmd) -or $exeExists
                    $hasStoreInstalled = ($storePkg -ne $null)

                    $targetUninstallType = "" # "Normal", "Store", "Both"

                    if ($hasStoreInstalled -and $hasNormalInstalled) {
                        # Her ikisi de kurulu ise KULLANICIYA SOR!
                        $dlgUninst = New-Object System.Windows.Window
                        $dlgUninst.Title = "Kaldırma Seçeneği - $($app.Name)"
                        $dlgUninst.Width = 440
                        $dlgUninst.Height = 220
                        $dlgUninst.WindowStartupLocation = "CenterScreen"
                        $dlgUninst.ResizeMode = "NoResize"
                        $dlgUninst.Background = if ($global:isDark) { Brush("#0F172A") } else { Brush("#FFFFFF") }
                        $dlgUninst.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }

                        $uSp = New-Object System.Windows.Controls.StackPanel
                        $uSp.Margin = New-Object System.Windows.Thickness(20)

                        $uMsg = New-Object System.Windows.Controls.TextBlock
                        $uMsg.Text = "$($app.Name) uygulamasının sisteminizde hem Standart (Web) hem de Microsoft Store sürümü tespit edildi.`nHangisini kaldırmak istersiniz?"
                        $uMsg.TextWrapping = "Wrap"
                        $uMsg.FontSize = 12
                        $uMsg.Margin = New-Object System.Windows.Thickness(0,0,0,16)
                        [void]$uSp.Children.Add($uMsg)

                        $uBtnSp = New-Object System.Windows.Controls.StackPanel
                        $uBtnSp.Orientation = "Horizontal"
                        $uBtnSp.HorizontalAlignment = "Right"

                        $script:chosenUninst = "Both"

                        $btnUNormal = New-Object System.Windows.Controls.Button
                        $btnUNormal.Content = "🌐 Normal Sürüm"
                        $btnUNormal.Padding = New-Object System.Windows.Thickness(10,6,10,6)
                        $btnUNormal.Margin = New-Object System.Windows.Thickness(0,0,8,0)
                        $btnUNormal.Add_Click({ $script:chosenUninst = "Normal"; $dlgUninst.Close() })
                        [void]$uBtnSp.Children.Add($btnUNormal)

                        $btnUStore = New-Object System.Windows.Controls.Button
                        $btnUStore.Content = "🛍️ Store Sürüm"
                        $btnUStore.Padding = New-Object System.Windows.Thickness(10,6,10,6)
                        $btnUStore.Margin = New-Object System.Windows.Thickness(0,0,8,0)
                        $btnUStore.Add_Click({ $script:chosenUninst = "Store"; $dlgUninst.Close() })
                        [void]$uBtnSp.Children.Add($btnUStore)

                        $btnUBoth = New-Object System.Windows.Controls.Button
                        $btnUBoth.Content = "🗑️ İkisini de Kaldır"
                        $btnUBoth.Padding = New-Object System.Windows.Thickness(10,6,10,6)
                        $btnUBoth.FontWeight = "Bold"
                        $btnUBoth.Add_Click({ $script:chosenUninst = "Both"; $dlgUninst.Close() })
                        [void]$uBtnSp.Children.Add($btnUBoth)

                        [void]$uSp.Children.Add($uBtnSp)
                        $dlgUninst.Content = $uSp
                        [void]$dlgUninst.ShowDialog()
                        $targetUninstallType = $script:chosenUninst
                    } elseif ($hasStoreInstalled) {
                        # Sadece Store kurulu ise sormadan Store kaldir
                        $targetUninstallType = "Store"
                    } else {
                        # Sadece Normal kurulu ise (veya genel) sormadan Normal kaldir
                        $targetUninstallType = "Normal"
                    }

                    # Store Kaldirma islemi
                    if ($targetUninstallType -eq "Store" -or $targetUninstallType -eq "Both") {
                        if ($storePkg) {
                            Set-Status "$($app.Name) Store paketi sistemden kaldırılıyor..." "WARN"
                            try {
                                Remove-AppxPackage -Package $storePkg.PackageFullName -ErrorAction Stop
                                $res = @{ ExitCode = 0; Output = "$($app.Name) Store paketi başarıyla kaldırıldı."; Error = "" }
                            } catch {
                                $res = @{ ExitCode = 1; Output = ""; Error = $_.Exception.Message }
                            }
                        }
                    }

                    # Normal Kaldirma islemi
                    if ($targetUninstallType -eq "Normal" -or $targetUninstallType -eq "Both") {
                        # 1. WinGet ile tam ID uzerinden kaldir
                        $args1 = @("uninstall", "--id", $app.Id, "--exact", "--accept-source-agreements")
                        $res1 = & $runWinget $args1
                        $res = $res1

                        # 2. Tam ID eslesmezse serbest ID ile dene
                        if ($res.ExitCode -ne 0) {
                            $args2 = @("uninstall", "--id", $app.Id, "--accept-source-agreements")
                            $res2 = & $runWinget $args2
                            if ($res2.ExitCode -eq 0) { $res = $res2 }
                        }

                        # 3. Hala bulunamazsa uygulama ismi ile dene
                        if ($res.ExitCode -ne 0) {
                            $cleanName = $app.Name -replace '\s*\((?:x64|x86)\)', '' -replace '\s*Uygulaması?', ''
                            $args3 = @("uninstall", "--name", $cleanName, "--accept-source-agreements")
                            $res3 = & $runWinget $args3
                            if ($res3.ExitCode -eq 0) { $res = $res3 }
                        }

                        # 4. WinGet bulamazsa Windows Kayit Defterindeki yerel kaldiriciyi calistir
                        if ($res.ExitCode -ne 0 -and $nativeUninst -and $nativeUninst.Cmd) {
                            Set-Status "$($app.Name) Windows yerel kaldırıcı çalıştırılıyor..." "WARN"
                            $rawCmd = $nativeUninst.Cmd
                            if ($rawCmd -match 'MsiExec\.exe\s+/(?:I|X)\s*(\{[^}]+\})') {
                                $guid = $matches[1]
                                $p = Start-Process "msiexec.exe" -ArgumentList "/X$guid /qn /norestart" -PassThru -Wait
                                $res = @{ ExitCode = $p.ExitCode; Output = "MSI kaldırıcı tamamlandı"; Error = "" }
                            } else {
                                $p = Start-Process "cmd.exe" -ArgumentList "/c `"$rawCmd`"" -PassThru -Wait
                                $res = @{ ExitCode = $p.ExitCode; Output = "Yerel kaldırıcı tamamlandı"; Error = "" }
                            }
                        }
                    }
                }
            }

            $exitCode = if ($res) { $res.ExitCode } else { -1 }
            $fullLog = "$($res.Output)`n$($res.Error)"

            # Kaldırma işlemi sonrası durum doğrulaması: Uygulama sistemden gerçekten silindi mi?
            if ($operation -eq "Kaldir") {
                $waitSec = 0
                while ($waitSec -lt 8) {
                    Start-Sleep -Seconds 1
                    $waitSec++
                    $appExe = if ($app.ExePath) { $app.ExePath } else { "" }
                    $appReg = if ($app.RegistryName) { $app.RegistryName } else { "" }
                    $stillInstalled = Is-AppActuallyInstalled $app.Name $app.Id $appExe $appReg
                    if (-not $stillInstalled) {
                        $exitCode = 0
                        $fullLog = "Uygulama sistemden başarıyla kaldırıldı."
                        break
                    }
                }
            }

            # Hash Uyuşmazlığı durumunda (üretici yeni sürüm yayınlamış ama winget manifesti eski kalmış)
            if (($exitCode -eq -1978335215 -or $fullLog -match 'Installer hash does not match|hash does not match') -and ($operation -eq "Kur" -or $operation -eq "Guncelle")) {
                Set-Status "$($app.Name) hash uyuşmazlığı tespit edildi, doğrudan kuruluyor..." "WARN"
                $cachedDirs = Get-ChildItem -Path (Join-Path $env:TEMP "WinGet") -Filter "*$($app.Id)*" -Directory -ErrorAction SilentlyContinue
                $installerFile = $null
                foreach ($cd in $cachedDirs) {
                    $found = Get-ChildItem -Path $cd.FullName -File -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($found) { $installerFile = $found.FullName; break }
                }
                if ($installerFile -and (Test-Path $installerFile)) {
                    $sig = Get-AuthenticodeSignature $installerFile -ErrorAction SilentlyContinue
                    if ($sig -and $sig.Status -eq "Valid") {
                        $targetExe = Join-Path $env:TEMP "$($app.Slug)_Installer.exe"
                        Copy-Item $installerFile $targetExe -Force
                        $p = Start-Process -FilePath $targetExe -ArgumentList "/S" -PassThru
                        $waitCount = 0
                        while (-not $p.HasExited -and $waitCount -lt 45) {
                            Start-Sleep -Seconds 1
                            $waitCount++
                        }
                        $exitCode = 0
                        $res = @{ ExitCode = 0; Output = "Direct vendor installer executed successfully"; Error = "" }
                        $fullLog = "Direct vendor installer executed successfully"
                    }
                }
            }

            # Olası yeniden başlatma gereksinimini yakala
            if ($exitCode -eq 3010 -or $exitCode -eq 1641 -or $fullLog -match 'reboot') {
                $global:rebootRequired = $true
                $global:rebootReasonApps += $app.Name
            }

            # Başarı tespiti
            $isAlreadyLatest = ($exitCode -eq -1978335189 -or $fullLog -match 'No applicable update found|Güncelleştirme bulunamadı|No available upgrade|already at the latest version')
            $isAlreadyInstalled = ($fullLog -match 'existing package already installed|Zaten yüklü bir paket bulundu|already installed')
            $isReboot = ($exitCode -eq 3010 -or $exitCode -eq 1641 -or $fullLog -match 'reboot')
            $isNormalSuccess = ($exitCode -eq 0 -or $exitCode -eq 2359302)

            $isSuccess = ($isNormalSuccess -or $isAlreadyLatest -or $isAlreadyInstalled -or $isReboot)

            if ($isSuccess) {
                $successCount++
                if ($global:isDark) {
                    $card.Background = Brush("#064E3B")
                    $card.BorderBrush = Brush("#34D399")
                }
                else {
                    $card.Background = Brush("#DCFCE7")
                    $card.BorderBrush = Brush("#15803D")
                }

                if ($state.QueueRow) {
                    $state.QueueRow.Background = if ($global:isDark) { Brush("#064E3B") } else { Brush("#DCFCE7") }
                    $state.QueueRow.BorderBrush = if ($global:isDark) { Brush("#34D399") } else { Brush("#15803D") }
                }

                if ($operation -eq "Kaldir") {
                    $state.BadgeText.Text = "Kaldırıldı"
                } elseif ($isAlreadyLatest) {
                    $state.BadgeText.Text = "En Güncel"
                } elseif ($isAlreadyInstalled) {
                    $state.BadgeText.Text = "Zaten Kurulu"
                } else {
                    $state.BadgeText.Text = "Tamamlandı"
                }
                $state.BadgeText.Foreground = Brush("#22C55E")
            }
            else {
                $failedCount++
                $failedApps += $app.Name
                if ($global:isDark) {
                    $card.Background = Brush("#450A0A")
                    $card.BorderBrush = Brush("#EF4444")
                }
                else {
                    $card.Background = Brush("#FEE2E2")
                    $card.BorderBrush = Brush("#DC2626")
                }

                if ($state.QueueRow) {
                    $state.QueueRow.Background = if ($global:isDark) { Brush("#450A0A") } else { Brush("#FEE2E2") }
                    $state.QueueRow.BorderBrush = if ($global:isDark) { Brush("#EF4444") } else { Brush("#DC2626") }
                }

                $state.BadgeText.Text = "Başarısız"
                $state.BadgeText.Foreground = Brush("#EF4444")
                Set-Status "$($app.Name) başarısız oldu. ExitCode: $exitCode" "ERR"
            }

            $done++
            # Tekil uygulama tamamlandığında ilerlemeyi %100 yap ve bir sonraki uygulamaya geçmeden kısa bir süre göster
            Set-ProgressValue 100
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
            Start-Sleep -Milliseconds 400
        }


        # Son işlemin görsel sonucunu kullanıcıya kısa bir an göster (0.8s)
        Start-Sleep -Milliseconds 800

        # Tüm sistemi ve durumu otomatik olarak yenile (kartlar, durum rozetleri, sıra ve ilerleme çubuğu)
        Trigger-FullStateRefresh

        if ($failedCount -eq 0) {
            Set-Status "$successCount/$total işlem başarıyla tamamlandı." "OK"
            Show-ModernAlert "İşlem Tamamlandı" "$successCount uygulama başarıyla işlendi." "INFO"
        }
        else {
            $failedList = ($failedApps -join ", ")
            Set-Status "$successCount başarılı, $failedCount başarısız." "ERR"
            Show-ModernAlert "Bazı İşlemler Başarısız" "Başarılı: $successCount`nBaşarısız: $failedCount`n`nBaşarısız olanlar:`n$failedList" "ERR"
        }

        # Eğer herhangi bir güncelleme yeniden başlatma gerektirdiyse kullanıcıya sor
        if ($global:rebootRequired -and $global:rebootReasonApps.Count -gt 0) {
            $rebootNames = ($global:rebootReasonApps | Select-Object -Unique) -join ", "
            $userWantsReboot = Show-ModernConfirmDialog "Yeniden Başlatma Gerekli" "Yeniden Başlat" @("Aşağıdaki güncellemeler (veya sistem bileşenleri) sistemin yeniden başlatılmasını gerektiriyor:`n$rebootNames`n`nBilgisayarınızı şimdi yeniden başlatmak ister misiniz? (İptal derseniz daha sonra kendiniz de başlatabilirsiniz)")
            if ($userWantsReboot) {
                Restart-Computer -Force
            }
        }
    }
    catch {
        Set-Status "Hata: $_" "ERR"
        Show-ModernAlert "Hata" "İşlem sırasında beklenmeyen bir hata oluştu:`n$($_.Exception.Message)" "ERR"
    }
    finally {
        $global:isBusy = $false
        $cardContainerBorder.Opacity = 1.0
        Update-ActionButtonGuards
    }
}

# --- SÜRÜCÜ & DONANIM YÖNETİCİSİ (DRIVER & DEVICE HUB) ---
function Get-FriendlyDriverInfo($name, $rawClass, $provider, $origInf) {
    $norm = ("$name $rawClass $origInf $provider").ToLowerInvariant()

    $typeBadge = "📦 Donanım Sürücüsü"
    $friendlyDesc = ""

    if ($norm.Contains("geforce") -or $norm.Contains("rtx") -or $norm.Contains("gtx") -or $norm.Contains("radeon") -or ($norm.Contains("nvidia") -and ($norm.Contains("display") -or $norm.Contains("graphics")))) {
        $typeBadge = "🎮 Harici Ekran Kartı (GPU)"
        $friendlyDesc = "Oyunlar, 3D çizim ve yüksek grafik performansı için birincil ekran kartı grafik sürücüsü."
    } elseif ($norm.Contains("uhd graphics") -or $norm.Contains("iris") -or ($norm.Contains("intel") -and ($norm.Contains("display") -or $norm.Contains("graphics")) -and -not $norm.Contains("virtual"))) {
        $typeBadge = "🖥️ Dahili Grafik (iGPU)"
        $friendlyDesc = "İşlemciye entegre Intel dahili ekran kartı görüntü sürücüsü."
    } elseif ($norm.Contains("teamviewer") -or $norm.Contains("virtual monitor") -or $norm.Contains("virtual display") -or $norm.Contains("spacedesk") -or $norm.Contains("parsec")) {
        $typeBadge = "📺 Sanal Ekran Sürücüsü"
        $friendlyDesc = "Uzaktan masaüstü ve ekran yansıtma yazılımları için sanal görüntü sürücüsü."
    } elseif ($norm.Contains("realtek") -and ($norm.Contains("audio") -or $norm.Contains("sound") -or $norm.Contains("media"))) {
        $typeBadge = "🔊 Dahili Ses Kartı"
        $friendlyDesc = "Hoparlör, kulaklık ve mikrofon ses giriş/çıkışlarını yöneten anakart ses sürücüsü."
    } elseif ($norm.Contains("steelseries") -and ($norm.Contains("audio") -or $norm.Contains("sonar"))) {
        $typeBadge = "🎧 SteelSeries Sonar Ses"
        $friendlyDesc = "SteelSeries kulaklıklar için gelişmiş sanal ses yönlendirme ve filtreleme sürücüsü."
    } elseif ($norm.Contains("bluetooth") -or $norm.Contains("bth")) {
        $typeBadge = "📶 Bluetooth Donanımı"
        $friendlyDesc = "Kablosuz kulaklık, gamepad, klavye ve fare bağlantılarını sağlayan Bluetooth sürücüsü."
    } elseif ($norm.Contains("wi-fi") -or $norm.Contains("wifi") -or $norm.Contains("wireless") -or $norm.Contains("wlan") -or $norm.Contains("802.11")) {
        $typeBadge = "🌐 Kablosuz Ağ (Wi-Fi)"
        $friendlyDesc = "Kablosuz internet ve yerel ağ bağlantısını sağlayan Wi-Fi ağ kartı sürücüsü."
    } elseif ($norm.Contains("ethernet") -or $norm.Contains("gigabit") -or $norm.Contains("lan") -or $norm.Contains("pcie gbe") -or $norm.Contains("i219") -or $norm.Contains("i225")) {
        $typeBadge = "🌐 Kablolu Ağ (Ethernet)"
        $friendlyDesc = "Kablolu internet bağlantısını yöneten yüksek hızlı Ethernet ağ bağdaştırıcısı."
    } elseif ($norm.Contains("nvme") -or $norm.Contains("ssd") -or $norm.Contains("storage") -or $norm.Contains("sata") -or $norm.Contains("ahci") -or $norm.Contains("rst") -or $norm.Contains("vmd")) {
        $typeBadge = "💾 Hızlı Disk & NVMe SSD"
        $friendlyDesc = "M.2 NVMe SSD ve sabit disklerin maksimum okuma/yazma hızında çalışmasını sağlar."
    } elseif ($norm.Contains("chipset") -or $norm.Contains("yonga") -or $norm.Contains("smbus") -or $norm.Contains("lpc") -or $norm.Contains("pcie rc") -or $norm.Contains("gpio") -or $norm.Contains("acpi") -or $norm.Contains("system management")) {
        $typeBadge = "⚙️ Anakart Çipseti (Chipset)"
        $friendlyDesc = "İşlemci, RAM ve anakart donanım yolları arasındaki veri akışını yöneten temel sistem sürücüsü."
    } elseif ($norm.Contains("logitech") -or $norm.Contains("g hub")) {
        $typeBadge = "🖱️ Logitech Oyuncu Donanımı"
        $friendlyDesc = "Logitech G serisi fare, klavye ve kulaklıkların G HUB ile iletişimini sağlayan sürücü."
    } elseif ($norm.Contains("gamepad") -or $norm.Contains("controller") -or $norm.Contains("xinput") -or $norm.Contains("nefarius") -or $norm.Contains("dualsense")) {
        $typeBadge = "🎮 Oyun Kolu (Gamepad)"
        $friendlyDesc = "Xbox veya PlayStation oyun kollarının bilgisayarda gecikmesiz çalışmasını sağlar."
    } else {
        $cleanRaw = switch -Regex ($rawClass) {
            '(?i)display'                { "🖥️ Ekran & Grafik" }
            '(?i)media|sound|audio'      { "🔊 Ses & Medya" }
            '(?i)net'                    { "🌐 Ağ Bileşeni" }
            '(?i)bluetooth'              { "📶 Bluetooth Aygıtı" }
            '(?i)scsi|disk|storage|hdc'  { "💾 Depolama & Disk" }
            '(?i)system|chipset'         { "⚙️ Sistem Bileşeni" }
            '(?i)usb|hid'                { "🔌 USB / Giriş Aygıtı" }
            default                      { "📦 Donanım Bileşeni" }
        }
        $typeBadge = $cleanRaw
        $friendlyDesc = "$provider üreticisine ait Windows $rawClass donanım sürücüsü."
    }

    return @{
        Badge = $typeBadge
        Description = $friendlyDesc
    }
}

function Get-SystemDrivers {
    $pnpList = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.Present -and $_.FriendlyName }
    $pnpByInstance = @{}
    $pnpByName = @{}
    foreach ($p in $pnpList) {
        if ($p.InstanceId) { $pnpByInstance[$p.InstanceId] = $p }
        $lowName = $p.FriendlyName.ToLowerInvariant().Trim()
        if (-not $pnpByName.ContainsKey($lowName)) { $pnpByName[$lowName] = $p }
    }

    $signed = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue
    $infToPnp = @{}
    $devIdToSigned = @{}
    foreach ($s in $signed) {
        if ($s.InfName) { $infToPnp[$s.InfName.ToLowerInvariant()] = $s }
        if ($s.DeviceID) { $devIdToSigned[$s.DeviceID] = $s }
    }

    $pnpOut = pnputil /enum-drivers
    $blocks = ($pnpOut -join "`n") -split "(?m)(?=Published Name:\s+)"
    $items = @()
    $seenInstances = @{}

    foreach ($b in $blocks) {
        if ($b -match 'Published Name:\s+(oem\d+\.inf)') {
            $pub = $matches[1].ToLowerInvariant()
            $orig = if ($b -match 'Original Name:\s+([^\r\n]+)') { $matches[1].Trim() } else { "" }
            $prov = if ($b -match 'Provider Name:\s+([^\r\n]+)') { $matches[1].Trim() } else { "" }
            $cls = if ($b -match 'Class Name:\s+([^\r\n]+)') { $matches[1].Trim() } else { "" }
            $ver = if ($b -match 'Driver Version:\s+([^\r\n]+)') { $matches[1].Trim() } else { "" }

            $sd = if ($infToPnp.ContainsKey($pub)) { $infToPnp[$pub] } else { $null }
            $friendly = if ($sd -and $sd.DeviceName) { $sd.DeviceName } else { "$prov $cls ($orig)" }
            $rawClass = if ($sd -and $sd.DeviceClass) { $sd.DeviceClass } else { $cls }
            $instId = if ($sd -and $sd.DeviceID) { $sd.DeviceID } else { "" }

            $pnpMatch = if ($instId -and $pnpByInstance.ContainsKey($instId)) { 
                $pnpByInstance[$instId] 
            } elseif ($pnpByName.ContainsKey($friendly.ToLowerInvariant().Trim())) { 
                $pnpByName[$friendly.ToLowerInvariant().Trim()] 
            } else { 
                $null 
            }

            $hasProblem = $false
            $problemCode = ""
            $isDisabled = $false

            if ($pnpMatch) {
                if ($pnpMatch.InstanceId) { $seenInstances[$pnpMatch.InstanceId] = $true }
                if ($pnpMatch.Problem -eq 'CM_PROB_DISABLED' -or $pnpMatch.ConfigManagerErrorCode -eq 'CM_PROB_DISABLED') {
                    $isDisabled = $true
                } elseif ($pnpMatch.Status -eq 'Error' -or $pnpMatch.Status -eq 'Degraded' -or 
                    ($pnpMatch.ConfigManagerErrorCode -and $pnpMatch.ConfigManagerErrorCode -ne 'CM_PROB_NONE' -and $pnpMatch.ConfigManagerErrorCode -ne 'CM_PROB_NOT_CONFIGURED')) {
                    $hasProblem = $true
                    $problemCode = if ($pnpMatch.Problem) { $pnpMatch.Problem } else { $pnpMatch.ConfigManagerErrorCode }
                }
            }

            # Turkish-invariant normalization for category classification
            $norm = ("$rawClass $cls $orig $friendly").ToLowerInvariant()
            $cleanCat = if ($norm.Contains("display") -or $norm.Contains("video") -or $norm.Contains("gpu") -or $norm.Contains("geforce") -or $norm.Contains("radeon") -or $norm.Contains("graphics") -or $norm.Contains("monitor")) { "Display" }
            elseif ($norm.Contains("media") -or $norm.Contains("sound") -or $norm.Contains("audio") -or $norm.Contains("realtek audio") -or $norm.Contains("sonar")) { "Media" }
            elseif ($norm.Contains("net") -or $norm.Contains("wifi") -or $norm.Contains("wlan") -or $norm.Contains("ethernet") -or $norm.Contains("lan") -or $norm.Contains("802.11")) { "Net" }
            elseif ($norm.Contains("bluetooth") -or $norm.Contains("bth")) { "Bluetooth" }
            elseif ($norm.Contains("scsi") -or $norm.Contains("disk") -or $norm.Contains("storage") -or $norm.Contains("nvme") -or $norm.Contains("hdc") -or $norm.Contains("sata") -or $norm.Contains("ahci")) { "Storage" }
            elseif ($norm.Contains("system") -or $norm.Contains("chipset") -or $norm.Contains("processor") -or $norm.Contains("cpu") -or $norm.Contains("smbus") -or $norm.Contains("pcie") -or $norm.Contains("acpi") -or $norm.Contains("lpc") -or $norm.Contains("gpio")) { "System" }
            elseif ($norm.Contains("usb") -or $norm.Contains("hid") -or $norm.Contains("mouse") -or $norm.Contains("keyboard") -or $norm.Contains("controller") -or $norm.Contains("gamepad") -or $norm.Contains("logitech")) { "USB" }
            else { "Other" }

            $friendlyInfo = Get-FriendlyDriverInfo $friendly $rawClass $prov $orig

            $items += [PSCustomObject]@{
                Name          = $friendly
                InfName       = $pub
                OriginalInf   = $orig
                Provider      = $prov
                RawClass      = $rawClass
                Category      = $cleanCat
                Version       = $ver
                InstanceId    = if ($pnpMatch) { $pnpMatch.InstanceId } else { $instId }
                HasProblem    = $hasProblem
                ProblemCode   = $problemCode
                IsDisabled    = $isDisabled
                IsPnpOnly     = $false
                HardwareID    = if ($sd -and $sd.HardwareID) { $sd.HardwareID } else { "" }
                FriendlyBadge = $friendlyInfo.Badge
                FriendlyDesc  = $friendlyInfo.Description
            }
        }
    }

    foreach ($p in $pnpList) {
        if ($seenInstances.ContainsKey($p.InstanceId)) { continue }

        $hasProb = ($p.Status -eq 'Error' -or $p.Status -eq 'Degraded' -or 
            ($p.ConfigManagerErrorCode -and $p.ConfigManagerErrorCode -ne 'CM_PROB_NONE' -and $p.ConfigManagerErrorCode -ne 'CM_PROB_NOT_CONFIGURED'))
        $isDis = ($p.Problem -eq 'CM_PROB_DISABLED' -or $p.ConfigManagerErrorCode -eq 'CM_PROB_DISABLED')

        if ($hasProb -or $isDis) {
            $sd = if ($devIdToSigned.ContainsKey($p.InstanceId)) { $devIdToSigned[$p.InstanceId] } else { $null }
            $norm = ("$($p.Class) $($p.FriendlyName)").ToLowerInvariant()

            $cleanCat = if ($norm.Contains("display") -or $norm.Contains("video") -or $norm.Contains("gpu")) { "Display" }
            elseif ($norm.Contains("media") -or $norm.Contains("sound") -or $norm.Contains("audio")) { "Media" }
            elseif ($norm.Contains("net") -or $norm.Contains("wifi") -or $norm.Contains("wlan") -or $norm.Contains("ethernet")) { "Net" }
            elseif ($norm.Contains("bluetooth") -or $norm.Contains("bth")) { "Bluetooth" }
            elseif ($norm.Contains("scsi") -or $norm.Contains("disk") -or $norm.Contains("storage") -or $norm.Contains("nvme") -or $norm.Contains("hdc")) { "Storage" }
            elseif ($norm.Contains("system") -or $norm.Contains("chipset") -or $norm.Contains("processor") -or $norm.Contains("cpu")) { "System" }
            elseif ($norm.Contains("usb") -or $norm.Contains("hid") -or $norm.Contains("mouse") -or $norm.Contains("keyboard")) { "USB" }
            else { "Other" }

            $prov = if ($sd) { $sd.DriverProviderName } else { "Microsoft" }
            $friendlyInfo = Get-FriendlyDriverInfo $p.FriendlyName $p.Class $prov ""

            $items += [PSCustomObject]@{
                Name          = $p.FriendlyName
                InfName       = if ($sd) { $sd.InfName } else { "Standart Windows Sürücüsü" }
                OriginalInf   = ""
                Provider      = $prov
                RawClass      = $p.Class
                Category      = $cleanCat
                Version       = if ($sd) { $sd.DriverVersion } else { "10.0" }
                InstanceId    = $p.InstanceId
                HasProblem    = $hasProb
                ProblemCode   = if ($p.Problem) { $p.Problem } else { $p.ConfigManagerErrorCode }
                IsDisabled    = $isDis
                IsPnpOnly     = $true
                HardwareID    = if ($sd -and $sd.HardwareID) { $sd.HardwareID } else { "" }
                FriendlyBadge = $friendlyInfo.Badge
                FriendlyDesc  = $friendlyInfo.Description
            }
        }
    }

    return $items
}

# --- SİSTEM VE DİSK TEMİZLEYİCİ (PC CLEANER PRO) ---
function script:Format-CleanerBytes([double]$bytes) {
    if ($bytes -le 0) { return "0 B" }
    if ($bytes -lt 1KB) { return "$bytes B" }
    if ($bytes -lt 1MB) { return "$([Math]::Round($bytes / 1KB, 1)) KB" }
    if ($bytes -lt 1GB) { return "$([Math]::Round($bytes / 1MB, 1)) MB" }
    return "$([Math]::Round($bytes / 1GB, 2)) GB"
}
function global:Format-CleanerBytes([double]$bytes) {
    if ($bytes -le 0) { return "0 B" }
    if ($bytes -lt 1KB) { return "$bytes B" }
    if ($bytes -lt 1MB) { return "$([Math]::Round($bytes / 1KB, 1)) KB" }
    if ($bytes -lt 1GB) { return "$([Math]::Round($bytes / 1MB, 1)) MB" }
    return "$([Math]::Round($bytes / 1GB, 2)) GB"
}


# ---------------------------------------------------------
# WINDOWS DEFENDER VİRÜS & TEHDİT KORUMASI MODAL PENCERESİ
# ---------------------------------------------------------

function Show-DefenderSecurityModal {
    $dWin = New-Object System.Windows.Window
    $dWin.Title = "Windows Güvenlik & Virüs Taraması"
    $dWin.Width = 880
    $dWin.Height = 670
    $dWin.WindowStartupLocation = "CenterScreen"
    $dWin.ResizeMode = "NoResize"
    $dWin.WindowStyle = "None"
    $dWin.AllowsTransparency = $true
    $dWin.Background = [System.Windows.Media.Brushes]::Transparent
    $dWin.ShowInTaskbar = $true
    try { $dWin.Resources = $window.Resources } catch {}

    $mBorder = New-Object System.Windows.Controls.Border
    $mBorder.CornerRadius = New-Object System.Windows.CornerRadius(14)
    $mBorder.Background = if ($global:isDark) { Brush("#0A0F1A") } else { Brush("#F8FAFC") }
    $mBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#CBD5E1") }
    $mBorder.BorderThickness = New-Object System.Windows.Thickness(1.5)
    $mBorder.Padding = New-Object System.Windows.Thickness(24)

    $mGrid = New-Object System.Windows.Controls.Grid
    $mr0 = New-Object System.Windows.Controls.RowDefinition; $mr0.Height = [System.Windows.GridLength]::Auto # Header
    $mr1 = New-Object System.Windows.Controls.RowDefinition; $mr1.Height = [System.Windows.GridLength]::Auto # Status Cards
    $mr2 = New-Object System.Windows.Controls.RowDefinition; $mr2.Height = [System.Windows.GridLength]::Auto # Scan Cards
    $mr3 = New-Object System.Windows.Controls.RowDefinition; $mr3.Height = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star) # Progress & Log
    $mr4 = New-Object System.Windows.Controls.RowDefinition; $mr4.Height = [System.Windows.GridLength]::Auto # Footer
    [void]$mGrid.RowDefinitions.Add($mr0); [void]$mGrid.RowDefinitions.Add($mr1); [void]$mGrid.RowDefinitions.Add($mr2); [void]$mGrid.RowDefinitions.Add($mr3); [void]$mGrid.RowDefinitions.Add($mr4)

    # 1. HEADER
    $headerGrid = New-Object System.Windows.Controls.Grid
    $hc0 = New-Object System.Windows.Controls.ColumnDefinition; $hc0.Width = [System.Windows.GridLength]::Auto
    $hc1 = New-Object System.Windows.Controls.ColumnDefinition; $hc1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $hc2 = New-Object System.Windows.Controls.ColumnDefinition; $hc2.Width = [System.Windows.GridLength]::Auto
    [void]$headerGrid.ColumnDefinitions.Add($hc0); [void]$headerGrid.ColumnDefinitions.Add($hc1); [void]$headerGrid.ColumnDefinitions.Add($hc2)

    $hIcoB = New-Object System.Windows.Controls.Border
    $hIcoB.Width = 46; $hIcoB.Height = 46; $hIcoB.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $hIcoB.Background = if ($global:isDark) { Brush("#064E3B") } else { Brush("#DCFCE7") }
    $hIcoB.BorderBrush = if ($global:isDark) { Brush("#10B981") } else { Brush("#86EFAC") }
    $hIcoB.BorderThickness = New-Object System.Windows.Thickness(1)
    $hIcoB.Margin = New-Object System.Windows.Thickness(0,0,14,0)
    $hIcoT = New-Object System.Windows.Controls.TextBlock; $hIcoT.Text = "🛡️"; $hIcoT.FontSize = 22
    $hIcoT.HorizontalAlignment = "Center"; $hIcoT.VerticalAlignment = "Center"
    $hIcoB.Child = $hIcoT
    [System.Windows.Controls.Grid]::SetColumn($hIcoB, 0)
    [void]$headerGrid.Children.Add($hIcoB)

    $hTitles = New-Object System.Windows.Controls.StackPanel
    $hTitles.VerticalAlignment = "Center"
    $hMainT = New-Object System.Windows.Controls.TextBlock
    $hMainT.Text = "Virüs & Tehdit Koruması (Windows Defender)"
    $hMainT.FontSize = 18; $hMainT.FontWeight = "Bold"
    $hMainT.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    [void]$hTitles.Children.Add($hMainT)
    $hSubT = New-Object System.Windows.Controls.TextBlock
    $hSubT.Text = "Windows Defender güvenlik motoru, gerçek zamanlı kalkan ve virüs tanımları yönetimi"
    $hSubT.FontSize = 11; $hSubT.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    $hSubT.Margin = New-Object System.Windows.Thickness(0,2,0,0)
    [void]$hTitles.Children.Add($hSubT)
    [System.Windows.Controls.Grid]::SetColumn($hTitles, 1)
    [void]$headerGrid.Children.Add($hTitles)

    # Header Close Button
    $closeHeaderBtn = New-Object System.Windows.Controls.Border
    $closeHeaderBtn.Width = 32; $closeHeaderBtn.Height = 32
    $closeHeaderBtn.CornerRadius = New-Object System.Windows.CornerRadius(8)
    $closeHeaderBtn.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
    $closeHeaderBtn.Cursor = "Hand"
    $closeHeaderBtn.VerticalAlignment = "Center"
    $closeHeaderTxt = New-Object System.Windows.Controls.TextBlock
    $closeHeaderTxt.Text = "✕"; $closeHeaderTxt.FontSize = 14; $closeHeaderTxt.FontWeight = "Bold"
    $closeHeaderTxt.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    $closeHeaderTxt.HorizontalAlignment = "Center"; $closeHeaderTxt.VerticalAlignment = "Center"
    $closeHeaderBtn.Child = $closeHeaderTxt
    $closeHeaderBtn.Add_MouseEnter({ param($s,$e) $s.Background = Brush("#DC2626"); $s.Child.Foreground = Brush("#FFFFFF") })
    $closeHeaderBtn.Add_MouseLeave({ param($s,$e) $s.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }; $s.Child.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") } })
    $closeHeaderBtn.Add_MouseLeftButtonUp({ $dWin.Close() })
    [System.Windows.Controls.Grid]::SetColumn($closeHeaderBtn, 2)
    [void]$headerGrid.Children.Add($closeHeaderBtn)

    [System.Windows.Controls.Grid]::SetRow($headerGrid, 0)
    [void]$mGrid.Children.Add($headerGrid)

    # 2. STATUS SUMMARY STRIP
    $statBorder = New-Object System.Windows.Controls.Border
    $statBorder.Background = if ($global:isDark) { Brush("#111827") } else { Brush("#FFFFFF") }
    $statBorder.BorderBrush = if ($global:isDark) { Brush("#1F2937") } else { Brush("#E2E8F0") }
    $statBorder.BorderThickness = New-Object System.Windows.Thickness(1)
    $statBorder.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $statBorder.Padding = New-Object System.Windows.Thickness(16, 10, 16, 10)
    $statBorder.Margin = New-Object System.Windows.Thickness(0, 14, 0, 12)

    $statGrid = New-Object System.Windows.Controls.Grid
    $sc0 = New-Object System.Windows.Controls.ColumnDefinition; $sc0.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $sc1 = New-Object System.Windows.Controls.ColumnDefinition; $sc1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $sc2 = New-Object System.Windows.Controls.ColumnDefinition; $sc2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$statGrid.ColumnDefinitions.Add($sc0); [void]$statGrid.ColumnDefinitions.Add($sc1); [void]$statGrid.ColumnDefinitions.Add($sc2)

    # Status Column 1: Shield
    $sCol1Sp = New-Object System.Windows.Controls.StackPanel
    $sCol1Lbl = New-Object System.Windows.Controls.TextBlock; $sCol1Lbl.Text = "KALKAN DURUMU"; $sCol1Lbl.FontSize = 10; $sCol1Lbl.FontWeight = "Bold"; $sCol1Lbl.Foreground = Brush("#94A3B8")
    $sCol1Val = New-Object System.Windows.Controls.TextBlock; $sCol1Val.Text = "● Aktif & Korunuyor"; $sCol1Val.FontSize = 12.5; $sCol1Val.FontWeight = "Bold"; $sCol1Val.Foreground = Brush("#10B981"); $sCol1Val.Margin = New-Object System.Windows.Thickness(0,2,0,0)
    [void]$sCol1Sp.Children.Add($sCol1Lbl); [void]$sCol1Sp.Children.Add($sCol1Val)
    [System.Windows.Controls.Grid]::SetColumn($sCol1Sp, 0); [void]$statGrid.Children.Add($sCol1Sp)

    # Status Column 2: Threats
    $sCol2Sp = New-Object System.Windows.Controls.StackPanel
    $sCol2Lbl = New-Object System.Windows.Controls.TextBlock; $sCol2Lbl.Text = "BULUNAN TEHDİT"; $sCol2Lbl.FontSize = 10; $sCol2Lbl.FontWeight = "Bold"; $sCol2Lbl.Foreground = Brush("#94A3B8")
    $sCol2Val = New-Object System.Windows.Controls.TextBlock; $sCol2Val.Text = "0 Tehdit"; $sCol2Val.FontSize = 12.5; $sCol2Val.FontWeight = "Bold"; $sCol2Val.Foreground = Brush("#38BDF8"); $sCol2Val.Margin = New-Object System.Windows.Thickness(0,2,0,0)
    [void]$sCol2Sp.Children.Add($sCol2Lbl); [void]$sCol2Sp.Children.Add($sCol2Val)
    [System.Windows.Controls.Grid]::SetColumn($sCol2Sp, 1); [void]$statGrid.Children.Add($sCol2Sp)

    # Status Column 3: Timer
    $sCol3Sp = New-Object System.Windows.Controls.StackPanel
    $sCol3Lbl = New-Object System.Windows.Controls.TextBlock; $sCol3Lbl.Text = "GEÇEN SÜRE"; $sCol3Lbl.FontSize = 10; $sCol3Lbl.FontWeight = "Bold"; $sCol3Lbl.Foreground = Brush("#94A3B8")
    $sCol3Val = New-Object System.Windows.Controls.TextBlock; $sCol3Val.Text = "00:00"; $sCol3Val.FontSize = 12.5; $sCol3Val.FontWeight = "Bold"; $sCol3Val.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }; $sCol3Val.Margin = New-Object System.Windows.Thickness(0,2,0,0)
    [void]$sCol3Sp.Children.Add($sCol3Lbl); [void]$sCol3Sp.Children.Add($sCol3Val)
    [System.Windows.Controls.Grid]::SetColumn($sCol3Sp, 2); [void]$statGrid.Children.Add($sCol3Sp)

    $statBorder.Child = $statGrid
    [System.Windows.Controls.Grid]::SetRow($statBorder, 1)
    [void]$mGrid.Children.Add($statBorder)

    # 3. ACTION CARDS (4 Fluent Cards)
    $cardsGrid = New-Object System.Windows.Controls.Grid
    $cg0 = New-Object System.Windows.Controls.ColumnDefinition; $cg0.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $cg1 = New-Object System.Windows.Controls.ColumnDefinition; $cg1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $cg2 = New-Object System.Windows.Controls.ColumnDefinition; $cg2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $cg3 = New-Object System.Windows.Controls.ColumnDefinition; $cg3.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$cardsGrid.ColumnDefinitions.Add($cg0); [void]$cardsGrid.ColumnDefinitions.Add($cg1); [void]$cardsGrid.ColumnDefinitions.Add($cg2); [void]$cardsGrid.ColumnDefinitions.Add($cg3)
    $cardsGrid.Margin = New-Object System.Windows.Thickness(0, 0, 0, 14)

    function New-DefenderCard([string]$ico, [string]$title, [string]$sub, [string]$accentHex, [string]$lightBgHex, [string]$lightTextHex, [int]$col) {
        $c = New-Object System.Windows.Controls.Border
        $c.CornerRadius = New-Object System.Windows.CornerRadius(10)
        # Gozu yormayan pastel soft renkler
        $c.Background = if ($global:isDark) { Brush("#131D2E") } else { Brush($lightBgHex) }
        $c.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush($accentHex) }
        $c.BorderThickness = New-Object System.Windows.Thickness(1.2)
        $c.Padding = New-Object System.Windows.Thickness(14, 12, 14, 12)
        
        # Bitisikligi onleyen ayrismis zarif bosluklar (5. resimdeki sikisikligi cozer)
        $marginLeft = if ($col -eq 0) { 0 } else { 8 }
        $marginRight = if ($col -eq 3) { 0 } else { 8 }
        $c.Margin = New-Object System.Windows.Thickness($marginLeft, 0, $marginRight, 0)
        $c.Cursor = "Hand"

        $sp = New-Object System.Windows.Controls.StackPanel
        $sp.IsHitTestVisible = $false # Tiklamanin Border'a puruzsuz ulasmasini saglar
        
        $iT = New-Object System.Windows.Controls.TextBlock; $iT.Text = $ico; $iT.FontSize = 22; $iT.Margin = New-Object System.Windows.Thickness(0,0,0,6)
        $tT = New-Object System.Windows.Controls.TextBlock; $tT.Text = $title; $tT.FontSize = 12.5; $tT.FontWeight = "Bold"
        $tT.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush($lightTextHex) }
        
        $sT = New-Object System.Windows.Controls.TextBlock; $sT.Text = $sub; $sT.FontSize = 10
        $sT.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
        $sT.Margin = New-Object System.Windows.Thickness(0,3,0,0); $sT.TextWrapping = "Wrap"
        [void]$sp.Children.Add($iT); [void]$sp.Children.Add($tT); [void]$sp.Children.Add($sT)
        $c.Child = $sp

        $c.Add_MouseEnter({ param($s,$e) $s.Opacity = 0.88 })
        $c.Add_MouseLeave({ param($s,$e) $s.Opacity = 1.0 })

        [System.Windows.Controls.Grid]::SetColumn($c, $col)
        [void]$cardsGrid.Children.Add($c)
        return $c
    }

    $cardQuick = New-DefenderCard "⚡" "Hızlı Tarama" "Kritik sistem alanlarını tara" "#38BDF8" "#F0F9FF" "#0369A1" 0
    $cardFull  = New-DefenderCard "🛡️" "Tam Tarama" "Tüm diskleri derinlemesine tara" "#818CF8" "#F5F3FF" "#4F46E5" 1
    $cardUpd   = New-DefenderCard "🔄" "İmza Güncelle" "En güncel virüs tanımlarını indir" "#34D399" "#ECFDF5" "#059669" 2
    $cardOpen  = New-DefenderCard "⚙️" "Windows Güvenliği" "Resmi Windows kalkan panelini aç" "#F59E0B" "#FFFBEB" "#B45309" 3

    [System.Windows.Controls.Grid]::SetRow($cardsGrid, 2)
    [void]$mGrid.Children.Add($cardsGrid)

    # 4. LOG & PROGRESS SECTION
    $logBorder = New-Object System.Windows.Controls.Border
    $logBorder.Background = if ($global:isDark) { Brush("#090D16") } else { Brush("#F1F5F9") }
    $logBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#CBD5E1") }
    $logBorder.BorderThickness = New-Object System.Windows.Thickness(1)
    $logBorder.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $logBorder.Padding = New-Object System.Windows.Thickness(14)

    $logGrid = New-Object System.Windows.Controls.Grid
    $lr0 = New-Object System.Windows.Controls.RowDefinition; $lr0.Height = [System.Windows.GridLength]::Auto
    $lr1 = New-Object System.Windows.Controls.RowDefinition; $lr1.Height = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    [void]$logGrid.RowDefinitions.Add($lr0); [void]$logGrid.RowDefinitions.Add($lr1)

    $logHeadSp = New-Object System.Windows.Controls.StackPanel
    $logHeadT = New-Object System.Windows.Controls.TextBlock; $logHeadT.Text = "GÜVENLİK KONSOLU & TARAMA ÇIKTISI"; $logHeadT.FontSize = 10.5; $logHeadT.FontWeight = "Bold"; $logHeadT.Foreground = Brush("#38BDF8")
    $pBar = New-Object System.Windows.Controls.ProgressBar; $pBar.Height = 3; $pBar.Foreground = Brush("#0284C7"); $pBar.Background = Brush("Transparent"); $pBar.BorderThickness = New-Object System.Windows.Thickness(0); $pBar.Margin = New-Object System.Windows.Thickness(0,6,0,8); $pBar.Visibility = [System.Windows.Visibility]::Collapsed
    [void]$logHeadSp.Children.Add($logHeadT); [void]$logHeadSp.Children.Add($pBar)
    [System.Windows.Controls.Grid]::SetRow($logHeadSp, 0); [void]$logGrid.Children.Add($logHeadSp)

    $logScroll = New-Object System.Windows.Controls.ScrollViewer; $logScroll.VerticalScrollBarVisibility = "Auto"
    $txtLog = New-Object System.Windows.Controls.TextBox
    $txtLog.Background = Brush("Transparent"); $txtLog.BorderThickness = New-Object System.Windows.Thickness(0)
    $txtLog.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#334155") }
    $txtLog.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas")
    $txtLog.FontSize = 11; $txtLog.IsReadOnly = $true; $txtLog.TextWrapping = "Wrap"
    $txtLog.Text = "Hazır. Yukarıdaki işlem kartlarından birine tıklayarak işlemi başlatabilirsiniz.`nWindows Defender motoru arka planda sessiz ve optimize şekilde yürütülür."
    $logScroll.Content = $txtLog
    [System.Windows.Controls.Grid]::SetRow($logScroll, 1); [void]$logGrid.Children.Add($logScroll)

    $logBorder.Child = $logGrid
    [System.Windows.Controls.Grid]::SetRow($logBorder, 3)
    [void]$mGrid.Children.Add($logBorder)

    # 5. FOOTER
    $footGrid = New-Object System.Windows.Controls.Grid
    $footGrid.Margin = New-Object System.Windows.Thickness(0, 14, 0, 0)
    $fc0 = New-Object System.Windows.Controls.ColumnDefinition; $fc0.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $fc1 = New-Object System.Windows.Controls.ColumnDefinition; $fc1.Width = [System.Windows.GridLength]::Auto
    [void]$footGrid.ColumnDefinitions.Add($fc0); [void]$footGrid.ColumnDefinitions.Add($fc1)

    $footHint = New-Object System.Windows.Controls.TextBlock
    $footHint.Text = "💡 Güvenlik Notu: Tarama sırasında bilgisayarınızı normal şekilde kullanmaya devam edebilirsiniz."
    $footHint.FontSize = 11; $footHint.Foreground = Brush("#64748B"); $footHint.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($footHint, 0); [void]$footGrid.Children.Add($footHint)

    $btnDClose = New-Object System.Windows.Controls.Border
    $btnDClose.CornerRadius = New-Object System.Windows.CornerRadius(7)
    $btnDClose.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
    $btnDClose.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $btnDClose.BorderThickness = New-Object System.Windows.Thickness(1)
    $btnDClose.Padding = New-Object System.Windows.Thickness(18, 7, 18, 7)
    $btnDClose.Cursor = "Hand"
    $btnDCloseTxt = New-Object System.Windows.Controls.TextBlock; $btnDCloseTxt.Text = "✕  Pencereyi Kapat"; $btnDCloseTxt.FontSize = 11.5; $btnDCloseTxt.FontWeight = "SemiBold"; $btnDCloseTxt.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#475569") }
    $btnDClose.Child = $btnDCloseTxt
    $btnDClose.Add_MouseEnter({ param($s,$e) $s.Background = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") } })
    $btnDClose.Add_MouseLeave({ param($s,$e) $s.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") } })
    $btnDClose.Add_MouseLeftButtonUp({ $dWin.Close() })
    [System.Windows.Controls.Grid]::SetColumn($btnDClose, 1); [void]$footGrid.Children.Add($btnDClose)

    [System.Windows.Controls.Grid]::SetRow($footGrid, 4)
    [void]$mGrid.Children.Add($footGrid)

    # 6. SCAN EXECUTION ROUTINE (NO CMD WINDOW! 100% SILENT BACKGROUND PROCESS)
    $mpCmdPath = "C:\Program Files\Windows Defender\MpCmdRun.exe"
    if (-not (Test-Path $mpCmdPath)) {
        $mpCmdPath = (Get-ChildItem "C:\ProgramData\Microsoft\Windows Defender\Platform" -Filter "MpCmdRun.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $elapsedSec = 0
    $timer.Add_Tick({
        $elapsedSec++
        $m = [Math]::Floor($elapsedSec / 60)
        $s = $elapsedSec % 60
        $sCol3Val.Text = "{0:D2}:{1:D2}" -f [int]$m, [int]$s
    })

    $RunSilentDefender = {
        param([string]$scanArg, [string]$actionName)

        $cardQuick.IsEnabled = $false; $cardFull.IsEnabled = $false; $cardUpd.IsEnabled = $false; $cardOpen.IsEnabled = $false
        $pBar.IsIndeterminate = $true; $pBar.Visibility = [System.Windows.Visibility]::Visible
        $sCol1Val.Text = "● $actionName..."; $sCol1Val.Foreground = Brush("#F59E0B")
        $txtLog.Text = "[$([DateTime]::Now.ToString('HH:mm:ss'))] $actionName başlatıldı... Lütfen bekleyin.`n"

        $elapsedSec = 0
        $sCol3Val.Text = "00:00"
        $timer.Start()

        $activeMpPath = $mpCmdPath
        $workerArg = @{
            MpPath = $activeMpPath
            ScanArg = $scanArg
            Action = $actionName
        }

        $bgWorker = New-Object System.ComponentModel.BackgroundWorker
        $bgWorker.DoWork += {
            param($s, $e)
            $wArg = $e.Argument
            $exe = $wArg.MpPath
            $arg = $wArg.ScanArg
            $action = $wArg.Action

            $outText = ""
            $errCode = 0

            # 1. Oncelik: MpCmdRun.exe
            if ($exe -and (Test-Path $exe)) {
                try {
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = $exe
                    $psi.Arguments = $arg
                    $psi.UseShellExecute = $false
                    $psi.RedirectStandardOutput = $true
                    $psi.RedirectStandardError = $true
                    $psi.CreateNoWindow = $true
                    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

                    $proc = [System.Diagnostics.Process]::Start($psi)
                    $outTask = $proc.StandardOutput.ReadToEndAsync()
                    $errTask = $proc.StandardError.ReadToEndAsync()
                    $proc.WaitForExit()
                    $errCode = $proc.ExitCode
                    $outText = if ($outTask.IsCompleted -or $outTask.Wait(4000)) { $outTask.Result } else { "" }
                    $errText = if ($errTask.IsCompleted -or $errTask.Wait(4000)) { $errTask.Result } else { "" }
                    if ($errText) { $outText += "`n" + $errText }
                } catch {
                    $outText = "MpCmdRun hatasi: " + $_.Exception.Message
                    $errCode = -1
                }
            } else {
                # 2. Alternatif: PowerShell Defender Modulu
                try {
                    if ($arg -match 'ScanType 1') {
                        Start-MpScan -ScanType QuickScan -ErrorAction Stop
                        $outText = "Hızlı tarama tamamlandı."
                    } elseif ($arg -match 'ScanType 2') {
                        Start-MpScan -ScanType FullScan -ErrorAction Stop
                        $outText = "Tam tarama tamamlandı."
                    } elseif ($arg -match 'SignatureUpdate') {
                        Update-MpSignature -ErrorAction Stop
                        $outText = "İmza tanımları güncellendi."
                    }
                    $errCode = 0
                } catch {
                    $outText = "Defender komut hatası: " + $_.Exception.Message
                    $errCode = 1
                }
            }

            $e.Result = @{
                ExitCode = $errCode
                Output = $outText
                Action = $action
            }
        }

        $bgWorker.RunWorkerCompleted += {
            param($s, $e)
            $timer.Stop()
            $res = $e.Result
            $cardQuick.IsEnabled = $true; $cardFull.IsEnabled = $true; $cardUpd.IsEnabled = $true; $cardOpen.IsEnabled = $true
            $pBar.Visibility = [System.Windows.Visibility]::Collapsed

            $fullOut = "$($res.Output)".Trim()
            if ($fullOut) {
                $txtLog.Text += "`n$fullOut`n"
            }

            if ($res.ExitCode -eq 0) {
                $sCol1Val.Text = "● Koruma Aktif (Temiz)"; $sCol1Val.Foreground = Brush("#10B981")
                $sCol2Val.Text = "0 Tehdit"; $sCol2Val.Foreground = Brush("#10B981")
                $txtLog.Text += "[$([DateTime]::Now.ToString('HH:mm:ss'))] $($res.Action) başarıyla tamamlandı. Tehdit tespit edilmedi.`n"
            } elseif ($res.ExitCode -eq 2) {
                $sCol1Val.Text = "● Tehdit Tespit Edildi!"; $sCol1Val.Foreground = Brush("#EF4444")
                $sCol2Val.Text = "⚠️ Tehdit Var!"; $sCol2Val.Foreground = Brush("#EF4444")
                $txtLog.Text += "[$([DateTime]::Now.ToString('HH:mm:ss'))] DİKKAT: Sistemde güvenlik tehdidi tespit edildi!`n"
            } else {
                $sCol1Val.Text = "● Tamamlandı"; $sCol1Val.Foreground = Brush("#38BDF8")
                $txtLog.Text += "[$([DateTime]::Now.ToString('HH:mm:ss'))] $($res.Action) tamamlandı (Kod: $($res.ExitCode)).`n"
            }
            $txtLog.ScrollToEnd()
        }

        $bgWorker.RunWorkerAsync($workerArg)
    }

    $cardQuick.Add_MouseLeftButtonUp({ & $RunSilentDefender "-Scan -ScanType 1" "Hızlı Tarama" })
    $cardFull.Add_MouseLeftButtonUp({ & $RunSilentDefender "-Scan -ScanType 2" "Tam Tarama" })
    $cardUpd.Add_MouseLeftButtonUp({ & $RunSilentDefender "-SignatureUpdate" "İmza Güncelleme" })
    $cardOpen.Add_MouseLeftButtonUp({
        try { Start-Process "windowsdefender:" } catch { [System.Windows.MessageBox]::Show($_.Exception.Message) }
    })

    $mBorder.Child = $mGrid
    $dWin.Content = $mBorder
    [void]$dWin.ShowDialog()
}

function Show-DiskCleanerModal {
    function Brush([string]$hex) {
        try {
            return [System.Windows.Media.BrushConverter]::new().ConvertFromString($hex)
        } catch {
            return [System.Windows.Media.Brushes]::Transparent
        }
    }

    function Format-CleanerBytes([double]$bytes) {
        if ($bytes -le 0) { return "0 B" }
        if ($bytes -lt 1KB) { return "$bytes B" }
        if ($bytes -lt 1MB) { return "$([Math]::Round($bytes / 1KB, 1)) KB" }
        if ($bytes -lt 1GB) { return "$([Math]::Round($bytes / 1MB, 1)) MB" }
        return "$([Math]::Round($bytes / 1GB, 2)) GB"
    }

    $cleanerLogosDir = if ($global:localLogosDir -and (Test-Path $global:localLogosDir)) {
        $global:localLogosDir
    } elseif (Test-Path "c:\projem\logolar") {
        "c:\projem\logolar"
    } elseif (Test-Path "$PSScriptRoot\logolar") {
        "$PSScriptRoot\logolar"
    } else {
        ""
    }

    $cWin = New-Object System.Windows.Window
    $cWin.Title = "Sistem ve Disk Temizleyici (PC Cleaner Pro)"
    $cWin.Width = 840
    $cWin.Height = 690
    $cWin.MinWidth = 760
    $cWin.MinHeight = 580
    $cWin.WindowStartupLocation = "CenterScreen"
    try { if ($window -and $window.IsVisible) { $cWin.Owner = $window } } catch {}
    $cWin.Background = if ($global:isDark) { Brush("#0B0E14") } else { Brush("#F0F2F5") }
    $cWin.Foreground = if ($global:isDark) { Brush("#F3F4F6") } else { Brush("#0F172A") }

    $gridMain = New-Object System.Windows.Controls.Grid
    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::Auto
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::Auto
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::Auto
    $r3 = New-Object System.Windows.Controls.RowDefinition; $r3.Height = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $r4 = New-Object System.Windows.Controls.RowDefinition; $r4.Height = [System.Windows.GridLength]::Auto
    [void]$gridMain.RowDefinitions.Add($r0)
    [void]$gridMain.RowDefinitions.Add($r1)
    [void]$gridMain.RowDefinitions.Add($r2)
    [void]$gridMain.RowDefinitions.Add($r3)
    [void]$gridMain.RowDefinitions.Add($r4)

    # 1. HEADER
    $headerBorder = New-Object System.Windows.Controls.Border
    $headerBorder.Background = if ($global:isDark) { Brush("#111622") } else { Brush("#FFFFFF") }
    $headerBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
    $headerBorder.BorderThickness = New-Object System.Windows.Thickness(0,0,0,1)
    $headerBorder.Padding = New-Object System.Windows.Thickness(24, 18, 24, 18)
    [System.Windows.Controls.Grid]::SetRow($headerBorder, 0)
    [void]$gridMain.Children.Add($headerBorder)

    $hGrid = New-Object System.Windows.Controls.Grid
    $hCol0 = New-Object System.Windows.Controls.ColumnDefinition; $hCol0.Width = [System.Windows.GridLength]::Auto
    $hCol1 = New-Object System.Windows.Controls.ColumnDefinition; $hCol1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $hCol2 = New-Object System.Windows.Controls.ColumnDefinition; $hCol2.Width = [System.Windows.GridLength]::Auto
    [void]$hGrid.ColumnDefinitions.Add($hCol0); [void]$hGrid.ColumnDefinitions.Add($hCol1); [void]$hGrid.ColumnDefinitions.Add($hCol2)

    $logoB = New-Object System.Windows.Controls.Border
    $logoB.Width = 46; $logoB.Height = 46
    $logoB.CornerRadius = New-Object System.Windows.CornerRadius(12)
    $logoB.Background = if ($global:isDark) { Brush("#102336") } else { Brush("#E0F2FE") }
    $logoB.BorderBrush = Brush("#0284C7")
    $logoB.BorderThickness = New-Object System.Windows.Thickness(1)
    $logoB.Margin = New-Object System.Windows.Thickness(0,0,14,0)

    $logoTxt = New-Object System.Windows.Controls.TextBlock
    $logoTxt.Text = "🧹"
    $logoTxt.FontSize = 22
    $logoTxt.HorizontalAlignment = "Center"
    $logoTxt.VerticalAlignment = "Center"
    $logoB.Child = $logoTxt
    [System.Windows.Controls.Grid]::SetColumn($logoB, 0)
    [void]$hGrid.Children.Add($logoB)

    $titleSp = New-Object System.Windows.Controls.StackPanel
    $titleSp.VerticalAlignment = "Center"
    $t1 = New-Object System.Windows.Controls.TextBlock
    $t1.Text = "Sistem & Disk Temizleyici"
    $t1.FontSize = 18
    $t1.FontWeight = "Bold"
    $t1.Foreground = if ($global:isDark) { Brush("#F9FAFB") } else { Brush("#0F172A") }
    [void]$titleSp.Children.Add($t1)

    $t2 = New-Object System.Windows.Controls.TextBlock
    $t2.Text = "Gereksiz geçici dosyaları, sistem ve tarayıcı önbelleklerini temizleyerek disk alanı açın"
    $t2.FontSize = 12
    $t2.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    $t2.Margin = New-Object System.Windows.Thickness(0, 2, 0, 0)
    [void]$titleSp.Children.Add($t2)
    [System.Windows.Controls.Grid]::SetColumn($titleSp, 1)
    [void]$hGrid.Children.Add($titleSp)

    # Total Junk Box
    $sumBorder = New-Object System.Windows.Controls.Border
    $sumBorder.CornerRadius = New-Object System.Windows.CornerRadius(10)
    $sumBorder.Background = if ($global:isDark) { Brush("#182030") } else { Brush("#F1F5F9") }
    $sumBorder.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $sumBorder.BorderThickness = New-Object System.Windows.Thickness(1)
    $sumBorder.Padding = New-Object System.Windows.Thickness(16, 8, 16, 8)
    $sumBorder.VerticalAlignment = "Center"

    $sumSp = New-Object System.Windows.Controls.StackPanel
    $sumSp.HorizontalAlignment = "Right"
    $sumLbl = New-Object System.Windows.Controls.TextBlock
    $sumLbl.Text = "BULUNAN GEREKSİZ ALAN"
    $sumLbl.FontSize = 10
    $sumLbl.FontWeight = "SemiBold"
    $sumLbl.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    $sumLbl.HorizontalAlignment = "Right"
    [void]$sumSp.Children.Add($sumLbl)

    $txtTotalJunk = New-Object System.Windows.Controls.TextBlock
    $txtTotalJunk.Text = "Hesaplanıyor..."
    $txtTotalJunk.FontSize = 20
    $txtTotalJunk.FontWeight = "Bold"
    $txtTotalJunk.Foreground = Brush("#38BDF8")
    $txtTotalJunk.HorizontalAlignment = "Right"
    [void]$sumSp.Children.Add($txtTotalJunk)
    $sumBorder.Child = $sumSp

    [System.Windows.Controls.Grid]::SetColumn($sumBorder, 2)
    [void]$hGrid.Children.Add($sumBorder)
    $headerBorder.Child = $hGrid

    # 2. ACTION BAR (Select All + Buttons)
    $actionBorder = New-Object System.Windows.Controls.Border
    $actionBorder.Background = if ($global:isDark) { Brush("#0E131F") } else { Brush("#F8FAFC") }
    $actionBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
    $actionBorder.BorderThickness = New-Object System.Windows.Thickness(0, 0, 0, 1)
    $actionBorder.Padding = New-Object System.Windows.Thickness(24, 10, 24, 10)
    [System.Windows.Controls.Grid]::SetRow($actionBorder, 1)
    [void]$gridMain.Children.Add($actionBorder)

    $actGrid = New-Object System.Windows.Controls.Grid
    $aCol0 = New-Object System.Windows.Controls.ColumnDefinition; $aCol0.Width = [System.Windows.GridLength]::Auto
    $aCol1 = New-Object System.Windows.Controls.ColumnDefinition; $aCol1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $aCol2 = New-Object System.Windows.Controls.ColumnDefinition; $aCol2.Width = [System.Windows.GridLength]::Auto
    [void]$actGrid.ColumnDefinitions.Add($aCol0); [void]$actGrid.ColumnDefinitions.Add($aCol1); [void]$actGrid.ColumnDefinitions.Add($aCol2)

    $cleanerBtnTpl = [System.Windows.Markup.XamlReader]::Parse('<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.88"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.72"/></Trigger></ControlTemplate.Triggers></ControlTemplate>')

    # Modern Select All Button
    $btnSelectAll = New-Object System.Windows.Controls.Button
    $btnSelectAll.Content = "✓ Tümünü Seç / Kaldır"
    $btnSelectAll.Padding = New-Object System.Windows.Thickness(14, 7, 14, 7)
    $btnSelectAll.FontSize = 12
    $btnSelectAll.FontWeight = "SemiBold"
    $btnSelectAll.Cursor = "Hand"
    $btnSelectAll.Template = $cleanerBtnTpl
    $btnSelectAll.Background = if ($global:isDark) { Brush("#1A2234") } else { Brush("#EDF2F7") }
    $btnSelectAll.Foreground = if ($global:isDark) { Brush("#E2E8F0") } else { Brush("#1E293B") }
    $btnSelectAll.BorderBrush = if ($global:isDark) { Brush("#2E3E5B") } else { Brush("#CBD5E1") }
    $btnSelectAll.BorderThickness = New-Object System.Windows.Thickness(1)
    $btnSelectAll.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($btnSelectAll, 0)
    [void]$actGrid.Children.Add($btnSelectAll)

    # Action Buttons on the Right
    $actBtnSp = New-Object System.Windows.Controls.StackPanel
    $actBtnSp.Orientation = "Horizontal"
    $actBtnSp.HorizontalAlignment = "Right"
    $actBtnSp.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($actBtnSp, 2)

    # Windows Disk Cleanup button (cleanmgr)
    $btnWinClean = New-Object System.Windows.Controls.Button
    $btnWinClean.Content = "⚙️ Windows Temizleme (cleanmgr)"
    $btnWinClean.Padding = New-Object System.Windows.Thickness(14, 7, 14, 7)
    $btnWinClean.FontSize = 12
    $btnWinClean.FontWeight = "SemiBold"
    $btnWinClean.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
    $btnWinClean.Cursor = "Hand"
    $btnWinClean.Template = $cleanerBtnTpl
    $btnWinClean.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#EDF2F7") }
    $btnWinClean.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#475569") }
    $btnWinClean.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $btnWinClean.BorderThickness = New-Object System.Windows.Thickness(1)
    $btnWinClean.ToolTip = "Gelişmiş dahili Windows Temizleme Aracı'nı (cleanmgr.exe) açar."
    $btnWinClean.Add_Click({ Start-Process "cleanmgr.exe" -ArgumentList "/d C:" })
    [void]$actBtnSp.Children.Add($btnWinClean)

    # Rescan Button
    $btnScan = New-Object System.Windows.Controls.Button
    $btnScan.Content = "🔄 Yeniden Tara"
    $btnScan.Padding = New-Object System.Windows.Thickness(14, 7, 14, 7)
    $btnScan.FontSize = 12
    $btnScan.FontWeight = "SemiBold"
    $btnScan.Margin = New-Object System.Windows.Thickness(0, 0, 10, 0)
    $btnScan.Cursor = "Hand"
    $btnScan.Template = $cleanerBtnTpl
    $btnScan.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#EDF2F7") }
    $btnScan.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    $btnScan.BorderBrush = if ($global:isDark) { Brush("#38BDF8") } else { Brush("#0284C7") }
    $btnScan.BorderThickness = New-Object System.Windows.Thickness(1)
    [void]$actBtnSp.Children.Add($btnScan)

    # Clean Button
    $btnClean = New-Object System.Windows.Controls.Button
    $btnClean.Content = "🚀 Seçilenleri Temizle"
    $btnClean.Padding = New-Object System.Windows.Thickness(18, 7, 18, 7)
    $btnClean.FontSize = 12.5
    $btnClean.FontWeight = "Bold"
    $btnClean.Cursor = "Hand"
    $btnClean.Template = $cleanerBtnTpl
    $btnClean.Background = Brush("#0284C7")
    $btnClean.Foreground = Brush("#FFFFFF")
    $btnClean.BorderThickness = New-Object System.Windows.Thickness(0)
    [void]$actBtnSp.Children.Add($btnClean)

    [void]$actGrid.Children.Add($actBtnSp)
    $actionBorder.Child = $actGrid

    # 3. PROGRESS BAR STRIP
    $progBorder = New-Object System.Windows.Controls.Border
    $progBorder.Background = if ($global:isDark) { Brush("#151D2A") } else { Brush("#E0F2FE") }
    $progBorder.Padding = New-Object System.Windows.Thickness(24, 6, 24, 6)
    $progBorder.Visibility = [System.Windows.Visibility]::Collapsed
    [System.Windows.Controls.Grid]::SetRow($progBorder, 2)
    [void]$gridMain.Children.Add($progBorder)

    $pSp = New-Object System.Windows.Controls.StackPanel
    $pTxt = New-Object System.Windows.Controls.TextBlock
    $pTxt.Text = "Taranıyor..."
    $pTxt.FontSize = 11.5
    $pTxt.Foreground = Brush("#0284C7")
    $pTxt.Margin = New-Object System.Windows.Thickness(0, 0, 0, 4)
    [void]$pSp.Children.Add($pTxt)

    $pBar = New-Object System.Windows.Controls.ProgressBar
    $pBar.IsIndeterminate = $true
    $pBar.Height = 3
    $pBar.Foreground = Brush("#0284C7")
    $pBar.Background = if ($global:isDark) { Brush("#233145") } else { Brush("#BAE6FD") }
    $pBar.BorderThickness = New-Object System.Windows.Thickness(0)
    [void]$pSp.Children.Add($pBar)
    $progBorder.Child = $pSp

    # 4. SCROLLABLE LIST OF CATEGORIES
    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.VerticalScrollBarVisibility = "Auto"
    $scroll.HorizontalScrollBarVisibility = "Disabled"
    $scroll.Padding = New-Object System.Windows.Thickness(24, 16, 24, 16)
    
    # Modern Slim Scrollbar Template
    try {
        $sbThumbColor = if ($global:isDark) { "#334155" } else { "#CBD5E1" }
        $sbXaml = @"
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="ScrollBar">
    <Setter Property="Width" Value="8"/>
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="ScrollBar">
                <Grid Background="Transparent">
                    <Track x:Name="PART_Track" IsDirectionReversed="true">
                        <Track.Thumb>
                            <Thumb>
                                <Thumb.Template>
                                    <ControlTemplate TargetType="Thumb">
                                        <Border CornerRadius="4" Background="$sbThumbColor"/>
                                    </ControlTemplate>
                                </Thumb.Template>
                            </Thumb>
                        </Track.Thumb>
                    </Track>
                </Grid>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
"@
        $scroll.Resources.Add([System.Windows.Controls.Primitives.ScrollBar], [System.Windows.Markup.XamlReader]::Parse($sbXaml))
    } catch {}

    [System.Windows.Controls.Grid]::SetRow($scroll, 3)
    [void]$gridMain.Children.Add($scroll)

    $listSp = New-Object System.Windows.Controls.StackPanel
    $scroll.Content = $listSp

    # 5. FOOTER INFO
    $footerBorder = New-Object System.Windows.Controls.Border
    $footerBorder.Background = if ($global:isDark) { Brush("#0E131F") } else { Brush("#F8FAFC") }
    $footerBorder.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
    $footerBorder.BorderThickness = New-Object System.Windows.Thickness(0,1,0,0)
    $footerBorder.Padding = New-Object System.Windows.Thickness(24, 12, 24, 12)
    [System.Windows.Controls.Grid]::SetRow($footerBorder, 4)
    [void]$gridMain.Children.Add($footerBorder)

    $fGrid = New-Object System.Windows.Controls.Grid
    $fCol0 = New-Object System.Windows.Controls.ColumnDefinition; $fCol0.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $fCol1 = New-Object System.Windows.Controls.ColumnDefinition; $fCol1.Width = [System.Windows.GridLength]::Auto
    [void]$fGrid.ColumnDefinitions.Add($fCol0); [void]$fGrid.ColumnDefinitions.Add($fCol1)

    $fHint = New-Object System.Windows.Controls.TextBlock
    $fHint.Text = "💡 İpucu: Temizlik yalnızca önbellek ve geçici dosyaları siler, kişisel belgelerinize ve şifrelerinize dokunmaz."
    $fHint.FontSize = 11.5
    $fHint.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
    $fHint.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($fHint, 0)
    [void]$fGrid.Children.Add($fHint)

    $btnClose = New-Object System.Windows.Controls.Button
    $btnClose.Content = "Pencereyi Kapat"
    $btnClose.Padding = New-Object System.Windows.Thickness(18, 7, 18, 7)
    $btnClose.FontSize = 12
    $btnClose.FontWeight = "SemiBold"
    $btnClose.Cursor = "Hand"
    $btnClose.Template = $cleanerBtnTpl
    $btnClose.Background = if ($global:isDark) { Brush("#1E293B") } else { Brush("#EDF2F7") }
    $btnClose.Foreground = if ($global:isDark) { Brush("#CBD5E1") } else { Brush("#475569") }
    $btnClose.BorderBrush = if ($global:isDark) { Brush("#334155") } else { Brush("#CBD5E1") }
    $btnClose.BorderThickness = New-Object System.Windows.Thickness(1)
    $btnClose.Add_Click({ $cWin.Close() })
    [System.Windows.Controls.Grid]::SetColumn($btnClose, 1)
    [void]$fGrid.Children.Add($btnClose)
    $footerBorder.Child = $fGrid

    # CATEGORIES DEFINITION (Only Installed Browsers are Included!)
    $categories = [System.Collections.ArrayList]::new()

    # System categories with vibrant color styles
    [void]$categories.Add(@{
        Id = "UserTemp"; Title = "Kullanıcı Geçici Dosyaları (User Temp)"; Desc = "Kullanıcı profilinizdeki geçici uygulama çalışma ve önbellek dosyaları"
        Icon = "📁"; IconColor = "#FBBF24"; BoxBg = if ($global:isDark) { "#2D1C08" } else { "#FEF3C7" }; BoxBorder = "#F59E0B"
        IsLogo = $false; LogoFile = $null; Group = "Sistem Önbellekleri"; Paths = @($env:TEMP); Filter = "*"; Type = "Normal"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })
    [void]$categories.Add(@{
        Id = "WinTemp"; Title = "Windows Sistem Geçici Dosyaları (System Temp)"; Desc = "Windows işletim sisteminin ortak geçici çalışma dizini (C:\Windows\Temp)"
        Icon = "⚙️"; IconColor = "#60A5FA"; BoxBg = if ($global:isDark) { "#0C2340" } else { "#DBEAFE" }; BoxBorder = "#3B82F6"
        IsLogo = $false; LogoFile = $null; Group = "Sistem Önbellekleri"; Paths = @("$env:SystemRoot\Temp"); Filter = "*"; Type = "Normal"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })
    [void]$categories.Add(@{
        Id = "Prefetch"; Title = "Windows Prefetch (Ön Yükleme Dosyaları)"; Desc = "Eski uygulama açılış izleri ve önbellek dizinleri"
        Icon = "⚡"; IconColor = "#C084FC"; BoxBg = if ($global:isDark) { "#20103A" } else { "#F3E8FF" }; BoxBorder = "#8B5CF6"
        IsLogo = $false; LogoFile = $null; Group = "Sistem Önbellekleri"; Paths = @("$env:SystemRoot\Prefetch"); Filter = "*"; Type = "Normal"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })
    [void]$categories.Add(@{
        Id = "RecycleBin"; Title = "Geri Dönüşüm Kutusu (Recycle Bin)"; Desc = "Silinmiş ve çöp kutusunda bekleyen tüm dosyalar"
        Icon = "🗑️"; IconColor = "#F87171"; BoxBg = if ($global:isDark) { "#2B0E14" } else { "#FEE2E2" }; BoxBorder = "#EF4444"
        IsLogo = $false; LogoFile = $null; Group = "Kullanıcı Dosyaları"; Paths = @(); Filter = "*"; Type = "RecycleBin"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })
    [void]$categories.Add(@{
        Id = "WinUpdate"; Title = "Windows Güncelleme İndirme Önbelleği"; Desc = "Başarıyla yüklenmiş eski Windows Update kurulum paketleri"
        Icon = "🔄"; IconColor = "#34D399"; BoxBg = if ($global:isDark) { "#042A1D" } else { "#D1FAE5" }; BoxBorder = "#10B981"
        IsLogo = $false; LogoFile = $null; Group = "Sistem Bakımı"; Paths = @("$env:SystemRoot\SoftwareDistribution\Download"); Filter = "*"; Type = "Normal"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })
    [void]$categories.Add(@{
        Id = "Thumbnails"; Title = "Küçük Resim (Thumbnail) Önbelleği"; Desc = "Windows Gezgini resim ve video küçük önizleme veritabanı"
        Icon = "🖼️"; IconColor = "#38BDF8"; BoxBg = if ($global:isDark) { "#072635" } else { "#E0F2FE" }; BoxBorder = "#06B6D4"
        IsLogo = $false; LogoFile = $null; Group = "Görsel Önbellekler"; Paths = @((Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Explorer")); Filter = "thumbcache_*.db"; Type = "FilterFiles"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })
    [void]$categories.Add(@{
        Id = "CrashDumps"; Title = "Hata Raporları ve Crash Dump Dosyaları"; Desc = "Uygulama çökmelerinde Windows tarafından kaydedilen dmp döküm dosyaları"
        Icon = "💥"; IconColor = "#FB923C"; BoxBg = if ($global:isDark) { "#2B1208" } else { "#FFEDD5" }; BoxBorder = "#F97316"
        IsLogo = $false; LogoFile = $null; Group = "Sistem Bakımı"; Paths = @((Join-Path $env:LOCALAPPDATA "CrashDumps"), (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\WER")); Filter = "*"; Type = "Normal"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })
    [void]$categories.Add(@{
        Id = "SystemLogs"; Title = "Sistem & Kurulum Log Dosyaları"; Desc = "Eski yazılım kurulum ve Windows tanılama günlük dosyaları"
        Icon = "📋"; IconColor = "#818CF8"; BoxBg = if ($global:isDark) { "#161933" } else { "#E0E7FF" }; BoxBorder = "#6366F1"
        IsLogo = $false; LogoFile = $null; Group = "Sistem Bakımı"; Paths = @("$env:SystemRoot\Logs"); Filter = "*"; Type = "Normal"
        IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
    })

    # DYNAMIC BROWSER FILTERING: ONLY ADD IF ACTUALLY INSTALLED!
    $chromeData = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
    if (Test-Path $chromeData) {
        [void]$categories.Add(@{
            Id = "ChromeCache"; Title = "Google Chrome Önbelleği"; Desc = "Google Chrome web tarayıcısının geçici internet önbellek dosyaları"
            Icon = "🌐"; IconColor = "#FBBF24"; BoxBg = if ($global:isDark) { "#1A1E26" } else { "#F1F5F9" }; BoxBorder = "#E2E8F0"
            IsLogo = $true; LogoFile = "3840px-Google_Chrome_icon_Februa.png"; Group = "Web Tarayıcıları"; Paths = @((Join-Path $chromeData "Default\Cache"), (Join-Path $chromeData "Default\Code Cache")); Filter = "*"; Type = "Normal"
            IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
        })
    }

    $edgeData = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data"
    if (Test-Path $edgeData) {
        [void]$categories.Add(@{
            Id = "EdgeCache"; Title = "Microsoft Edge Önbelleği"; Desc = "Microsoft Edge web tarayıcısının geçici internet önbellek dosyaları"
            Icon = "🌐"; IconColor = "#38BDF8"; BoxBg = if ($global:isDark) { "#1A1E26" } else { "#F1F5F9" }; BoxBorder = "#E2E8F0"
            IsLogo = $true; LogoFile = "Microsoft_Edge_logo_2019.png"; Group = "Web Tarayıcıları"; Paths = @((Join-Path $edgeData "Default\Cache"), (Join-Path $edgeData "Default\Code Cache")); Filter = "*"; Type = "Normal"
            IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
        })
    }

    $firefoxData = Join-Path $env:APPDATA "Mozilla\Firefox"
    if (Test-Path $firefoxData) {
        [void]$categories.Add(@{
            Id = "FirefoxCache"; Title = "Mozilla Firefox Önbelleği"; Desc = "Mozilla Firefox tarayıcısı profil önbellekleri"
            Icon = "🌐"; IconColor = "#FB923C"; BoxBg = if ($global:isDark) { "#1A1E26" } else { "#F1F5F9" }; BoxBorder = "#E2E8F0"
            IsLogo = $true; LogoFile = "Firefox_logo,_2017.png"; Group = "Web Tarayıcıları"; Paths = @((Join-Path $env:LOCALAPPDATA "Mozilla\Firefox\Profiles")); Filter = "*"; Type = "Firefox"
            IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
        })
    }

    $braveData = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data"
    if (Test-Path $braveData) {
        [void]$categories.Add(@{
            Id = "BraveCache"; Title = "Brave Tarayıcı Önbelleği"; Desc = "Brave tarayıcısının web önbellekleri ve indirme geçmişi parçaları"
            Icon = "🦁"; IconColor = "#F97316"; BoxBg = if ($global:isDark) { "#2B1208" } else { "#FFEDD5" }; BoxBorder = "#F97316"
            IsLogo = $true; LogoFile = "brave.png"; Group = "Web Tarayıcıları"; Paths = @((Join-Path $braveData "Default\Cache")); Filter = "*"; Type = "Normal"
            IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
        })
    }

    $operaData = Join-Path $env:APPDATA "Opera Software"
    if (Test-Path $operaData) {
        [void]$categories.Add(@{
            Id = "OperaCache"; Title = "Opera Tarayıcı Önbelleği"; Desc = "Opera tarayıcısının web önbellekleri"
            Icon = "🌐"; IconColor = "#EF4444"; BoxBg = if ($global:isDark) { "#1A1E26" } else { "#F1F5F9" }; BoxBorder = "#E2E8F0"
            IsLogo = $true; LogoFile = "opera_browser_logo_icon_152972.png"; Group = "Web Tarayıcıları"; Paths = @((Join-Path $env:LOCALAPPDATA "Opera Software\Opera Stable\Cache")); Filter = "*"; Type = "Normal"
            IsChecked = $true; ChkBorder = $null; ChkMark = $null; BadgeBorder = $null; BadgeTxt = $null; CountTxt = $null; ScannedBytes = 0.0; ScannedFiles = 0
        })
    }

    # BUILD CATEGORY ROW CONTROLS
    foreach ($cat in $categories) {
        $rowB = New-Object System.Windows.Controls.Border
        $rowB.Background = if ($global:isDark) { Brush("#111722") } else { Brush("#FFFFFF") }
        $rowB.BorderBrush = if ($global:isDark) { Brush("#1E293B") } else { Brush("#E2E8F0") }
        $rowB.BorderThickness = New-Object System.Windows.Thickness(1)
        $rowB.CornerRadius = New-Object System.Windows.CornerRadius(10)
        $rowB.Padding = New-Object System.Windows.Thickness(14, 11, 14, 11)
        $rowB.Margin = New-Object System.Windows.Thickness(0, 0, 0, 8)
        $rowB.Cursor = "Hand"

        $rowGrid = New-Object System.Windows.Controls.Grid
        $rc0 = New-Object System.Windows.Controls.ColumnDefinition; $rc0.Width = [System.Windows.GridLength]::Auto
        $rc1 = New-Object System.Windows.Controls.ColumnDefinition; $rc1.Width = [System.Windows.GridLength]::Auto
        $rc2 = New-Object System.Windows.Controls.ColumnDefinition; $rc2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $rc3 = New-Object System.Windows.Controls.ColumnDefinition; $rc3.Width = [System.Windows.GridLength]::Auto
        [void]$rowGrid.ColumnDefinitions.Add($rc0)
        [void]$rowGrid.ColumnDefinitions.Add($rc1)
        [void]$rowGrid.ColumnDefinitions.Add($rc2)
        [void]$rowGrid.ColumnDefinitions.Add($rc3)

        # 1. Custom Sleek Checkbox
        $chkBorder = New-Object System.Windows.Controls.Border
        $chkBorder.Width = 20; $chkBorder.Height = 20
        $chkBorder.CornerRadius = New-Object System.Windows.CornerRadius(6)
        $chkBorder.Background = Brush("#0284C7")
        $chkBorder.BorderBrush = Brush("#38BDF8")
        $chkBorder.BorderThickness = New-Object System.Windows.Thickness(1.5)
        $chkBorder.Cursor = "Hand"
        $chkBorder.VerticalAlignment = "Center"
        $chkBorder.Margin = New-Object System.Windows.Thickness(0, 0, 12, 0)

        $chkMark = New-Object System.Windows.Controls.TextBlock
        $chkMark.Text = "✓"
        $chkMark.FontSize = 11.5
        $chkMark.FontWeight = "Bold"
        $chkMark.HorizontalAlignment = "Center"
        $chkMark.VerticalAlignment = "Center"
        $chkMark.Foreground = Brush("#FFFFFF")
        $chkBorder.Child = $chkMark

        $cat.ChkBorder = $chkBorder
        $cat.ChkMark = $chkMark
        [System.Windows.Controls.Grid]::SetColumn($chkBorder, 0)
        [void]$rowGrid.Children.Add($chkBorder)

        # 2. Vibrant Colored Icon Box (or Official Browser Logo)
        $icoB = New-Object System.Windows.Controls.Border
        $icoB.Width = 38; $icoB.Height = 38
        $icoB.CornerRadius = New-Object System.Windows.CornerRadius(9)
        $icoB.Margin = New-Object System.Windows.Thickness(0, 0, 12, 0)
        $icoB.VerticalAlignment = "Center"
        $icoB.Background = Brush($cat.BoxBg)
        $icoB.BorderBrush = Brush($cat.BoxBorder)
        $icoB.BorderThickness = New-Object System.Windows.Thickness(1)

        $logoLoaded = $false
        $fullLogoPath = if ($cleanerLogosDir -and $cat.LogoFile) { Join-Path $cleanerLogosDir $cat.LogoFile } else { "" }
        if ($fullLogoPath -and (Test-Path $fullLogoPath)) {
            try {
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.UriSource = [Uri]$fullLogoPath
                $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bmp.EndInit()
                $bmp.Freeze()
                $img = New-Object System.Windows.Controls.Image
                $img.Width = 24; $img.Height = 24
                $img.Source = $bmp
                $img.HorizontalAlignment = "Center"; $img.VerticalAlignment = "Center"
                $icoB.Child = $img
                $logoLoaded = $true
            } catch {}
        }
        if (-not $logoLoaded) {
            $bTxt = New-Object System.Windows.Controls.TextBlock
            $bTxt.Text = $cat.Icon
            $bTxt.FontSize = 18
            $bTxt.Foreground = Brush($cat.IconColor)
            $bTxt.HorizontalAlignment = "Center"
            $bTxt.VerticalAlignment = "Center"
            $icoB.Child = $bTxt
        }
        [System.Windows.Controls.Grid]::SetColumn($icoB, 1)
        [void]$rowGrid.Children.Add($icoB)

        # 3. Titles & Group
        $cTextSp = New-Object System.Windows.Controls.StackPanel
        $cTextSp.VerticalAlignment = "Center"

        $grpT = New-Object System.Windows.Controls.TextBlock
        $grpT.Text = $cat.Group.ToUpper()
        $grpT.FontSize = 9.5
        $grpT.FontWeight = "Bold"
        $grpT.Foreground = Brush("#38BDF8")
        $grpT.Margin = New-Object System.Windows.Thickness(0, 0, 0, 1)
        [void]$cTextSp.Children.Add($grpT)

        $cNameT = New-Object System.Windows.Controls.TextBlock
        $cNameT.Text = $cat.Title
        $cNameT.FontSize = 13.5
        $cNameT.FontWeight = "SemiBold"
        $cNameT.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
        [void]$cTextSp.Children.Add($cNameT)

        $cDescT = New-Object System.Windows.Controls.TextBlock
        $cDescT.Text = $cat.Desc
        $cDescT.FontSize = 11
        $cDescT.Foreground = if ($global:isDark) { Brush("#94A3B8") } else { Brush("#64748B") }
        $cDescT.Margin = New-Object System.Windows.Thickness(0, 2, 0, 0)
        [void]$cTextSp.Children.Add($cDescT)

        [System.Windows.Controls.Grid]::SetColumn($cTextSp, 2)
        [void]$rowGrid.Children.Add($cTextSp)

        # 4. Size & Count Badge
        $sizeSp = New-Object System.Windows.Controls.StackPanel
        $sizeSp.HorizontalAlignment = "Right"
        $sizeSp.VerticalAlignment = "Center"

        $badgeB = New-Object System.Windows.Controls.Border
        $badgeB.CornerRadius = New-Object System.Windows.CornerRadius(6)
        $badgeB.Padding = New-Object System.Windows.Thickness(10, 4, 10, 4)
        $badgeB.Background = if ($global:isDark) { Brush("#1A2234") } else { Brush("#E2E8F0") }

        $badgeT = New-Object System.Windows.Controls.TextBlock
        $badgeT.Text = "Hesaplanıyor..."
        $badgeT.FontSize = 12.5
        $badgeT.FontWeight = "Bold"
        $badgeT.Foreground = Brush("#38BDF8")
        $badgeB.Child = $badgeT
        [void]$sizeSp.Children.Add($badgeB)

        $countT = New-Object System.Windows.Controls.TextBlock
        $countT.Text = "0 dosya"
        $countT.FontSize = 10.5
        $countT.Foreground = if ($global:isDark) { Brush("#64748B") } else { Brush("#94A3B8") }
        $countT.HorizontalAlignment = "Right"
        $countT.Margin = New-Object System.Windows.Thickness(0, 2, 0, 0)
        [void]$sizeSp.Children.Add($countT)

        [System.Windows.Controls.Grid]::SetColumn($sizeSp, 3)
        [void]$rowGrid.Children.Add($sizeSp)

        $rowB.Child = $rowGrid
        [void]$listSp.Children.Add($rowB)

        $cat.BadgeBorder = $badgeB
        $cat.BadgeTxt = $badgeT
        $cat.CountTxt = $countT

        # CLICK TOGGLE CHECKBOX LOGIC
        $targetCat = $cat
        $toggleAction = {
            $targetCat.IsChecked = (-not $targetCat.IsChecked)
            if ($targetCat.IsChecked) {
                $targetCat.ChkBorder.Background = Brush("#0284C7")
                $targetCat.ChkBorder.BorderBrush = Brush("#38BDF8")
                $targetCat.ChkMark.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $targetCat.ChkBorder.Background = Brush("Transparent")
                $targetCat.ChkBorder.BorderBrush = if ($global:isDark) { Brush("#475569") } else { Brush("#94A3B8") }
                $targetCat.ChkMark.Visibility = [System.Windows.Visibility]::Collapsed
            }
            # Recalculate clean button state
            $selCount = @($categories | Where-Object { $_.IsChecked }).Count
            $btnClean.IsEnabled = ($selCount -gt 0 -and $txtTotalJunk.Text -ne "0 B" -and $txtTotalJunk.Text -ne "Hesaplanıyor...")
        }

        $chkBorder.Add_MouseDown($toggleAction)
        $rowB.Add_MouseDown($toggleAction)
    }

    # TOGGLE ALL BUTTON
    $btnSelectAll.Add_Click({
        $anyChecked = @($categories | Where-Object { $_.IsChecked }).Count -gt 0
        $newVal = (-not $anyChecked)
        foreach ($cat in $categories) {
            $cat.IsChecked = $newVal
            if ($newVal) {
                $cat.ChkBorder.Background = Brush("#0284C7")
                $cat.ChkBorder.BorderBrush = Brush("#38BDF8")
                $cat.ChkMark.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $cat.ChkBorder.Background = Brush("Transparent")
                $cat.ChkBorder.BorderBrush = if ($global:isDark) { Brush("#475569") } else { Brush("#94A3B8") }
                $cat.ChkMark.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
        $btnClean.IsEnabled = ($newVal -and $txtTotalJunk.Text -ne "0 B" -and $txtTotalJunk.Text -ne "Hesaplanıyor...")
    })

    # SCAN ROUTINE
    $ScanCategories = {
        $pTxt.Text = "Sistem ve geçici dosyalar taranıyor..."
        $progBorder.Visibility = [System.Windows.Visibility]::Visible
        $btnScan.IsEnabled = $false
        $btnClean.IsEnabled = $false
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

        $grandTotal = 0.0
        $grandFiles = 0

        foreach ($cat in $categories) {
            $catSize = 0.0
            $catFiles = 0
            $pTxt.Text = "$($cat.Title) taranıyor..."
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

            try {
                if ($cat.Type -eq "RecycleBin") {
                    $sh = New-Object -ComObject Shell.Application
                    $rb = $sh.Namespace(10)
                    $catFiles = $rb.Items().Count
                    foreach ($it in $rb.Items()) { $catSize += [double]$it.Size }
                } elseif ($cat.Type -eq "FilterFiles") {
                    foreach ($p in $cat.Paths) {
                        if (Test-Path $p) {
                            $m = Get-ChildItem -Path $p -Filter $cat.Filter -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                            if ($m -and $m.Sum) { $catSize += [double]$m.Sum; $catFiles += [int]$m.Count }
                        }
                    }
                } elseif ($cat.Type -eq "Firefox") {
                    foreach ($p in $cat.Paths) {
                        if (Test-Path $p) {
                            $c2Dirs = Get-ChildItem -Path $p -Filter "cache2" -Recurse -Directory -Force -ErrorAction SilentlyContinue
                            foreach ($c2 in $c2Dirs) {
                                $m = Get-ChildItem -Path $c2.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                                if ($m -and $m.Sum) { $catSize += [double]$m.Sum; $catFiles += [int]$m.Count }
                            }
                        }
                    }
                } else {
                    foreach ($p in $cat.Paths) {
                        if (Test-Path $p) {
                            $m = Get-ChildItem -Path $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                            if ($m -and $m.Sum) { $catSize += [double]$m.Sum; $catFiles += [int]$m.Count }
                        }
                    }
                }
            } catch {}

            $cat.ScannedBytes = $catSize
            $cat.ScannedFiles = $catFiles
            $grandTotal += $catSize
            $grandFiles += $catFiles

            if ($cat.BadgeTxt) {
                $cat.BadgeTxt.Text = Format-CleanerBytes $catSize
                $cat.CountTxt.Text = "$catFiles dosya"
                if ($catSize -gt 100MB) {
                    $cat.BadgeBorder.Background = if ($global:isDark) { Brush("#064E3B") } else { Brush("#DCFCE7") }
                    $cat.BadgeTxt.Foreground = if ($global:isDark) { Brush("#34D399") } else { Brush("#15803D") }
                } elseif ($catSize -gt 0) {
                    $cat.BadgeBorder.Background = if ($global:isDark) { Brush("#0F2942") } else { Brush("#E0F2FE") }
                    $cat.BadgeTxt.Foreground = if ($global:isDark) { Brush("#38BDF8") } else { Brush("#0284C7") }
                } else {
                    $cat.BadgeBorder.Background = if ($global:isDark) { Brush("#1E2838") } else { Brush("#F1F5F9") }
                    $cat.BadgeTxt.Foreground = if ($global:isDark) { Brush("#64748B") } else { Brush("#94A3B8") }
                }
            }
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
        }

        $txtTotalJunk.Text = Format-CleanerBytes $grandTotal
        $sumLbl.Text = "BULUNAN GEREKSİZ ALAN ($grandFiles dosya)"
        $progBorder.Visibility = [System.Windows.Visibility]::Collapsed
        $btnScan.IsEnabled = $true
        $btnClean.IsEnabled = ($grandTotal -gt 0)
    }

    # CLEAN ROUTINE
    $CleanSelected = {
        $selectedItems = @($categories | Where-Object { $_.IsChecked })
        if ($selectedItems.Count -eq 0) { return }

        $progBorder.Visibility = [System.Windows.Visibility]::Visible
        $btnScan.IsEnabled = $false
        $btnClean.IsEnabled = $false
        $btnSelectAll.IsEnabled = $false

        foreach ($cat in $selectedItems) {
            $pTxt.Text = "$($cat.Title) temizleniyor..."
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

            if ($cat.Type -eq "RecycleBin") {
                try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch {}
            } elseif ($cat.Type -eq "FilterFiles") {
                foreach ($p in $cat.Paths) {
                    if (Test-Path $p) {
                        try { Get-ChildItem -Path $p -Filter $cat.Filter -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue } catch {}
                    }
                }
            } elseif ($cat.Type -eq "Firefox") {
                foreach ($p in $cat.Paths) {
                    if (Test-Path $p) {
                        $c2Dirs = Get-ChildItem -Path $p -Filter "cache2" -Recurse -Directory -Force -ErrorAction SilentlyContinue
                        foreach ($c2 in $c2Dirs) {
                            try { Get-ChildItem -Path $c2.FullName -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                        }
                    }
                }
            } else {
                foreach ($p in $cat.Paths) {
                    if (Test-Path $p) {
                        try { Get-ChildItem -Path $p -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                    }
                }
            }
        }

        $pTxt.Text = "Kalan boyutlar hesaplanıyor..."
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
        & $ScanCategories

        $btnSelectAll.IsEnabled = $true
        $fHint.Text = "✅ Temizlik tamamlandı! Sistem başarıyla optimize edildi."
        $fHint.Foreground = Brush("#22C55E")
    }

    $btnScan.Add_Click($ScanCategories)
    $btnClean.Add_Click($CleanSelected)

    $cWin.Add_ContentRendered({
        & $ScanCategories
    })

    $cWin.Content = $gridMain
    [void]$cWin.ShowDialog()
}

# --- GELİŞMİŞ ARAÇLAR ---
if ($btnOpenDiskCleaner) { $btnOpenDiskCleaner.Add_Click({ Show-DiskCleanerModal }) }
if ($btnOpenDefenderScan) { $btnOpenDefenderScan.Add_Click({ Show-DefenderSecurityModal }) }

$btnOpenDriverHub.Add_Click({ Show-DriverManagerModal })

$btnOpenToolsModal.Add_Click({
    $toolsWin = New-Object System.Windows.Window
    $global:currentToolsWin = $toolsWin
    $toolsWin.Title = "Gelişmiş Sistem Ayarları & İnce Ayarlar"
    $toolsWin.Width = 660
    $toolsWin.Height = 560
    $toolsWin.WindowStartupLocation = "CenterOwner"
    try { if ($window -and $window.IsVisible) { $toolsWin.Owner = $window } } catch {}
    $toolsWin.Add_Closed({ $global:currentToolsWin = $null })
    $toolsWin.Background = if ($global:isDark) { Brush("#0B0E14") } else { Brush("#F8FAFC") }
    $toolsWin.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    $toolsWin.ResizeMode = "NoResize"

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.VerticalScrollBarVisibility = "Auto"

    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Margin = New-Object System.Windows.Thickness(24)

    $tHeader = New-Object System.Windows.Controls.TextBlock
    $tHeader.Text = "Sistem ve Windows 11 İnce Ayarları"
    $tHeader.FontSize = 17
    $tHeader.FontWeight = "Bold"
    $tHeader.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
    $tHeader.Margin = New-Object System.Windows.Thickness(0,0,0,4)
    [void]$sp.Children.Add($tHeader)

    $tSub = New-Object System.Windows.Controls.TextBlock
    $tSub.Text = "Tek tıkla sistem güncellemeleri, aktivasyon ve arayüz optimizasyonları."
    $tSub.FontSize = 11
    $tSub.Foreground = Brush("#8C9BB0")
    $tSub.Margin = New-Object System.Windows.Thickness(0,0,0,18)
    [void]$sp.Children.Add($tSub)

    function Add-ModernToolCard($icon, $title, $desc, $btnText, $btnColor, [scriptblock]$action, $extraBtnText = $null, $extraBtnColor = "#6366F1", [scriptblock]$extraAction = $null) {
        $cBorder = New-Object System.Windows.Controls.Border
        $cBorder.Background = if ($global:isDark) { Brush("#151C28") } else { Brush("#FFFFFF") }
        $cBorder.BorderBrush = if ($global:isDark) { Brush("#232E40") } else { Brush("#E2E8F0") }
        $cBorder.BorderThickness = New-Object System.Windows.Thickness(1)
        $cBorder.CornerRadius = New-Object System.Windows.CornerRadius(14)
        $cBorder.Padding = New-Object System.Windows.Thickness(14)
        $cBorder.Margin = New-Object System.Windows.Thickness(0,0,0,12)

        $g = New-Object System.Windows.Controls.Grid
        $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = [System.Windows.GridLength]::Auto
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::Auto
        [void]$g.ColumnDefinitions.Add($c0); [void]$g.ColumnDefinitions.Add($c1); [void]$g.ColumnDefinitions.Add($c2)

        $icoBox = New-Object System.Windows.Controls.Border
        $icoBox.Width = 40
        $icoBox.Height = 40
        $icoBox.CornerRadius = New-Object System.Windows.CornerRadius(10)
        $icoBox.Background = if ($global:isDark) { Brush("#1A2332") } else { Brush("#F1F5F9") }
        $icoBox.Margin = New-Object System.Windows.Thickness(0,0,14,0)

        $icoTxt = New-Object System.Windows.Controls.TextBlock
        $icoTxt.Text = $icon
        $icoTxt.FontSize = 18
        $icoTxt.HorizontalAlignment = "Center"
        $icoTxt.VerticalAlignment = "Center"
        $icoBox.Child = $icoTxt
        [System.Windows.Controls.Grid]::SetColumn($icoBox, 0)
        [void]$g.Children.Add($icoBox)

        $txtBox = New-Object System.Windows.Controls.StackPanel
        $txtBox.VerticalAlignment = "Center"
        $lblT = New-Object System.Windows.Controls.TextBlock
        $lblT.Text = $title
        $lblT.FontWeight = "Bold"
        $lblT.FontSize = 13
        $lblT.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
        $lblD = New-Object System.Windows.Controls.TextBlock
        $lblD.Text = $desc
        $lblD.FontSize = 10.5
        $lblD.Foreground = Brush("#8C9BB0")
        $lblD.Margin = New-Object System.Windows.Thickness(0,2,0,0)
        [void]$txtBox.Children.Add($lblT)
        [void]$txtBox.Children.Add($lblD)
        [System.Windows.Controls.Grid]::SetColumn($txtBox, 1)
        [void]$g.Children.Add($txtBox)

                $btnPanel = New-Object System.Windows.Controls.StackPanel
        $btnPanel.Orientation = "Horizontal"
        $btnPanel.VerticalAlignment = "Center"
        $btnPanel.HorizontalAlignment = "Right"
        $btnTpl = '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Name="b" Background="{TemplateBinding Background}" CornerRadius="19" SnapsToDevicePixels="True"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="16,0,16,0"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.88"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.75"/></Trigger></ControlTemplate.Triggers></ControlTemplate>'

        if ($extraBtnText -and $extraAction) {
            $xbtn = New-Object System.Windows.Controls.Button
            $xbtn.Content = $extraBtnText
            $xbtn.Height = 38
            $xbtn.MinWidth = 120
            $xbtn.Margin = New-Object System.Windows.Thickness(0,0,10,0)
            $xbtn.Padding = New-Object System.Windows.Thickness(14,0,14,0)
            $xbtn.Background = Brush($extraBtnColor)
            $xbtn.Foreground = Brush("#FFFFFF")
            $xbtn.FontWeight = "Bold"
            $xbtn.FontSize = 11.5
            $xbtn.BorderThickness = New-Object System.Windows.Thickness(0)
            $xbtn.Cursor = "Hand"
            $xbtn.Template = [System.Windows.Markup.XamlReader]::Parse($btnTpl)
            $xbtn.Add_Click($extraAction)
            [void]$btnPanel.Children.Add($xbtn)
        }

        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = $btnText
        $btn.Height = 38
        $btn.MinWidth = 110
        $btn.Padding = New-Object System.Windows.Thickness(18,0,18,0)
        $btn.Background = Brush($btnColor)
        $btn.Foreground = Brush("#FFFFFF")
        $btn.FontWeight = "Bold"
        $btn.FontSize = 12
        $btn.BorderThickness = New-Object System.Windows.Thickness(0)
        $btn.Cursor = "Hand"
        $btn.Template = [System.Windows.Markup.XamlReader]::Parse($btnTpl)
        $btn.Add_Click($action)
        [void]$btnPanel.Children.Add($btn)

        [System.Windows.Controls.Grid]::SetColumn($btnPanel, 2)
        [void]$g.Children.Add($btnPanel)

        $cBorder.Child = $g
        [void]$sp.Children.Add($cBorder)
    }

    Add-ModernToolCard "🧹" "Sistem & Disk Temizleyici" "Temp, Prefetch, çöp kutusu, güncelleme önbelleği ve gereksiz sistem kalıntılarını temizler." "Temizle" "#10B981" {
        Show-DiskCleanerModal
    }

    Add-ModernToolCard "🔄" "Windows Güncellemelerini Denetle" "Resmi Windows Update ayarlarını açar ve tarama yapar." "Aç" "#2563EB" {
        Start-Process "ms-settings:windowsupdate"
    }

    Add-ModernToolCard "🔑" "Windows & Office Lisanslama (MAS)" "Açık kaynak Microsoft Activation Scripts kütüphanesini açar." "Başlat" "#38BDF8" {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.activated.win | iex`""
    }

        function Show-ContextMenuComparison {
        $cWin = New-Object System.Windows.Window
        $cWin.Title = "Sağ Tık Menüsü Karşılaştırması (Önce / Sonra)"
        $cWin.Width = 720
        $cWin.Height = 670
        $cWin.WindowStartupLocation = "CenterScreen"
        $cWin.Background = if ($global:isDark) { Brush("#0B0E14") } else { Brush("#F8FAFC") }
        $cWin.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
        $cWin.ResizeMode = "NoResize"
        if ($toolsWin) { try { $cWin.Owner = $toolsWin } catch {} }

        $mBtnTpl = '<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button"><Border Name="b" Background="{TemplateBinding Background}" CornerRadius="19" SnapsToDevicePixels="True"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="16,0,16,0"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.88"/></Trigger><Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.75"/></Trigger></ControlTemplate.Triggers></ControlTemplate>'

        function Get-MenuPreviewBmp([bool]$isAfter) {
            $fPath = if ($isAfter) { "C:\projem\assets\menu_after.png" } else { "C:\projem\assets\menu_before.png" }
            if (Test-Path $fPath) {
                try {
                    $b = New-Object System.Windows.Media.Imaging.BitmapImage
                    $b.BeginInit()
                    $b.UriSource = [Uri]$fPath
                    $b.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $b.EndInit()
                    $b.Freeze()
                    return $b
                } catch {}
            }
            $b64 = if ($isAfter) { $global:b64MenuAfter } else { $global:b64MenuBefore }
            if ($b64) {
                try {
                    $raw = [Convert]::FromBase64String($b64)
                    $ms = New-Object System.IO.MemoryStream(,$raw)
                    $b = New-Object System.Windows.Media.Imaging.BitmapImage
                    $b.BeginInit()
                    $b.StreamSource = $ms
                    $b.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $b.EndInit()
                    $b.Freeze()
                    return $b
                } catch {}
            }
            return $null
        }

        $pnl = New-Object System.Windows.Controls.StackPanel
        $pnl.Margin = New-Object System.Windows.Thickness(20)

        $tH = New-Object System.Windows.Controls.TextBlock
        $tH.Text = "Sağ Tık Menüsü Karşılaştırması"
        $tH.FontSize = 18
        $tH.FontWeight = "Bold"
        $tH.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
        [void]$pnl.Children.Add($tH)

        $tS = New-Object System.Windows.Controls.TextBlock
        $tS.Text = "Windows 11 varsayılan kısıtlı menüsü ile Windows 10 klasik tam menüsü arasındaki görsel ve işlevsel fark:"
        $tS.FontSize = 11.5
        $tS.Foreground = Brush("#8C9BB0")
        $tS.Margin = New-Object System.Windows.Thickness(0,3,0,16)
        [void]$pnl.Children.Add($tS)

        $gridCols = New-Object System.Windows.Controls.Grid
        $col0 = New-Object System.Windows.Controls.ColumnDefinition; $col0.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $col1 = New-Object System.Windows.Controls.ColumnDefinition; $col1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        [void]$gridCols.ColumnDefinitions.Add($col0); [void]$gridCols.ColumnDefinitions.Add($col1)

        # ÖNCE Panel
        $bBefore = New-Object System.Windows.Controls.Border
        $bBefore.Background = if ($global:isDark) { Brush("#151C28") } else { Brush("#FFFFFF") }
        $bBefore.BorderBrush = Brush("#EF4444")
        $bBefore.BorderThickness = New-Object System.Windows.Thickness(1.5)
        $bBefore.CornerRadius = New-Object System.Windows.CornerRadius(12)
        $bBefore.Padding = New-Object System.Windows.Thickness(12)
        $bBefore.Margin = New-Object System.Windows.Thickness(0,0,8,0)

        $spB = New-Object System.Windows.Controls.StackPanel
        $lblB = New-Object System.Windows.Controls.TextBlock
        $lblB.Text = "🔴 ÖNCE (Windows 11 Varsayılan)"
        $lblB.FontWeight = "Bold"
        $lblB.FontSize = 12
        $lblB.Foreground = Brush("#EF4444")
        $lblB.Margin = New-Object System.Windows.Thickness(0,0,0,8)
        [void]$spB.Children.Add($lblB)

        $imgB = New-Object System.Windows.Controls.Image
        $imgB.Source = Get-MenuPreviewBmp $false
        $imgB.Height = 340
        $imgB.Stretch = [System.Windows.Media.Stretch]::Uniform
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($imgB, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        [void]$spB.Children.Add($imgB)

        $descB = New-Object System.Windows.Controls.TextBlock
        $descB.Text = "Kısıtlı Menü: Uygulama seçenekleri gizlidir, 'Daha fazla seçenek göster' tıklaması gerektirir."
        $descB.FontSize = 10.5
        $descB.Foreground = Brush("#8C9BB0")
        $descB.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $descB.Margin = New-Object System.Windows.Thickness(0,8,0,0)
        [void]$spB.Children.Add($descB)
        $bBefore.Child = $spB
        [System.Windows.Controls.Grid]::SetColumn($bBefore, 0)
        [void]$gridCols.Children.Add($bBefore)

        # SONRA Panel
        $bAfter = New-Object System.Windows.Controls.Border
        $bAfter.Background = if ($global:isDark) { Brush("#151C28") } else { Brush("#FFFFFF") }
        $bAfter.BorderBrush = Brush("#22C55E")
        $bAfter.BorderThickness = New-Object System.Windows.Thickness(1.5)
        $bAfter.CornerRadius = New-Object System.Windows.CornerRadius(12)
        $bAfter.Padding = New-Object System.Windows.Thickness(12)
        $bAfter.Margin = New-Object System.Windows.Thickness(8,0,0,0)

        $spA = New-Object System.Windows.Controls.StackPanel
        $lblA = New-Object System.Windows.Controls.TextBlock
        $lblA.Text = "🟢 SONRA (Windows 10 Klasik)"
        $lblA.FontWeight = "Bold"
        $lblA.FontSize = 12
        $lblA.Foreground = Brush("#22C55E")
        $lblA.Margin = New-Object System.Windows.Thickness(0,0,0,8)
        [void]$spA.Children.Add($lblA)

        $imgA = New-Object System.Windows.Controls.Image
        $imgA.Source = Get-MenuPreviewBmp $true
        $imgA.Height = 340
        $imgA.Stretch = [System.Windows.Media.Stretch]::Uniform
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($imgA, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        [void]$spA.Children.Add($imgA)

        $descA = New-Object System.Windows.Controls.TextBlock
        $descA.Text = "Tam Klasik Menü: Tüm seçenekler doğrudan tek tıkla açılır, gizli menü ve gecikme yoktur."
        $descA.FontSize = 10.5
        $descA.Foreground = Brush("#8C9BB0")
        $descA.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $descA.Margin = New-Object System.Windows.Thickness(0,8,0,0)
        [void]$spA.Children.Add($descA)
        $bAfter.Child = $spA
        [System.Windows.Controls.Grid]::SetColumn($bAfter, 1)
        [void]$gridCols.Children.Add($bAfter)

        [void]$pnl.Children.Add($gridCols)

        # Bottom Buttons
        $btnRow = New-Object System.Windows.Controls.StackPanel
        $btnRow.Orientation = "Horizontal"
        $btnRow.HorizontalAlignment = "Right"
        $btnRow.Margin = New-Object System.Windows.Thickness(0,18,0,0)

        $actApply = New-Object System.Windows.Controls.Button
        $actApply.Content = "✅ Windows 10 Menüsünü Etkinleştir"
        $actApply.Height = 38
        $actApply.Padding = New-Object System.Windows.Thickness(16,0,16,0)
        $actApply.Background = Brush("#22C55E")
        $actApply.Foreground = Brush("#FFFFFF")
        $actApply.FontWeight = "Bold"
        $actApply.FontSize = 12
        $actApply.Cursor = "Hand"
        $actApply.Template = [System.Windows.Markup.XamlReader]::Parse($mBtnTpl)
        $actApply.Add_Click({
            REG ADD "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /t REG_SZ /f /reg:64 2>$null
            REG ADD "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /t REG_SZ /f /reg:32 2>$null
            taskkill /f /im explorer.exe 2>$null
            Start-Process "C:\Windows\explorer.exe"
            Show-ModernAlert "İşlem Başarılı" "Windows 10 klasik sağ tık menüsü başarıyla uygulandı!" "OK"
            $cWin.Close()
        })
        [void]$btnRow.Children.Add($actApply)

        $actDefault = New-Object System.Windows.Controls.Button
        $actDefault.Content = "↩️ Windows 11 Varsayılanına Dön"
        $actDefault.Height = 38
        $actDefault.Margin = New-Object System.Windows.Thickness(10,0,0,0)
        $actDefault.Padding = New-Object System.Windows.Thickness(16,0,16,0)
        $actDefault.Background = Brush("#EF4444")
        $actDefault.Foreground = Brush("#FFFFFF")
        $actDefault.FontWeight = "Bold"
        $actDefault.FontSize = 12
        $actDefault.Cursor = "Hand"
        $actDefault.Template = [System.Windows.Markup.XamlReader]::Parse($mBtnTpl)
        $actDefault.Add_Click({
            REG DELETE "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f /reg:64 2>$null
            REG DELETE "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f /reg:32 2>$null
            taskkill /f /im explorer.exe 2>$null
            Start-Process "C:\Windows\explorer.exe"
            Show-ModernAlert "İşlem Başarılı" "Windows 11 varsayılan menüsü geri yüklendi!" "OK"
            $cWin.Close()
        })
        [void]$btnRow.Children.Add($actDefault)

        $actClose = New-Object System.Windows.Controls.Button
        $actClose.Content = "Kapat"
        $actClose.Height = 38
        $actClose.MinWidth = 80
        $actClose.Margin = New-Object System.Windows.Thickness(10,0,0,0)
        $actClose.Padding = New-Object System.Windows.Thickness(16,0,16,0)
        $actClose.Background = if ($global:isDark) { Brush("#232E40") } else { Brush("#CBD5E1") }
        $actClose.Foreground = if ($global:isDark) { Brush("#F8FAFC") } else { Brush("#0F172A") }
        $actClose.FontWeight = "SemiBold"
        $actClose.FontSize = 12
        $actClose.Cursor = "Hand"
        $actClose.Template = [System.Windows.Markup.XamlReader]::Parse($mBtnTpl)
        $actClose.Add_Click({ $cWin.Close() })
        [void]$btnRow.Children.Add($actClose)

        [void]$pnl.Children.Add($btnRow)

        $cWin.Content = $pnl
        [void]$cWin.ShowDialog()
    }

    Add-ModernToolCard "📂" "Windows 10 Klasik Sağ Tık Menüsü" "Windows 10 tarzı tam ve doğrudan sağ tık menüsünü geri getirir." "Etkinleştir" "#22C55E" {
        REG ADD "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /t REG_SZ /f /reg:64 2>$null
        REG ADD "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /t REG_SZ /f /reg:32 2>$null
        taskkill /f /im explorer.exe 2>$null
        Start-Process "C:\Windows\explorer.exe"
        Show-ModernAlert "İşlem Başarılı" "Windows 10 klasik sağ tık menüsü uygulandı!" "OK"
    } "👁️ Önce / Sonra" "#6366F1" {
        Show-ContextMenuComparison
    }

    Add-ModernToolCard "↩️" "Windows 11 Varsayılan Sağ Tıka Dön" "Windows 11'in yeni modern sağ tık menüsüne geri döner." "Geri Yükle" "#EF4444" {
        REG DELETE "HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f 2>$null
        taskkill /f /im explorer.exe 2>$null
        Start-Process "C:\Windows\explorer.exe"
        Show-ModernAlert "İşlem Başarılı" "Varsayılan sağ tık menüsüne dönüldü." "OK"
    }

    $scroll.Content = $sp
    $toolsWin.Content = $scroll
    [void]$toolsWin.ShowDialog()
})

# --- EVENT ATAMALARI ---
$navButtons["All"].Add_Click({ Set-CategoryFilter "All" "Tüm Uygulamalar" })
$navButtons["Installed"].Add_Click({ Set-CategoryFilter "Installed" "Yüklü Uygulamalar" })
$navButtons["Updates"].Add_Click({ Set-CategoryFilter "Updates" "Güncellemesi Olan Uygulamalar" })
$navButtons["Browsers"].Add_Click({ Set-CategoryFilter "Browsers" "Tarayıcı, İletişim & Sosyal Medya" })
$navButtons["Games"].Add_Click({ Set-CategoryFilter "Games" "Oyun Başlatıcıları, Medya & Dijital Yayın" })
$navButtons["Dev"].Add_Click({ Set-CategoryFilter "Dev" "Geliştirici & AI" })
$navButtons["Hardware"].Add_Click({ Set-CategoryFilter "Hardware" "Donanım & Sürücüler" })
$navButtons["Security"].Add_Click({ Set-CategoryFilter "Security" "Güvenlik & Kalkan" })
$navButtons["Runtimes"].Add_Click({ Set-CategoryFilter "Runtimes" ".NET & Visual C++" })
$navButtons["Tools"].Add_Click({ Set-CategoryFilter "Tools" "Sistem & Araçlar" })

$txtSearch.Add_TextChanged({ Apply-Filters })
$btnClearSearch.Add_Click({
    $txtSearch.Text = ""
    Apply-Filters
})

$btnClearQueue.Add_Click({
    foreach ($card in $global:allCards) {
        $state = $card.Tag
        $state.IsSelected = $false
        $card.Background = if ($global:isDark) { Brush("#1A2332") } else { Brush("#EDF2F7") }
        $card.BorderBrush = if ($global:isDark) { Brush("#253246") } else { Brush("#CBD5E1") }
        $state.CheckBadge.Background = if ($global:isDark) { Brush("#253246") } else { Brush("#CBD5E1") }
        $state.CheckMark.Visibility = [System.Windows.Visibility]::Collapsed
    }
    $global:selectedQueue.Clear()
    Render-QueuePanel
})

$btnRefresh.Add_Click({
    Trigger-FullStateRefresh
})

$btnSelectUpdates.Add_Click({
    $found = 0
    foreach ($card in $global:allCards) {
        $state = $card.Tag
        if ($state.IsInstalled -and $state.HasUpdate -and -not $state.IsSelected) {
            $state.IsSelected = $true
            $card.Background = if ($global:isDark) { Brush("#1B293C") } else { Brush("#E0F2FE") }
            $card.BorderBrush = Brush("#38BDF8")
            $state.CheckBadge.Background = Brush("#38BDF8")
            $state.CheckMark.Foreground = Brush("#FFFFFF")
            $state.CheckMark.Visibility = [System.Windows.Visibility]::Visible
            if (!$global:selectedQueue.Contains($card)) {
                [void]$global:selectedQueue.Add($card)
            }
            $found++
        }
    }
    Render-QueuePanel
    if ($found -eq 0) {
        Show-ModernAlert "Sistem Güncel" "Sisteminizdeki tüm uygulamalar zaten güncel sürümde!" "INFO"
    }
})

$btnInstall.Add_Click({ Invoke-BatchOperation "Kur" })
$btnUpgrade.Add_Click({ Invoke-BatchOperation "Guncelle" })
$btnUninstall.Add_Click({ Invoke-BatchOperation "Kaldir" })

# Tema Değiştirici
$btnTheme.Add_Click({
    # Tema geçiş animasyonu - fade out → değiştir → fade in
    $animOut = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animOut.From = 1.0
    $animOut.To = 0.0
    $animOut.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(180))
    $animOut.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
    ([System.Windows.Media.Animation.QuadraticEase]($animOut.EasingFunction)).EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseIn

    $animIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animIn.From = 0.0
    $animIn.To = 1.0
    $animIn.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(280))
    $animIn.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
    ([System.Windows.Media.Animation.QuadraticEase]($animIn.EasingFunction)).EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut

    # Fade out — uygula
    $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $animOut)
    Start-Sleep -Milliseconds 200
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)

    # Tema renklerini uygula
    $resources = $window.Resources
    if ($global:isDark) {
        $resources["WindowBg"] = Brush("#F0F2F5")
        $resources["SidebarBg"] = Brush("#FFFFFF")
        $resources["PanelBg"] = Brush("#F8FAFC")
        $resources["CardBg"] = Brush("#EDF2F7")
        $resources["BorderColor"] = Brush("#E2E8F0")
        $resources["CardBorder"] = Brush("#CBD5E1")
        $resources["TextMain"] = Brush("#0F172A")
        $resources["TextMuted"] = Brush("#64748B")
        $resources["NavHoverBg"] = Brush("#15475569")
        $resources["HeaderBtnHover"] = Brush("#E2E8F0")
        $resources["DisabledBtnBg"] = Brush("#E2E8F0")
        $resources["DisabledBtnFg"] = Brush("#94A3B8")
        $resources["ScrollThumb"] = Brush("#CBD5E1")
        $resources["ScrollThumbHover"] = Brush("#94A3B8")
        $btnTheme.Content = "🌙 Koyu Tema"
    } else {
        $resources["WindowBg"] = Brush("#0B0E14")
        $resources["SidebarBg"] = Brush("#11161F")
        $resources["PanelBg"] = Brush("#151C28")
        $resources["CardBg"] = Brush("#1A2332")
        $resources["BorderColor"] = Brush("#232E40")
        $resources["CardBorder"] = Brush("#253246")
        $resources["TextMain"] = Brush("#F3F4F6")
        $resources["TextMuted"] = Brush("#8C9BB0")
        $resources["NavHoverBg"] = Brush("#1A38BDF8")
        $resources["HeaderBtnHover"] = Brush("#2A374E")
        $resources["DisabledBtnBg"] = Brush("#252F40")
        $resources["DisabledBtnFg"] = Brush("#5E6F88")
        $resources["ScrollThumb"] = Brush("#334155")
        $resources["ScrollThumbHover"] = Brush("#475569")
        $btnTheme.Content = "☀️ Açık Tema"
    }
    $global:isDark = -not $global:isDark
    Render-Cards

    # Fade in — yeni temayı göster
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $animIn)
})

if ($global:wingetExe -and (Test-Path $global:wingetExe)) {
    $txtWingetStatus.Text = "WinGet Aktif"
} elseif (Get-Command winget.exe -ErrorAction SilentlyContinue) {
    $txtWingetStatus.Text = "WinGet Aktif"
} else {
    $txtWingetStatus.Text = "WinGet Yok"
    $txtWingetStatus.Foreground = Brush("#EF4444")
}

Render-Cards
Set-Status "Sistem hazır. Sıraya paket ekleyebilirsiniz." "OK"


# ═══════════════════════════════════════════════════════════════
# AÇILIŞ EKRANI (SPLASH SCREEN)
# ═══════════════════════════════════════════════════════════════
function Show-SplashScreen {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

    $splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        WindowStartupLocation="CenterScreen"
        Width="480" Height="300"
        Topmost="True"
        ShowInTaskbar="False">
    <Grid>
        <Border Background="#0D1117" CornerRadius="18"
                BorderThickness="1.5">
            <Border.BorderBrush>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#38BDF8" Offset="0"/>
                    <GradientStop Color="#6366F1" Offset="0.5"/>
                    <GradientStop Color="#22C55E" Offset="1"/>
                </LinearGradientBrush>
            </Border.BorderBrush>
            <Border.Effect>
                <DropShadowEffect Color="#000000" BlurRadius="40" ShadowDepth="0" Opacity="0.7"/>
            </Border.Effect>
        </Border>

        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Margin="40,0">
            <!-- İkon -->
            <Border Width="72" Height="72" CornerRadius="16" HorizontalAlignment="Center" Margin="0,0,0,16">
                <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#1E293B" Offset="0"/>
                        <GradientStop Color="#0F172A" Offset="1"/>
                    </LinearGradientBrush>
                </Border.Background>
                <Border.Effect>
                    <DropShadowEffect Color="#38BDF8" BlurRadius="18" ShadowDepth="0" Opacity="0.5"/>
                </Border.Effect>
                <TextBlock Text="⚙" FontSize="38" HorizontalAlignment="Center" VerticalAlignment="Center"
                           Foreground="#38BDF8"/>
            </Border>

            <!-- Başlık -->
            <TextBlock Name="splashTitle" Text="System Manager Pro"
                       FontSize="22" FontWeight="Bold" HorizontalAlignment="Center"
                       Foreground="#F8FAFC" FontFamily="Segoe UI" Margin="0,0,0,4"/>

            <!-- Alt yazı -->
            <TextBlock Name="splashSub" Text="Sistem başlatılıyor..."
                       FontSize="12" HorizontalAlignment="Center"
                       Foreground="#8C9BB0" FontFamily="Segoe UI" Margin="0,0,0,24"/>

            <!-- Progress bar arka planı -->
            <Border Height="5" CornerRadius="3" Background="#1E293B" Width="340" Margin="0,0,0,12">
                <Border Name="splashProgress" Height="5" CornerRadius="3" HorizontalAlignment="Left" Width="0">
                    <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                            <GradientStop Color="#38BDF8" Offset="0"/>
                            <GradientStop Color="#6366F1" Offset="0.6"/>
                            <GradientStop Color="#22C55E" Offset="1"/>
                        </LinearGradientBrush>
                    </Border.Background>
                    <Border.Effect>
                        <DropShadowEffect Color="#38BDF8" BlurRadius="8" ShadowDepth="0" Opacity="0.8"/>
                    </Border.Effect>
                </Border>
            </Border>

            <!-- Versiyon -->
            <TextBlock Text="v1.0  •  2026 Edition"
                       FontSize="10" HorizontalAlignment="Center"
                       Foreground="#334155" FontFamily="Segoe UI"/>
        </StackPanel>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new([xml]$splashXaml)
    $splashWin = [System.Windows.Markup.XamlReader]::Load($reader)

    $splashProgress = $splashWin.FindName("splashProgress")
    $splashSub = $splashWin.FindName("splashSub")

    # Fade-in animasyonu
    $splashWin.Opacity = 0
    $splashWin.Show()

    $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $fadeIn.From = 0
    $fadeIn.To = 1
    $fadeIn.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(400))
    $fadeIn.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
    $splashWin.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeIn)

    # Progress animasyonu adım adım ve akıcı
    $steps = @(
        @{ TargetWidth = 60;  Text = "Modüller ve kütüphaneler yükleniyor..." },
        @{ TargetWidth = 130; Text = "Uygulama listesi hazırlanıyor..." },
        @{ TargetWidth = 200; Text = "Yüklü programlar ve Store paketleri taranıyor..." },
        @{ TargetWidth = 270; Text = "Arayüz bileşenleri oluşturuluyor..." },
        @{ TargetWidth = 320; Text = "Logolar ve durum rozetleri işleniyor..." },
        @{ TargetWidth = 340; Text = "Hazır! System Manager Pro açılıyor..." }
    )

    $currentWidth = 0.0
    foreach ($step in $steps) {
        $splashSub.Text = $step.Text
        $target = [double]$step.TargetWidth
        while ($currentWidth -lt $target) {
            $currentWidth = [Math]::Min($target, $currentWidth + 5.0)
            $splashProgress.Width = $currentWidth
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
            Start-Sleep -Milliseconds 12
        }
        Start-Sleep -Milliseconds 60
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    }

    # Fade-out
    $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
    $fadeOut.From = 1
    $fadeOut.To = 0
    $fadeOut.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(350))
    $fadeOut.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase

    $splashWin.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeOut)
    Start-Sleep -Milliseconds 380
    $splashWin.Close()
}

Show-SplashScreen

[void]$window.ShowDialog()
