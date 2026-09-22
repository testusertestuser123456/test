最新の完全版コード（-Restore 対応）のオプション解説と実行例をまとめた取扱説明書です。
改行コード（CR）一括変換ツール test2.ps1
📌 概要
Windows環境（CRLF）と Linux/Mac環境（LF）の間で発生する「改行コードのエラー」を双方解決できる万能ツールです。
 * 通常モード: Linuxでエラーになる CR を削除（CRLF ➔ LF）
 * 復元モード (-rst): Windowsで読みやすくするために CR を追加（LF ➔ CRLF）
バイナリ処理を行っているため、ファイルの文字コード（UTF-8, Shift_JIS等）を壊さず変換できます。
🛠 パラメータ（オプション）一覧
| オプション名 | 短縮形 | パラメータの型 | 初期値（指定なしの場合） | 機能説明 |
|---|---|---|---|---|
| -TargetFolder | -p | 文字列 (String) | スクリプトがあるフォルダ | 処理対象のフォルダパスを指定します。
スペースを含むパスは 'C:\My Project' のように引用符で囲みます。 |
| -Recursive | -r | フラグ (Switch) | オフ（直下のみ） | サブフォルダの中身も一括で検索・処理します。 |
| -Restore | -rst | フラグ (Switch) | オフ（CR削除） | Windows用（CRLF）に復元します。
単体の LF の前に CR を自動挿入します。 |
| -Backup | -b | フラグ (Switch) | オフ（上書き） | 変換を行う直前に、元のファイルを ファイル名.bak として複製します。 |
| -IncludeExtension | -i | 文字列配列 | なし（全テキスト） | 指定した拡張子のみを処理対象にします。
例: -i .sh, .py, .env |
| -ExcludeExtension | -e | 文字列配列 | なし | 追加で無視したい拡張子を指定します。
例: -e .log, .tmp |
| -LogFile | -l | 文字列 (String) | なし（画面のみ） | 実行結果を画面だけでなく指定したログファイルへ保存します。 |
| -Force | -f | フラグ (Switch) | オフ（確認あり） | 最後の Y/N（実行確認）をスキップし、即座に変換を実行します。 |
| -Help | -h | フラグ (Switch) | オフ | ヘルプ画面を表示して処理を終了します。 |
> 💡 自動安全機能
> 画像や圧縮ファイル（.png, .jpg, .zip, .pdf, .exe など）は、バイナリ破損を防ぐために自動で除外・保護されます。
> 
💡 実行例（よく使うシチュエーション別）
1. 【基本】スクリプトがあるフォルダの直下だけ点検・変換
最もシンプルに試す方法です。
.\test2.ps1

 * 挙動: 直下のファイルをチェックし、変換対象があれば Y/N の確認が出ます。
2. Linuxに送る前処理（サブフォルダ含めて全一括変換）
プロジェクト全体を Linux サーバーに持っていく前によく使うパターンです。
.\test2.ps1 -p "C:\MyProject" -r

 * 挙動: C:\MyProject 配下のすべてのサブフォルダ内にあるテキストファイルを LF に変換します。
3. 万が一に備えてバックアップを作成しながら変換
誤変換が心配な場合や、大切なファイルを扱う際におすすめです。
.\test2.ps1 -p "C:\MyProject" -r -b

 * 挙動: 変換されたファイルと同じ場所に ファイル名.sh.bak のようなバックアップファイルが生成されます。
4. 特定のファイル（シェルスクリプトや設定ファイル）だけに絞る
画像やドキュメント等を完全にスルーし、コード類だけを処理したい場合です。
.\test2.ps1 -p "C:\MyProject" -r -i ".sh", ".py", ".env"

 * 挙動: .sh, .py, .env の拡張子を持つファイルだけを厳選して処理します。
5. 【復元】Linuxから持ち帰ったファイルを Windows用（CRLF）に戻す
-rst オプションをつけることで、逆方向の変換を行います。
.\test2.ps1 -p "C:\MyProject" -r -rst

 * 挙動: LF のみを検出し、Windowsで扱いやすい CRLF に変更します（すでに CRLF の行は二重変換されません）。
6. 完全自動化（確認なし＋ログ出力）
CI/CD パイプラインや定期実行タスクなどで対話処理をスキップしたい場合です。
.\test2.ps1 -p "C:\MyProject" -r -f -l "C:\Logs\convert.log"

 * 挙動: Y/N の確認を出さずに全自動で実行し、C:\Logs\convert.log に結果を書き残します。


コード

[CmdletBinding()]
param (
    # 対象フォルダパス
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias("Path", "p")]
    [string]$TargetFolder,

    # 除外する拡張子（例: -e ".png", ".zip"）
    [Parameter(Mandatory = $false)]
    [Alias("Exclude", "e")]
    [string[]]$ExcludeExtension,

    # 対象とする拡張子（例: -i ".sh", ".txt"）
    [Parameter(Mandatory = $false)]
    [Alias("Include", "i")]
    [string[]]$IncludeExtension,

    # サブフォルダも再帰的に処理する
    [Parameter(Mandatory = $false)]
    [Alias("r")]
    [switch]$Recursive,

    # 変換前にバックアップ (.bak) を作成する
    [Parameter(Mandatory = $false)]
    [Alias("b")]
    [switch]$Backup,

    # 実行結果をログファイルに出力する
    [Parameter(Mandatory = $false)]
    [Alias("l")]
    [string]$LogFile,

    # 最終確認メッセージをスキップして即時実行する
    [Parameter(Mandatory = $false)]
    [Alias("f")]
    [switch]$Force,

    # モード切り替え: LF を Windows用 CRLF に戻す (Restoreモード)
    [Parameter(Mandatory = $false)]
    [Alias("rst")]
    [switch]$Restore,

    # ヘルプ表示
    [Parameter(Mandatory = $false)]
    [Alias("h")]
    [switch]$Help
)

# --------------------------------------------------
# 0. ヘルプ表示処理
# --------------------------------------------------
if ($Help) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "  改行コード（CR）削除・復元ツール - HELP" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " [概要]"
    Write-Host "   テキストファイルの改行コードを LF(Linux向け) または CRLF(Windows向け) に一括変換します。"
    Write-Host ""
    Write-Host " [構文]"
    Write-Host "   .\test2.ps1 [-TargetFolder <パス>] [-ExcludeExtension <拡張子...>]"
    Write-Host "                [-IncludeExtension <拡張子...>] [-Recursive] [-Backup]"
    Write-Host "                [-LogFile <パス>] [-Force] [-Restore] [-Help]"
    Write-Host ""
    Write-Host " [パラメータ（短縮名）]"
    Write-Host "   -TargetFolder (-Path, -p)    : 対象フォルダパス。省略時は実行スクリプト直下。"
    Write-Host "   -ExcludeExtension (-Exclude, -e): 除外する拡張子を指定（例: -e .png .zip）。"
    Write-Host "   -IncludeExtension (-Include, -i): 対象にする拡張子を指定（例: -i .sh .txt）。"
    Write-Host "   -Recursive (-r)              : サブフォルダ配下も再帰的に処理対象とする。"
    Write-Host "   -Backup (-b)                 : 変換前に .bak バックアップファイルを作成。"
    Write-Host "   -LogFile (-l)                : 実行ログを指定したファイルパスに出力。"
    Write-Host "   -Force (-f)                  : 最終確認（Y/N）をスキップして即時変換を実行。"
    Write-Host "   -Restore (-rst)              : Windows用モード。LF を CRLF (CR付与) に復元します。"
    Write-Host "   -Help (-h)                   : ヘルプを表示。"
    Write-Host ""
    Write-Host " [実行例]"
    Write-Host "   1. Linux向け変換 (CR削除: CRLF -> LF):"
    Write-Host "      .\test2.ps1 -p 'C:\MyProject' -r"
    Write-Host ""
    Write-Host "   2. Windows向け復元 (CR追加: LF -> CRLF):"
    Write-Host "      .\test2.ps1 -p 'C:\MyProject' -r -rst"
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# --------------------------------------------------
# 1. ログ出力用関数の定義
# --------------------------------------------------
function Out-Log {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White,
        [bool]$NoNewline = $false
    )
    if ($NoNewline) {
        Write-Host $Message -NoNewline -ForegroundColor $Color
    } else {
        Write-Host $Message -ForegroundColor $Color
    }

    if (-not [string]::IsNullOrWhitespace($LogFile)) {
        Add-Content -Path $LogFile -Value $Message -Encoding UTF8
    }
}

if (-not [string]::IsNullOrWhitespace($LogFile)) {
    try {
        $logDir = Split-Path -Parent $LogFile
        if (-not [string]::IsNullOrWhitespace($logDir) -and -not (Test-Path -Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        "=== 改行コード変換ツール 実行ログ (" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + ") ===" | Out-File -FilePath $LogFile -Encoding UTF8 -Force
    } catch {
        Write-Host "[ERROR] ログファイルの作成に失敗しました: $_" -ForegroundColor Red
        exit 1
    }
}

# --------------------------------------------------
# 2. 対象フォルダの決定処理
# --------------------------------------------------
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDirectory = Split-Path -Parent $ScriptPath

if ([string]::IsNullOrWhitespace($TargetFolder)) {
    $FolderPath = $ScriptDirectory
} else {
    if (-not (Test-Path -Path $TargetFolder -PathType Container)) {
        Out-Log "[ERROR] 指定されたフォルダが存在しません: $TargetFolder" -Color Red
        exit 1
    }
    $FolderPath = (Get-Item -Path $TargetFolder).FullName
}

if ($Recursive) {
    $Files = Get-ChildItem -Path $FolderPath -File -Recurse
} else {
    $Files = Get-ChildItem -Path $FolderPath -File
}

# 自分自身の完全除外
$Files = $Files | Where-Object { $_.FullName -ne $ScriptPath }

# --------------------------------------------------
# 3. 拡張子フィルタリング処理
# --------------------------------------------------
$DefaultBinaryExtensions = @(
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico",
    ".zip", ".tar", ".gz", ".7z", ".rar",
    ".exe", ".dll", ".so", ".bin", ".pdf",
    ".docx", ".xlsx", ".pptx", ".bak"
)

if ($ExcludeExtension) {
    $UserExclude = $ExcludeExtension | ForEach-Object { if ($_ -notmatch "^\.") { ".$_" } else { $_ } } | ForEach-Object { $_.ToLower() }
    $FinalExclude = ($DefaultBinaryExtensions + $UserExclude) | Select-Object -Unique
} else {
    $FinalExclude = $DefaultBinaryExtensions
}

if ($IncludeExtension) {
    $IncludeExtension = $IncludeExtension | ForEach-Object { if ($_ -notmatch "^\.") { ".$_" } else { $_ } } | ForEach-Object { $_.ToLower() }
}

$FilteredFiles = @()
foreach ($f in $Files) {
    $ext = $f.Extension.ToLower()

    if ($IncludeExtension -and ($ext -notin $IncludeExtension)) {
        continue
    }

    if (-not $IncludeExtension -and ($ext -in $FinalExclude)) {
        continue
    }

    $FilteredFiles += $f
}

$Files = $FilteredFiles

# --------------------------------------------------
# 4. 初期ヘッダー表示
# --------------------------------------------------
$modeText = if ($Restore) { "CRLF復元モード (Linux -> Windows)" } else { "CR削除モード (Windows -> Linux)" }

Out-Log ""
Out-Log "==================================================" -Color Cyan
Out-Log "  改行コード変換ツール [$modeText]" -Color Cyan
Out-Log "==================================================" -Color Cyan
Out-Log " [対象フォルダ]     : $FolderPath" -Color Yellow
Out-Log " [検索モード]       : $(if ($Recursive) { 'サブフォルダ含む（再帰）' } else { '直下のみ' })" -Color Gray

if ($IncludeExtension) {
    Out-Log " [対象拡張子]       : $($IncludeExtension -join ', ')" -Color Gray
} else {
    Out-Log " [保護（自動除外）] : バイナリ系拡張子を保護中" -Color Gray
}
if ($Backup) {
    Out-Log " [バックアップ]     : 有効 (.bakファイルを作成)" -Color Yellow
}
Out-Log ""

if ($Files.Count -eq 0) {
    Out-Log " フィルタ条件に一致するファイルが見つかりませんでした。" -Color DarkGray
    Out-Log ""
    exit 0
}

# --------------------------------------------------
# 5. 点検（チェック）フェーズ
# --------------------------------------------------
Out-Log "--------------------------------------------------" -Color DarkGray
Out-Log "  ファイルの改行コードチェック" -Color Cyan
Out-Log "--------------------------------------------------" -Color DarkGray

$TargetFilesToFix = @()

foreach ($file in $Files) {
    $relativePath = $file.FullName.Replace($FolderPath, "").TrimStart("\")
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    
    $needsFix = $false
    $statusText = ""

    if (-not $Restore) {
        # 【CR削除モード】: 0x0D (CR) が含まれていれば対象
        if ($bytes -contains 0x0D) {
            $needsFix = $true
            $statusText = "CRが含まれています (要削除)"
        }
    } else {
        # 【CR復元モード】: 0x0D なしの 0x0A (単体LF) があれば対象
        for ($i = 0; $i -lt $bytes.Length; $i++) {
            if ($bytes[$i] -eq 0x0A) {
                if ($i -eq 0 -or $bytes[$i - 1] -ne 0x0D) {
                    $needsFix = $true
                    $statusText = "LFのみが含まれています (要CR追加)"
                    break
                }
            }
        }
    }

    if ($needsFix) {
        Out-Log " [ 要変換 ] " -Color Red -NoNewline $true
        Out-Log "$relativePath " -Color White -NoNewline $true
        Out-Log "($statusText)" -Color Red
        $TargetFilesToFix += $file
    } else {
        Out-Log " [ 正常   ] " -Color Green -NoNewline $true
        Out-Log "$relativePath " -Color White -NoNewline $true
        Out-Log "$(if ($Restore) { '(すでにCRLF)' } else { '(すでにLF)' })" -Color DarkGray
    }
}

if ($TargetFilesToFix.Count -eq 0) {
    Out-Log ""
    Out-Log " 変換が必要なファイルはありませんでした。" -Color DarkGray
    Out-Log ""
    exit 0
}

# --------------------------------------------------
# 6. Y/N 最終確認インタラクション
# --------------------------------------------------
Out-Log ""
if (-not $Force) {
    Write-Host "上記の $($TargetFilesToFix.Count) 件のファイルを変換します。" -ForegroundColor Yellow
    $response = Read-Host "変換処理を実行しますか？ (Y/N)"
    if ($response -notmatch "^[Yy]$") {
        Out-Log ""
        Out-Log "処理をキャンセルしました。ファイルの書き換えは行われていません。" -Color DarkGray
        Out-Log ""
        exit 0
    }
}

# --------------------------------------------------
# 7. 変更（変換）フェーズ
# --------------------------------------------------
Out-Log ""
Out-Log "--------------------------------------------------" -Color DarkGray
Out-Log "  改行コード変換処理" -Color Cyan
Out-Log "--------------------------------------------------" -Color DarkGray

$convertedCount = 0
$skippedCount = $Files.Count - $TargetFilesToFix.Count

foreach ($file in $TargetFilesToFix) {
    $relativePath = $file.FullName.Replace($FolderPath, "").TrimStart("\")
    
    try {
        if ($Backup) {
            Copy-Item -Path $file.FullName -Destination "$($file.FullName).bak" -Force
        }

        $rawBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $cleanBytes = [System.Collections.Generic.List[byte]]::new()
        
        if (-not $Restore) {
            # 【CR削除】: 0x0D (CR) を単に除外する
            foreach ($b in $rawBytes) {
                if ($b -ne 0x0D) {
                    $cleanBytes.Add($b)
                }
            }
        } else {
            # 【CR復元】: 単体 0x0A (LF) の直前に 0x0D (CR) を挿入する
            for ($i = 0; $i -lt $rawBytes.Length; $i++) {
                $b = $rawBytes[$i]
                if ($b -eq 0x0A) {
                    # 前の文字が CR でない場合のみ CR を挿入
                    if ($i -eq 0 -or $rawBytes[$i - 1] -ne 0x0D) {
                        $cleanBytes.Add([byte]0x0D)
                    }
                }
                $cleanBytes.Add($b)
            }
        }
        
        [System.IO.File]::WriteAllBytes($file.FullName, $cleanBytes.ToArray())

        Out-Log " [ 完了   ] " -Color Cyan -NoNewline $true
        Out-Log "$relativePath -> " -Color White -NoNewline $true
        Out-Log "$(if ($Restore) { 'CRLFに復元完了' } else { 'CR削除完了' })$(if ($Backup) { ' (.bak作成)' })" -Color Green
        $convertedCount++
    }
    catch {
        Out-Log " [ 失敗   ] " -Color Red -NoNewline $true
        Out-Log "$relativePath -> エラー: $_" -Color Red
    }
}

# --------------------------------------------------
# 8. 集計結果表示
# --------------------------------------------------
Out-Log ""
Out-Log "==================================================" -Color Cyan
Out-Log "  処理結果" -Color Cyan
Out-Log "==================================================" -Color Cyan
Out-Log "  ・変換したファイル数 : $convertedCount 件" -Color Green
Out-Log "  ・変更なしファイル数 : $skippedCount 件" -Color Gray
Out-Log "  ・チェック対象ファイル数 : $($Files.Count) 件"
Out-Log "==================================================" -Color Cyan
Out-Log ""

