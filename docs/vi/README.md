# ROOM 407: THE LAST SHIFT - Hướng dẫn tiếng Việt

Đây là hướng dẫn tiếng Việt đã được biên tập cho người chơi và người tải bản phát hành.
Tài liệu kỹ thuật, bằng chứng kiểm thử, checksum và điều khoản phát hành gốc vẫn là tiếng
Anh; xem [Documentation Hub](../README.md) và [release notes](../release-v0.9.0.md). Đây
**không** phải là bản dịch giao diện, phụ đề hay lồng tiếng trong game.

## Tải bản Windows x64

Bản chính thức, khi đã được công bố, nằm tại
[GitHub Release v0.9.0](https://github.com/JasonTM17/Horror_Game_Funny/releases/tag/v0.9.0).
Tải cả hai tệp sau từ cùng một release:

1. `room-407-the-last-shift-windows-x86_64-v0.9.0.zip`
2. `room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt`

Đây là bản **portable ZIP cho Windows x64**, không phải installer. Không tải từ nguồn
khác, và không chạy nếu release page chưa liệt kê hai tệp trên.

## Kiểm tra checksum và chạy

Mở PowerShell trong thư mục chứa hai tệp đã tải:

```powershell
$zip = '.\room-407-the-last-shift-windows-x86_64-v0.9.0.zip'
$sums = '.\room-407-the-last-shift-windows-x86_64-v0.9.0-SHA256SUMS.txt'
$name = [IO.Path]::GetFileName($zip)
$records = @(Get-Content -LiteralPath $sums | Where-Object { $_ -match '\S' })
$pattern = '^(?<hash>[A-Fa-f0-9]{64}) \*' + [regex]::Escape($name) + '$'
if ($records.Count -ne 1) { throw 'Checksum phải có đúng một dòng hợp lệ.' }
$match = [regex]::Match($records[0], $pattern)
if (-not $match.Success) { throw 'Dòng checksum sai định dạng hoặc trỏ đến tệp khác.' }
$expected = $match.Groups['hash'].Value.ToUpperInvariant()
$actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToUpperInvariant()
if ($actual -ne $expected) { throw 'Checksum không khớp. Không giải nén hoặc chạy tệp.' }

$destination = Join-Path (Get-Location) 'ROOM-407-v0.9.0'
if (Test-Path -LiteralPath $destination) { throw "Không dùng lại thư mục đã giải nén: $destination" }
Expand-Archive -LiteralPath $zip -DestinationPath $destination -ErrorAction Stop
$exe = Join-Path $destination 'ROOM-407-THE-LAST-SHIFT-v0.9.0\ROOM_407_THE_LAST_SHIFT.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Không tìm thấy tệp chạy ở đúng đường dẫn trong archive.' }
& $exe
```

- Giải nén toàn bộ archive trước khi chạy; giữ `LICENSE`, `THIRD_PARTY_NOTICES.md` và
  `GODOT_COPYRIGHT.txt` cùng bản phát hành.
- Bản này chưa ký code-signing. Windows SmartScreen có thể hiện cảnh báo cho tệp chưa
  được nhận dạng. Chỉ xem xét chạy sau khi đã xác minh checksum, URL GitHub và nguồn tải;
  nếu không chắc chắn, dừng lại và không bỏ qua cảnh báo.
- Với tệp đã tự xác minh từ release chính thức và bạn đã quyết định tin tưởng, Windows có
  thể yêu cầu vào **More info** rồi **Run anyway**. Điều này không thay thế việc kiểm tra
  checksum.

## Điều khiển

| Hành động | Phím |
|---|---|
| Di chuyển | W, A, S, D |
| Nhìn | Chuột |
| Chạy nhanh | Shift |
| Tương tác | E |
| Đèn pin | F |
| Xem mục tiêu | Tab |
| Tạm dừng | Escape |

Menu tạm dừng có Settings cho độ nhạy chuột, FOV, âm lượng, fullscreen và các tùy chọn
comfort. Checkpoint chỉ tồn tại trong phiên đang chạy; cài đặt có thể được lưu riêng.

## Giới hạn quan trọng

- Game là psychological horror và có cảnh tối, nhấp nháy, âm thanh bất ngờ và truy đuổi.
- Không có human physical/perceptual playtest được ghi nhận cho bản release này. Các test
  tự động không chứng minh độ sáng, âm thanh, input thật, độ công bằng khi truy đuổi hay
  hiệu năng trên máy của bạn. PDR-07 đã được chủ sở hữu chấp nhận rủi ro; xem
  [limitations](../limitations.md) để biết chi tiết.
- Game hiện dùng giao diện, phụ đề và voice tiếng Anh. Hướng dẫn này không thay đổi nội
  dung trong game.

## Source và container test

- Source: [GitHub repository](https://github.com/JasonTM17/Horror_Game_Funny). Cách chạy
  bằng Godot nằm trong [Deployment guide](../deployment-guide.md).
- `ghcr.io/jasontm17/horror-game-suite` là container cho **CI/headless tests**, không
  phải bản game để chơi. Không dùng Docker image để tải hoặc chạy game Windows.

## Hỗ trợ và bảo mật

Báo lỗi có thể lặp lại tại [Issues](https://github.com/JasonTM17/Horror_Game_Funny/issues).
Với vấn đề bảo mật, làm theo [Security Policy](../../SECURITY.md) và không công khai chi
tiết có thể khai thác trước khi có bản sửa.
