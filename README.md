# HPID Bank — CDSP Demo Lab

Môi trường demo **Thales CipherTrust Data Security Platform (CDSP)** dạng ngân hàng giả lập, chạy hoàn toàn bằng Docker Compose với image public trên Docker Hub.

**Mục tiêu:** Chỉ cần chuẩn bị CipherTrust Manager và điền 3 registration token cùng IP của CM vào file `.env`, sau đó `docker compose up -d` là có ngay môi trường demo đầy đủ — không cần build code.

---

## Kiến trúc tổng quan

```
┌──────────────────────────────────────────────────────────────┐
│                      Demo Host (Docker)                      │
│                                                              │
│  App1 v1 :5001 ──────────────────────────► postgres-prod     │
│  App1 v2 :5002 ──► CRDP :8090 ───────────► postgres-prod     │
│                                                              │
│  App2 v1 :8001 ──────────────────────────► app2-backend      │
│  App2 v2 :8002 ──► DPG :8990 ────────────► app2-backend      │
│                         │                       │            │
│                         └──────────────────► postgres-prod   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
          │ Registration                  │ Registration
          ▼                               ▼
  ┌────────────────────────────────────────────┐
  │          CipherTrust Manager               │
  │  (chuẩn bị riêng, ngoài Docker Compose)    │
  └────────────────────────────────────────────┘
```

### Danh sách service & port

| Service | Port | Mô tả |
|---|---|---|
| `app1-v1` | **5001** | Banking portal (Flask) — dữ liệu plaintext |
| `app1-v2` | **5002** | Banking portal (Flask) — tích hợp CRDP |
| `app2-frontend-v1` | **8001** | Banking app (React) — trỏ thẳng backend |
| `app2-frontend-v2` | **8002** | Banking app (React) — qua DPG proxy |
| `pgAdmin` | **5050** | Quản lý DB trực quan |
| `crdp` | 8090 / 8080 | CipherTrust RESTful Data Protection |
| `dpg` | 8990 | CipherTrust Data Protection Gateway |
| `bdt` | 8010 | CipherTrust Batch Data Transformation |
| `postgres-prod` | 5432 | DB chính (`customers`, `app_users`) |

---

## Yêu cầu trước khi chạy

### 1. Demo Host
- Docker Engine ≥ 24 + Docker Compose v2
- Kết nối mạng tới CipherTrust Manager

### 2. CipherTrust Manager (chuẩn bị sẵn)

Cấu hình các thành phần sau trên CM trước khi khởi động lab:

**Keys**

| Tên | Loại | Mô tả |
|---|---|---|
| `hpidbank_master_key` | AES-256 | Key gốc cho toàn bộ lab |

**Protection Policies**

| Tên | Loại | Mô tả |
|---|---|---|
| `pol_cccd_fpe` | Protection Policy — FPE/FF1v2 | Tokenize số CCCD (12 chữ số) |
| `pol_credit_card_fpe` | Protection Policy — FPE/FF1v2 | Tokenize số thẻ tín dụng (16 chữ số) |

**Access Policies (dành cho DPG)**

| Tên | Thành viên | Quyền trên DPG |
|---|---|---|
| `acc_cccd_role_based` | — | Áp `pol_cccd_fpe` theo User Set |
| `acc_cc_role_based` | — | Áp `pol_credit_card_fpe` theo User Set |

**User Sets**

| Tên | Thành viên | Quyền trên DPG |
|---|---|---|
| `admins` | `admin`, `app1` | Reveal — xem plaintext |
| `viewers` | `viewer1`, `viewer2` | Masked — xem dữ liệu che |

**DPG Policy — JSONPath rules**

Tạo 2 rule riêng cho policy `tok_dpg`:

| Endpoint | JSONPath CCCD | JSONPath Credit Card |
|---|---|---|
| List (`/api/customers`) | `customers.[*].cccd` | `customers.[*].credit_card_no` |
| Detail (`/api/customers/:id`) | `customer.cccd` | `customer.credit_card_no` |

**Registration Tokens**

Tạo 3 registration token riêng biệt trên CM cho: **CRDP**, **DPG**, **BDT**.

---

## Khởi động nhanh

### Bước 1 — Clone repo

```bash
git clone https://github.com/<your-org>/hpidbank-demo.git
cd hpidbank-demo
```

### Bước 2 — Tạo file `.env`

```bash
cp .env.example .env
```

Mở `.env` và điền các thông tin bắt buộc:

```env
# IP hoặc hostname của CipherTrust Manager
KMS=<ip-ciphertrust-manager>

# Registration tokens lấy từ CM
CRDP_REG_TOKEN=<token>
DPG_REG_TOKEN=<token>
BDT_REG_TOKEN=<token>
```

> Các biến còn lại (DB password, app secrets) đã có giá trị mặc định phù hợp cho môi trường demo — không cần thay đổi.

### Bước 3 — Khởi động

```bash
docker compose up -d
```

Docker sẽ tự pull image từ Docker Hub (`hpidsg/hpidbank-*`). Lần đầu mất vài phút tùy tốc độ mạng.

### Bước 4 — Kiểm tra

```bash
docker compose ps
```

Tất cả service ở trạng thái `Up` là sẵn sàng.

> **DB được seed tự động** khi `postgres-prod` khởi động lần đầu — 50 khách hàng mẫu với dữ liệu plaintext sẽ được tạo sẵn từ `sql/01-init.sql`.

---

## Tài khoản demo

### App1 (Flask — port 5001 / 5002)

| Username | Password | Role |
|---|---|---|
| `teller1` | `Teller@123` | Giao dịch viên |

### App2 (React — port 8001 / 8002)

| Username | Password | Role (JWT) | Xem data qua DPG |
|---|---|---|---|
| `admin` | `Admin@123` | `admin` | Plaintext đầy đủ |
| `viewer1` | `Viewer@123` | `viewer` | Dữ liệu bị mask |
| `viewer2` | `Viewer@123` | `viewer` | Dữ liệu bị mask |

### pgAdmin (`http://<host>:5050`)

| Email | Password |
|---|---|
| `admin@hpidbank.demo` | `Admin@123` |

Sau khi đăng nhập, thêm server:
- **Host:** `postgres-prod` · **Port:** `5432` · **Database:** `hpidbank`
- **Username:** `hpidbank` · **Password:** `Hpid@bank2026`

---

## Kịch bản demo

### Phase 1 — Baseline (dữ liệu plaintext)

1. Mở **App1 v1** (`http://<host>:5001`) — đăng nhập, xem danh sách khách hàng
2. Mở **App2 v1** (`http://<host>:8001`) — tương tự với giao diện React
3. Kiểm tra **pgAdmin** — CCCD và số thẻ lưu **hoàn toàn rõ ràng** trong DB

👉 *Talking point: bất kỳ ai có quyền DBA, backup, hoặc xâm nhập DB đều thấy toàn bộ dữ liệu nhạy cảm.*

### Phase 2 — BDT (Tokenize dữ liệu hàng loạt)

1. Trong CM, tạo **Data Source** trỏ vào `postgres-prod`
2. Tạo **Job Configuration** với các cột `cccd`, `credit_card_no`, policy FPE tương ứng
3. Chạy job — quay lại pgAdmin: dữ liệu cũ đã được **tokenize tại chỗ**
4. Kiểm tra audit log trên CM — mọi operation đều được ghi lại

### Phase 3 — CRDP (App1 v2 — tích hợp API)

1. Mở **App1 v2** (`http://<host>:5002`) — CCCD và số thẻ hiển thị **plaintext bình thường** trên UI
2. Tạo khách hàng mới — UI bình thường, nhưng pgAdmin cho thấy DB **lưu token**
3. So sánh code: `app1-v1` vs `app1-v2` — chỉ thêm **~6 dòng** gọi CRDP protect/reveal

👉 *Talking point: developer chỉ thêm vài dòng API call — không cần hiểu cryptography, không thay schema.*

### Phase 4 — DPG (App2 v2 — zero code change)

1. Đăng nhập **App2 v2** (`http://<host>:8002`) với `viewer1` — CCCD và số thẻ **bị mask**
2. Logout → đăng nhập với `admin` — thấy **plaintext đầy đủ**
3. Mở DevTools Network → xem response từ DPG đã mask sẵn trước khi về browser
4. Code `app2-backend` **không có một dòng nào** về encryption

👉 *Talking point: backend legacy không cần sửa code — DPG hoạt động như transparent proxy, policy quản lý trên CM.*

---

## Gỡ lỗi nhanh

```bash
# Xem log một service
docker compose logs -f crdp
docker compose logs -f dpg
docker compose logs -f app1-v2

# Restart một service
docker compose restart app1-v2

# Dừng toàn bộ (giữ data volume)
docker compose down

# Reset hoàn toàn kể cả data
docker compose down -v
```

**Lỗi thường gặp:**

| Triệu chứng | Nguyên nhân | Hướng xử lý |
|---|---|---|
| CRDP/DPG/BDT không kết nối CM | Registration token sai hoặc hết hạn | Tạo lại token trên CM |
| App1 v2 lỗi khi tạo KH | Protection policy chưa tạo trên CM | Tạo `pol_cccd_fpe` và `pol_credit_card_fpe` |
| DPG không mask dữ liệu | JSONPath rule chưa đúng | Kiểm tra rule cho list vs detail endpoint |
| DPG detail vẫn trả token thô | Rule thiếu cho endpoint detail | Thêm rule `customer.cccd` (không có `[*]`) |
| Admin login vẫn thấy masked data | Browser cache response cũ | Đã xử lý trong nginx — thử hard reload (`Ctrl+Shift+R`) |

---

## Cấu trúc repo

```
hpidbank-demo/
├── docker-compose.yml          # Orchestration toàn bộ lab
├── .env.example                # Template biến môi trường
├── bulk-gen-customer.py        # Script tạo dữ liệu mẫu analytics DB
└── sql/
    ├── 01-init.sql             # Schema + seed 50 khách hàng (postgres-prod)
    └── 02-analytics-init.sql   # Schema analytics (postgres-analytics)
```

> Source code các app được đóng gói sẵn trong Docker images trên [Docker Hub — hpidsg](https://hub.docker.com/u/hpidsg). Không cần build local.

---

## Liên hệ

[vuong.nguyen@hpid.vn](mailto:vuong.nguyen@hpid.vn)
