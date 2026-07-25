# 本倉庫開發與貢獻規範

2026-07-25T15:17:42+08:00

本倉庫（Wujidadi/squirrel）是 rime/squirrel（鼠鬚管）的 fork。
目標是基於原作（上游），逐步將鼠鬚管打造為最適配倉庫擁有者個人的完全客製化輸入法。

## 分支原則

- 本倉庫的 master 分支**永不直接合併回上游**。
- 當上游 master 有更新，或其他分支有值得吸收的變化時，本地 master 可合併它們（方向永遠是「上游→本地」）。
- 發現上游主專案有 bug 應修，或本地開發遇到值得貢獻回去的東西，一律從 `upstream/master` 開獨立分支，以 cherry-pick 擷取或獨立重寫的方式製作變更，再向上游提 PR；不可拿本地 master 或混有本地客製內容的分支直接開 PR。

## 語言規範

- 本地 master 及其他暫不考慮合回上游的分支：程式碼異動、註解、commit message、AI agent 指引檔（如 `.claude`、`.codex`、`CLAUDE.local.md`）等，一律使用繁體中文（台灣）。
- 只要是會合回上游的內容，一律用英文撰寫，包括 PR 與 Issue 的標題及內文。
- 若某分支起初是獨立開發、後來決定合回上游，則所有會進到上游的中文程式碼、註解與文檔都應改為英文。
- 本地分支中確定（或幾乎確定）不合回上游、但有部分內容值得貢獻的，以「從 `upstream/master` 開新分支，cherry-pick 或參考原異動獨立修改」為主，減少本地與上游互相合併的衝突與污染風險。
- 從上游 PR 分支 cherry-pick 回本地 master 的內容，程式碼與註解保持與 PR 逐字一致（英文），只有 commit message 改寫為繁體中文；如此上游合併後再同步時不會產生內容衝突。

## 版號慣例

- 自建版版號＝官方版號前綴 `w`（wujidadi 首字母），再加第四段自建流水號，如 `w1.1.2.1`。
- 版號定義於 `Squirrel.xcodeproj/project.pbxproj` 的 `CURRENT_PROJECT_VERSION`（Debug 與 Release 各一處）。
