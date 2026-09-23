# Fork 變更日誌

本檔記錄本 fork（Wujidadi/squirrel）相對上游 rime/squirrel 的所有變動，依自建版版號分節。
上游自身的變更見 `CHANGELOG.md`；分支與版號規範見 `FORK-POLICY.md`。

## 1.1.2-wujidadi.6 — 2026-09-23

### 基礎設施

- librime 子模組自 c7d525ed 更新至 37e47f86（fork `1.17.0-wujidadi.1`，基於上游 ef1a16aa）並重新編譯：
  fork 將上游 de21e7d4 的 userdb 詞條老化丟棄常量門檻 `1e-200` 改為設定項 `<ns>/user_dict_forget_threshold`，預設 `0` 不遺忘、設 `1e-200` 即恢復上游行為，
  避免整批 t 同值的詞條跨過門檻時一次全部失效（2026-09-22 terra_pinyin userdb 實測 839,655 條退回字典碼位序）；
  另帶進上游 ef1a16aa 之前的更新（含 opencc 子模組升至 ver.1.4.2、chording 相關機制），均屬上游內容、不另記於本檔
- `project.pbxproj` 的「Copy opencc Files」清單補入 OpenCC 1.4.2 新增的 `HKPhrases.ocd2`／`HKPhrasesRev.ocd2`（`hk2sp`／`s2hkp` 系列設定所引用），否則 Xcode 靜默不打包

## 1.1.2-wujidadi.5 — 2026-08-25

### 基礎設施

- librime 子模組自 4817d294 更新至 c7d525ed（fork 於 2026-08-25 合併上游 417db238 的版本）並重新編譯：
  上游帶進 prism 查詢效能改進（1d0df6e4）、CandidatePreview API（本前端未採用），
  以及 dee 極小值丟棄門檻（de21e7d4）與其誤丟 custom_phrase 無權重詞條回歸的修正（8dc90354）；
  pin 直接跳過含回歸、無修正的 3b3bb360～9b46caec 區間

## 1.1.2-wujidadi.4 — 2026-08-22

### 基礎設施

- 合併上游 master 至 0cd71a6（5400420）：上游變更含本 fork 先前貢獻回上游的 `SquirrelApp.appDir` 路徑修正（PR #1161）與標示區字型自訂（`preedit_font_face`／`preedit_font_point`），均屬上游內容、不另記於本檔

## 1.1.2-wujidadi.3 — 2026-08-09

### 行為變更

- 新增離線維護旗標：`~/Library/Rime/.maintenance-hold` 存在且未逾 10 分鐘時，無參數啟動（輸入法常駐模式）的實例立即退場，CLI 動詞不受約束。
  供 dotfiles 的 `rime-hold-quit` 於離線重建 userdb 期間阻止 TIS 隨需重啟的實例與 `rime_dict_manager` 競逐同一 LevelDB（此競態 2026-08-08 實測會造成 `CURRENT` 指向已刪 MANIFEST 的損壞）；
  macOS 26 對終端行程的 TISDisableInputSource 靜默失效，無法以停用輸入來源阻擋，故以旗標為之，逾時自動失效避免旗標意外殘留時輸入法永久無法啟動（64c009a）

### 基礎設施

- 合併上游 master 至 1dde022（94dc740）：上游變更含本 fork 先前貢獻回上游的標示文字直接上屏支援與狀態列圖標隱藏修正等，均屬上游內容、不另記於本檔

## 1.1.2-wujidadi.2 — 2026-07-27

### 修正

- 修正 CLI 散布通知不送達的問題：`--reload`、`--sync`、`--ascii`、`--nascii`、`--getascii` 五處發送改用 `deliverImmediately: true`。
  鼠鬚管是背景 App，AppKit 對非作用中 App 暫停散布通知投遞，原本預設發送方式會被佇列或丟棄，
  致 CLI 指令靜默無效（選單同名功能因行程內直呼不受影響）、偶爾在鼠鬚管短暫活躍時遲到補送（b10692d）

## 1.1.2-wujidadi.1 — 2026-07-26

### 基礎設施

- librime 子模組更新至含 fork 版號標記的版本（`1.17.0-wujidadi`）：`installation.yaml` 與 userdb 中繼資料自此可直接分辨機器上跑的是官方或 fork 的 librime

## 1.1.2-wujidadi — 2026-07-25

基於上游 master 2158538（官方 1.1.2 之後的開發版）。首個自建版。

### 行為變更

- `--register-input-source` 改為無條件重新註冊（原本已啟用時直接跳過），bundle 更換後可強制 TIS 重新整理來源紀錄（bced6b4）
- 版號改採 SemVer 相容格式 `<官方當前正式版>-wujidadi[.流水號]`；曾短暫使用的 `w` 前綴格式會被 Sparkle 判舊於官方版、有降級提示隱患，已棄用（d5acfc4、1e9af1c）

### 修正

- 修正 `SquirrelApp.appDir` 輸入法安裝路徑誤植（`/Library/Input Library/…` → `/Library/Input Methods/…`）；此為上游自 Swift 移轉（ce4f761）以來的 bug，致顯式重新註冊靜默失效。已回報上游：rime/squirrel#1161（0939d8a）
- 修正 `package/add_data_files` 的 `file_ref_entry` 錨點模板（`lastKnownFileType` 誤為 `text`，實際專案檔為 `text.yaml`），並改為依副檔名分派檔案型別；原 bug 使新資料檔缺 `PBXFileReference` 而被 Xcode 靜默漏打包，上游 4db2c85 的兩個 octagram `.gram` 檔案參考亦因此不完整，一併補齊。已回報上游：rime/squirrel#1160（3641740、e904057）
- `project.pbxproj` 的「Copy opencc Files」清單同步新版 OpenCC 字典檔名：移除已更名的 `JPVariants.ocd2`／`JPVariantsRev.ocd2`，新增 `CJK_Compatibility_Ideographs.ocd2` 等六檔（3641740）

### 基礎設施

- Sparkle 子模組固定至 2.9.4，librime 子模組固定至 2026-07-04 的上游 latest（3c0c199）
- librime 子模組改指自家 fork（Wujidadi/librime），依序納入 `--purge` 與同步合併新語義（095bcfd、eab7ad9；功能內容見 librime 倉庫的 `FORK-CHANGELOG.md`）
- 新增 `FORK-POLICY.md` 開發與貢獻規範及 `CLAUDE.local.md` 指標檔（3b4eb38）
