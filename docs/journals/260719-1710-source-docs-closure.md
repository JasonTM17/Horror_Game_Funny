---
date: 2026-07-19
session: source-docs-closure
status: resolved
---

# Khép source/docs sau khi bóc các đường xanh giả

**Date**: 2026-07-19 17:10
**Severity**: High
**Component**: Physical evidence, Windows export, packaging, repository docs
**Status**: Resolved for source/review/delivery; PDR-07 vẫn mở

## What Happened

Diff lộ năm đường xanh giả. Runner gọi Godot trực tiếp nên có thể treo vô hạn và để lại descendant. Parser chỉ yêu cầu một payload toàn cục, cho phép side-channel hash-verified nhưng rỗng được che bởi log khác. Export timeout probe có fake path exit `0` trước deadline. Bash verifier grep tên, không kiểm active count/order. Docs validator nhìn filesystem, không Git index, nên link untracked có thể pass local rồi gãy khi landing. Automated/source closure và PDR-07 là hai gate riêng.

## The Brutal Truth

Đây là kiểu xanh giả gây đau nhất: dashboard sạch nhưng provenance và landing contract đều thủng. Thật bực vì chúng ta kiểm tín hiệu thuận tiện thay vì ranh giới thất bại. Dùng automation để đóng PDR-07 sẽ là bịa bằng chứng chơi thật; việc đó chưa xảy ra.

## Technical Details

- `tests/run-physical-playthrough.ps1` nay dùng Job Object, mặc định `7200` giây/`16777216` byte, và đòi đúng một `PLAYTHROUGH_PACING` payload trong mỗi verified side-channel.
- Review bắt **2 High/1 Medium** trong `tests/windows-export-job-runner.cs`: write dưới `outputLock` chặn pumps; `Dispose()` join vô hạn treo cleanup; `CreatePipe` failure để output handles không xác định. Targeted fixes đã áp dụng; final review đóng với 0 Critical/High/Medium.
- Sau sửa: cold physical regression đủ **5 markers** và Windows export adversarial pass. Host **12/12**, actual Windows export/process smoke, packaging PS+Bash, Docker build/container **12/12** cũng pass.
- Bash verifier nay ràng đúng 12 active invocations theo thứ tự; docs validator dùng `git ls-files --cached -z`. Real-index gate đã chạy trước/sau commit và phát đủ bốn marker thành công.

## What We Tried

Quyết định là fail closed: bounded Job/output, payload theo từng side-channel, slow fake, structural order và indexed links. Direct/global/timing-dependent, grep-only và filesystem-only không chứng minh artifact được giao.

## Root Cause Analysis

Nguyên nhân gốc: chúng ta viết gate quanh happy path và nhầm “file/hash/tên tồn tại” với bằng chứng đúng nguồn, đúng nhánh lỗi, đúng thứ tự và thực sự được commit. C# runner còn đưa blocking I/O vào shared lock và bỏ deadline cleanup — lỗi thiết kế concurrency, không phải lỗi vặt.

## Lessons Learned

Mọi resource phải có budget; mỗi evidence source phải tự hoàn chỉnh; adversarial test phải ép đúng nhánh lỗi; docs gate phải kiểm index. Cleanup cũng phải bounded.

## Next Steps

- Delegated reviewer và QA/delivery owner: **hoàn tất**. Hai commit `ad514cb`/`c28beee` đã land non-force; remote parity và hai workflow CI đều xanh.
- Docker Hub: workflow skip vì không có Actions secrets; registry digest vẫn không tồn tại và không được claim.
- Human reviewer: chạy production-window bằng input vật lý, capture từ `START SHIFT` tới credits và ký review; chỉ bước đó mới đóng PDR-07.

## Resolution Update

The final CK review found and closed three more trust-boundary defects: the direct
unbounded Godot `--version` preflight, staged-index blob/mode confusion, and a media
allowlist suffix blind spot. The version probe now shares the bounded Job path; the docs
gate reads stage-0 regular blobs by object ID and rejects staged content/mode drift; the
media allowlist covers every indexed path regardless of extension. Final review is
**Pass for staging** with zero unresolved Critical/High/Medium findings and one
informational `git cat-file` process-efficiency Low. Delivery then passed the real-index
gate, landed `ad514cb` plus report-containing `c28beee`, reached 0/0 remote parity, and
completed both matching CI workflows successfully. Docker Hub skipped for absent secrets.
Only the separate human PDR-07 gate remains open.
