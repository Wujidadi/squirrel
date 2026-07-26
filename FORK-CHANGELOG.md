# Fork 變更日誌

本檔記錄本 fork（Wujidadi/squirrel）相對上游 rime/squirrel 的所有變動，依自建版版號分節。
上游自身的變更見 `CHANGELOG.md`；分支與版號規範見 `FORK-POLICY.md`。

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
