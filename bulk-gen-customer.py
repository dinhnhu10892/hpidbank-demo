#!/usr/bin/env python3
"""
Bulk-load N customers PLAINTEXT trực tiếp vào postgres-prod/hpidbank_analytics/customers.

Dùng cho demo Phase 4 BDT:
  → Tình huống: analytics team được cấp dữ liệu plaintext để train model / báo cáo.
  → Table customers lưu dữ liệu đã được reveal (hoặc load thẳng như script này).

Usage:
  python3 tests/bulk-load-analytics-clear.py          # mặc định 500 records
  python3 tests/bulk-load-analytics-clear.py 1000

Yêu cầu: postgres-prod đang chạy (port 5433 từ host, hoặc 5432 trong docker network).
"""
import sys
import os
import random
import string
import psycopg2
import psycopg2.extras

N = int(sys.argv[1]) if len(sys.argv) > 1 else 500

DB = dict(
    host=os.environ.get("DB_HOST",     "localhost"),
    port=int(os.environ.get("DB_PORT", "5433")),        # analytics expose 5433 ra host
    dbname=os.environ.get("DB_NAME",   "hpidbank_analytics"),
    user=os.environ.get("DB_USER",     "analytics"),
    password=os.environ.get("DB_PASSWORD", "Analytics@2026"),
)

# ── Data generators ──────────────────────────────────────────────────────────
VN_LASTNAMES = ["Nguyễn","Trần","Lê","Phạm","Hoàng","Huỳnh","Phan","Vũ","Đặng","Bùi",
                "Đỗ","Hà","Đinh","Dương","Ngô","Lý","Tô","Mai","Lưu","Tạ"]
VN_MIDDLE    = ["Văn","Thị","Quốc","Minh","Thanh","Hồng","Đức","Bảo","Thành","Tiến"]
VN_FIRST     = ["An","Bình","Châu","Dũng","Hà","Lan","Linh","Mai","Nam","Phong",
                "Quân","Thảo","Tùng","Uyên","Vinh","Xuân","Yến","Khoa","Long","Hùng"]
PROVINCES    = ["Hà Nội","TP. Hồ Chí Minh","Đà Nẵng","Hải Phòng","Cần Thơ",
                "Bình Dương","Đồng Nai","Khánh Hòa","Nghệ An","Thanh Hóa"]

def gen_name():
    return f"{random.choice(VN_LASTNAMES)} {random.choice(VN_MIDDLE)} {random.choice(VN_FIRST)}"

def gen_cccd():
    return "".join(random.choices(string.digits, k=12))

def gen_cc():
    """Số thẻ 16 chữ số hợp lệ Luhn."""
    prefix15 = "4" + "".join(random.choices(string.digits, k=14))
    total = sum(
        (n * 2 - 9 if n * 2 > 9 else n * 2) if i % 2 == 0 else n
        for i, n in enumerate(int(d) for d in reversed(prefix15))
    )
    return prefix15 + str((10 - total % 10) % 10)

def gen_phone():
    prefixes = ["032","033","034","035","036","037","038","039",
                "086","096","097","098","070","079","077","078","076"]
    return random.choice(prefixes) + "".join(random.choices(string.digits, k=7))

def gen_dob():
    return f"{random.randint(1960,2000):04d}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"

def gen_account():
    return "ACC" + "".join(random.choices(string.digits, k=9))

# ── Main ─────────────────────────────────────────────────────────────────────
def main():
    print(f"Loading {N} plaintext customers → postgres-prod / customers")
    print(f"DB: {DB['host']}:{DB['port']}/{DB['dbname']}")
    print()

    conn = psycopg2.connect(**DB)
    conn.autocommit = False
    cur  = conn.cursor()

    # Lấy max id hiện tại để tránh conflict PRIMARY KEY
    cur.execute("SELECT COALESCE(MAX(id), 0) FROM customers")
    start_id = cur.fetchone()[0] + 1
    print(f"Starting id from {start_id}")

    BATCH   = 500
    rows    = []
    inserted = 0

    for i in range(N):
        rows.append((
            start_id + i,                                           # id (INT PK, explicit)
            gen_name(),
            f"cust{start_id + i:06d}@analytics.demo",
            gen_phone(),
            gen_cccd(),                                             # plaintext
            gen_dob(),
            f"Số {random.randint(1,999)} đường {random.randint(1,99)}, {random.choice(PROVINCES)}",
            gen_cc(),                                               # plaintext
            gen_account(),
            round(random.uniform(1_000_000, 500_000_000), 2),
            random.choice(["verified","verified","verified","pending"]),
        ))

        if len(rows) >= BATCH:
            psycopg2.extras.execute_values(cur,
                """INSERT INTO customers
                   (id, full_name, email, phone, cccd, dob, address,
                    credit_card_no, account_no, balance, kyc_status)
                   VALUES %s
                   ON CONFLICT (id) DO NOTHING""",
                rows
            )
            conn.commit()
            inserted += len(rows)
            rows = []
            print(f"  [{inserted/N*100:5.1f}%] {inserted:,}/{N:,} records")

    if rows:
        psycopg2.extras.execute_values(cur,
            """INSERT INTO customers
               (id, full_name, email, phone, cccd, dob, address,
                credit_card_no, account_no, balance, kyc_status)
               VALUES %s
               ON CONFLICT (id) DO NOTHING""",
            rows
        )
        conn.commit()
        inserted += len(rows)

    cur.execute("SELECT COUNT(*) FROM customers")
    total = cur.fetchone()[0]
    cur.close()
    conn.close()

    print()
    print(f"Done: {inserted:,} records inserted.")
    print(f"Total rows in customers: {total:,}")


if __name__ == "__main__":
    main()
