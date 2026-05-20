-- =========================================================================
-- HPID Bank — schema khởi tạo
-- DB: hpidbank (chung cho App1 v1, App1 v2, App2)
-- =========================================================================

-- Bảng user dùng chung cho cả 2 app (App1 dùng role teller/auditor, App2 dùng admin/viewer)
CREATE TABLE IF NOT EXISTS app_users (
    id           SERIAL PRIMARY KEY,
    username     VARCHAR(64) UNIQUE NOT NULL,
    email        VARCHAR(120),
    password_hash TEXT NOT NULL,            -- bcrypt
    full_name    VARCHAR(120),
    role         VARCHAR(32) NOT NULL,      -- teller | auditor | admin | viewer
    app_scope    VARCHAR(8) NOT NULL,       -- 'app1' | 'app2' | 'both'
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_users_username ON app_users(username);

-- =========================================================================
-- Bảng customer — cùng table cho cả App1 và App2
-- 2 cột nhạy cảm: cccd (CCCD VN, 12 chữ số), credit_card_no (16 chữ số)
-- FPE giữ nguyên format/length nên VARCHAR(12) và VARCHAR(16) hoạt động tốt
-- cho cả plaintext (Phase 1) lẫn tokenized (Phase 2+)
-- =========================================================================
CREATE TABLE IF NOT EXISTS customers (
    id              SERIAL PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(120),
    phone           VARCHAR(20),
    cccd            VARCHAR(64),                -- nhạy cảm (FPE token có thể dài hơn plaintext)
    dob             DATE,
    address         VARCHAR(255),
    credit_card_no  VARCHAR(64),               -- nhạy cảm (FPE token có thể dài hơn plaintext)
    account_no      VARCHAR(20),
    balance         NUMERIC(30,2) DEFAULT 0,
    kyc_status      VARCHAR(20) DEFAULT 'pending',
    created_by      VARCHAR(64),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_full_name ON customers(full_name);

-- Khởi giá trị id customer từ 1001 cho dễ track trong demo
ALTER SEQUENCE customers_id_seq RESTART WITH 1001;

-- =========================================================================
-- Seed user demo
-- Password mặc định cho mọi user demo: Demo@123  (bcrypt cost 12)
-- =========================================================================

INSERT INTO app_users (username, email, password_hash, full_name, role, app_scope) VALUES
  ('teller01', 'teller01@hpidbank.vn',
   '$2b$12$s3192pqYi13CV1hZXyiOburwQap68q5bliD5qdGQC4d5SBKIzSMfu',
   'Trần Thị Lan (Teller)', 'teller', 'app1'),
  ('auditor', 'auditor@hpidbank.vn',
   '$2b$12$s3192pqYi13CV1hZXyiOburwQap68q5bliD5qdGQC4d5SBKIzSMfu',
   'Phạm Văn Auditor', 'auditor', 'app1'),
  ('admin', 'admin@hpidbank.vn',
   '$2b$12$s3192pqYi13CV1hZXyiOburwQap68q5bliD5qdGQC4d5SBKIzSMfu',
   'Lê Quốc Admin', 'admin', 'app2'),
  ('viewer1', 'viewer1@hpidbank.vn',
   '$2b$12$s3192pqYi13CV1hZXyiOburwQap68q5bliD5qdGQC4d5SBKIzSMfu',
   'Nguyễn Thị Viewer', 'viewer', 'app2'),
  ('viewer2', 'viewer2@hpidbank.vn',
   '$2b$12$s3192pqYi13CV1hZXyiOburwQap68q5bliD5qdGQC4d5SBKIzSMfu',
   'Hoàng Văn Viewer', 'viewer', 'app2')
ON CONFLICT (username) DO NOTHING;

-- =========================================================================
-- Seed 50 khách hàng mẫu — plaintext (Phase 1 demo)
-- CCCD: 12 chữ số thực tế VN (08x = Hà Nội, 07x = TP.HCM, 06x = miền Trung...)
-- Credit card: 16 chữ số, prefix 9704 (Napas VN)
-- Balance: đa dạng từ 500k đến 500tr VND
-- =========================================================================
INSERT INTO customers
  (full_name, email, phone, cccd, dob, address, credit_card_no, account_no, balance, kyc_status, created_by)
VALUES
  ('Nguyễn Văn An',       'an.nv@gmail.com',        '0901234561', '079201012345', '1990-03-15', '12 Lý Thường Kiệt, Hoàn Kiếm, Hà Nội',           '9704123400010001', 'ACC1001000001',  45000000.00, 'verified', 'teller01'),
  ('Trần Thị Bích',       'bich.tt@gmail.com',       '0912345672', '001285034521', '1985-07-22', '45 Trần Hưng Đạo, Hoàn Kiếm, Hà Nội',            '9704123400010002', 'ACC1001000002', 128500000.00, 'verified', 'teller01'),
  ('Lê Minh Cường',       'cuong.lm@yahoo.com',      '0933456783', '070195056789', '1995-11-08', '78 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',         '9704123400010003', 'ACC1001000003',   8200000.00, 'pending',  'teller01'),
  ('Phạm Thị Dung',       'dung.pt@gmail.com',       '0977567894', '048290078912', '1990-05-30', '23 Lê Lợi, Hải Châu, Đà Nẵng',                   '9704123400010004', 'ACC1001000004', 312000000.00, 'verified', 'teller01'),
  ('Hoàng Văn Em',        'em.hv@gmail.com',         '0868678905', '060185091234', '1985-09-12', '56 Trần Phú, Nha Trang, Khánh Hòa',               '9704123400010005', 'ACC1001000005',  19750000.00, 'verified', 'teller01'),
  ('Vũ Thị Phương',       'phuong.vt@outlook.com',   '0356789016', '031292103456', '1992-01-25', '9 Đinh Tiên Hoàng, Bình Thạnh, TP. Hồ Chí Minh', '9704123400010006', 'ACC1001000006',  67300000.00, 'verified', 'teller01'),
  ('Đặng Văn Giang',      'giang.dv@gmail.com',       '0909890127', '082188115678', '1988-06-03', '34 Phố Huế, Hai Bà Trưng, Hà Nội',               '9704123400010007', 'ACC1001000007', 500000000.00, 'verified', 'teller01'),
  ('Bùi Thị Hoa',         'hoa.bt@gmail.com',         '0798901238', '001296128901', '1996-12-18', '67 Bà Triệu, Hai Bà Trưng, Hà Nội',              '9704123400010008', 'ACC1001000008',   3100000.00, 'rejected', 'teller01'),
  ('Ngô Minh Hùng',       'hung.nm@gmail.com',        '0701012349', '079293141234', '1993-04-07', '11 Võ Thị Sáu, Quận 3, TP. Hồ Chí Minh',        '9704123400010009', 'ACC1001000009',  92400000.00, 'verified', 'teller01'),
  ('Đinh Thị Lan',        'lan.dt@gmail.com',         '0982123450', '048188153456', '1988-08-14', '88 Nguyễn Văn Linh, Hải Châu, Đà Nẵng',          '9704123400010010', 'ACC1001000010',  15600000.00, 'pending',  'teller01'),
  ('Trương Văn Khánh',    'khanh.tv@gmail.com',       '0853234561', '060290165678', '1990-02-28', '22 Lê Duẩn, TP. Buôn Ma Thuột, Đắk Lắk',        '9704123400010011', 'ACC1001000011', 234700000.00, 'verified', 'teller01'),
  ('Phan Thị Linh',       'linh.pt@gmail.com',        '0764345672', '031187178901', '1987-10-05', '5 Nguyễn Đình Chiểu, Quận 3, TP. Hồ Chí Minh',  '9704123400010012', 'ACC1001000012',  47800000.00, 'verified', 'teller01'),
  ('Đỗ Văn Mạnh',         'manh.dv@yahoo.com',        '0635456783', '082294191234', '1994-06-20', '43 Khâm Thiên, Đống Đa, Hà Nội',                 '9704123400010013', 'ACC1001000013',   6500000.00, 'pending',  'teller01'),
  ('Lý Thị Ngọc',         'ngoc.lt@gmail.com',        '0946567894', '079190203456', '1990-11-11', '71 Trần Quốc Toản, Quận 3, TP. Hồ Chí Minh',    '9704123400010014', 'ACC1001000014', 178900000.00, 'verified', 'teller01'),
  ('Mai Văn Phúc',        'phuc.mv@gmail.com',        '0917678905', '048291215678', '1991-03-08', '16 Hùng Vương, Hải Châu, Đà Nẵng',               '9704123400010015', 'ACC1001000015',  31200000.00, 'verified', 'teller01'),
  ('Cao Thị Quỳnh',       'quynh.ct@gmail.com',       '0388789016', '060186228901', '1986-07-17', '55 Đinh Lễ, Hoàn Kiếm, Hà Nội',                  '9704123400010016', 'ACC1001000016',  84600000.00, 'verified', 'teller01'),
  ('Lưu Văn Rạng',        'rang.lv@gmail.com',        '0829890127', '031288241234', '1988-09-24', '28 Lạc Long Quân, Tây Hồ, Hà Nội',               '9704123400010017', 'ACC1001000017',  12300000.00, 'rejected', 'teller01'),
  ('Tống Thị Sen',        'sen.tt@gmail.com',          '0770901238', '082195253456', '1995-01-30', '9 Phan Đình Phùng, Ba Đình, Hà Nội',             '9704123400010018', 'ACC1001000018', 456000000.00, 'verified', 'teller01'),
  ('Hà Văn Thành',        'thanh.hv@gmail.com',       '0901012349', '079292265678', '1992-05-16', '37 Nguyễn Thị Minh Khai, Quận 1, TP. Hồ Chí Minh','9704123400010019','ACC1001000019', 27800000.00, 'verified', 'teller01'),
  ('Dương Thị Uyên',      'uyen.dt@gmail.com',        '0942123450', '048189278901', '1989-12-02', '61 Bạch Đằng, Hải Châu, Đà Nẵng',                '9704123400010020', 'ACC1001000020',  73400000.00, 'verified', 'teller01'),
  ('Nguyễn Thị Vân',      'van.nt@gmail.com',         '0363234561', '060292291234', '1992-08-09', '14 Lý Tự Trọng, Quận 1, TP. Hồ Chí Minh',       '9704123400010021', 'ACC1001000021',   9800000.00, 'pending',  'teller01'),
  ('Trần Văn Xuân',       'xuan.tv@yahoo.com',        '0904345672', '031186303456', '1986-04-21', '82 Hai Bà Trưng, Quận 1, TP. Hồ Chí Minh',      '9704123400010022', 'ACC1001000022', 195600000.00, 'verified', 'teller01'),
  ('Lê Thị Yến',          'yen.lt@gmail.com',         '0935456783', '082293315678', '1993-10-13', '25 Hàng Bài, Hoàn Kiếm, Hà Nội',                 '9704123400010023', 'ACC1001000023',  58200000.00, 'verified', 'teller01'),
  ('Phạm Văn Zũng',       'zung.pv@gmail.com',        '0766567894', '079189328901', '1989-02-07', '48 Ngô Quyền, Hoàn Kiếm, Hà Nội',                '9704123400010024', 'ACC1001000024',  22700000.00, 'pending',  'teller01'),
  ('Hoàng Thị Ánh',       'anh.ht@gmail.com',         '0707678905', '048294341234', '1994-06-25', '33 Lê Thánh Tôn, Quận 1, TP. Hồ Chí Minh',      '9704123400010025', 'ACC1001000025', 341000000.00, 'verified', 'teller01'),
  ('Vũ Văn Bảo',          'bao.vv@gmail.com',         '0878789016', '060187353456', '1987-11-18', '7 Trần Bình Trọng, Quận 5, TP. Hồ Chí Minh',    '9704123400010026', 'ACC1001000026',  16900000.00, 'verified', 'teller01'),
  ('Đặng Thị Châu',       'chau.dt@gmail.com',        '0919890127', '031291365678', '1991-07-04', '52 Kim Mã, Ba Đình, Hà Nội',                      '9704123400010027', 'ACC1001000027',  88500000.00, 'verified', 'teller01'),
  ('Bùi Văn Dần',         'dan.bv@gmail.com',         '0960901238', '082197378901', '1997-03-29', '19 Nguyễn Trãi, Thanh Xuân, Hà Nội',             '9704123400010028', 'ACC1001000028',   4200000.00, 'rejected', 'teller01'),
  ('Ngô Thị Điệp',        'diep.nt@outlook.com',      '0381012349', '079293391234', '1993-09-15', '76 Hoàng Diệu, Hải Châu, Đà Nẵng',               '9704123400010029', 'ACC1001000029', 267300000.00, 'verified', 'teller01'),
  ('Đinh Văn Dương',      'duong.dv@gmail.com',        '0922123450', '048290403456', '1990-01-22', '41 Võ Văn Tần, Quận 3, TP. Hồ Chí Minh',        '9704123400010030', 'ACC1001000030',  39800000.00, 'verified', 'teller01'),
  ('Trương Thị Gia',      'gia.tt@gmail.com',          '0853234562', '060188415678', '1988-05-11', '63 Trần Quý Cáp, Hải Châu, Đà Nẵng',            '9704123400010031', 'ACC1001000031',  11400000.00, 'pending',  'teller01'),
  ('Phan Văn Hào',        'hao.pv@gmail.com',          '0784345673', '031295428901', '1995-12-06', '30 Phạm Ngũ Lão, Quận 1, TP. Hồ Chí Minh',     '9704123400010032', 'ACC1001000032', 523000000.00, 'verified', 'teller01'),
  ('Đỗ Thị Hạnh',         'hanh.dt@gmail.com',         '0645456784', '082192441234', '1992-08-28', '8 Lê Hồng Phong, Ba Đình, Hà Nội',              '9704123400010033', 'ACC1001000033',  72100000.00, 'verified', 'teller01'),
  ('Lý Văn Hiếu',         'hieu.lv@gmail.com',         '0956567895', '079188453456', '1988-04-14', '95 Nguyễn Công Trứ, Quận 1, TP. Hồ Chí Minh',  '9704123400010034', 'ACC1001000034',  28600000.00, 'verified', 'teller01'),
  ('Mai Thị Hương',       'huong.mt@gmail.com',        '0907678906', '048293465678', '1993-10-31', '18 Lý Nam Đế, Hoàn Kiếm, Hà Nội',               '9704123400010035', 'ACC1001000035', 147800000.00, 'verified', 'teller01'),
  ('Cao Văn Khoa',        'khoa.cv@yahoo.com',         '0398789017', '060191478901', '1991-02-08', '44 Tự Do, Hải Châu, Đà Nẵng',                    '9704123400010036', 'ACC1001000036',   5700000.00, 'pending',  'teller01'),
  ('Lưu Thị Lan',         'lan2.lt@gmail.com',         '0839890128', '031289491234', '1989-06-19', '72 Cách Mạng Tháng 8, Quận 3, TP. Hồ Chí Minh', '9704123400010037', 'ACC1001000037', 389200000.00, 'verified', 'teller01'),
  ('Tống Văn Lộc',        'loc.tv@gmail.com',           '0770901239', '082196503456', '1996-11-03', '26 Phan Chu Trinh, Hoàn Kiếm, Hà Nội',          '9704123400010038', 'ACC1001000038',  61500000.00, 'verified', 'teller01'),
  ('Hà Thị Mai',          'mai.ht@gmail.com',           '0901012350', '079291515678', '1991-07-26', '57 Nguyễn Du, Hai Bà Trưng, Hà Nội',            '9704123400010039', 'ACC1001000039',  33900000.00, 'verified', 'teller01'),
  ('Dương Văn Nam',       'nam.dv@gmail.com',           '0942123451', '048188528901', '1988-03-13', '13 Điện Biên Phủ, Bình Thạnh, TP. Hồ Chí Minh','9704123400010040', 'ACC1001000040',   7800000.00, 'rejected', 'teller01'),
  ('Nguyễn Thị Oanh',     'oanh.nt@gmail.com',         '0763234562', '060193541234', '1993-09-01', '85 Trưng Nữ Vương, Hải Châu, Đà Nẵng',           '9704123400010041', 'ACC1001000041', 215400000.00, 'verified', 'teller01'),
  ('Trần Văn Phong',      'phong.tv@gmail.com',        '0904345673', '031290553456', '1990-01-17', '39 Nguyễn Bỉnh Khiêm, Quận 1, TP. Hồ Chí Minh','9704123400010042', 'ACC1001000042',  49300000.00, 'verified', 'teller01'),
  ('Lê Thị Qua',          'qua.lt@gmail.com',           '0835456784', '082197565678', '1997-05-24', '64 Hàng Gai, Hoàn Kiếm, Hà Nội',               '9704123400010043', 'ACC1001000043',  18200000.00, 'pending',  'teller01'),
  ('Phạm Văn Quý',        'quy.pv@gmail.com',           '0766567895', '079189578901', '1989-11-09', '20 Ngô Đức Kế, Quận 1, TP. Hồ Chí Minh',      '9704123400010044', 'ACC1001000044', 478600000.00, 'verified', 'teller01'),
  ('Hoàng Thị Rƣợu',     'ruou.ht@gmail.com',          '0707678906', '048294591234', '1994-07-16', '47 Lê Văn Sỹ, Quận 3, TP. Hồ Chí Minh',        '9704123400010045', 'ACC1001000045',  26700000.00, 'verified', 'teller01'),
  ('Vũ Văn Sơn',          'son.vv@gmail.com',           '0878789017', '060187603456', '1987-02-23', '31 Trần Phú, Ba Đình, Hà Nội',                   '9704123400010046', 'ACC1001000046',  94100000.00, 'verified', 'teller01'),
  ('Đặng Thị Tâm',        'tam.dt@gmail.com',           '0919890128', '031292615678', '1992-08-07', '58 Phan Bội Châu, Hải Châu, Đà Nẵng',           '9704123400010047', 'ACC1001000047',   3600000.00, 'pending',  'teller01'),
  ('Bùi Văn Tuấn',        'tuan.bv@yahoo.com',          '0960901239', '082190628901', '1990-04-18', '16 Tôn Thất Thiệp, Quận 1, TP. Hồ Chí Minh',   '9704123400010048', 'ACC1001000048', 163700000.00, 'verified', 'teller01'),
  ('Ngô Thị Thủy',        'thuy.nt@gmail.com',          '0381012350', '079195641234', '1995-10-05', '73 Lý Thường Kiệt, Hoàn Kiếm, Hà Nội',          '9704123400010049', 'ACC1001000049',  42500000.00, 'verified', 'teller01'),
  ('Đinh Văn Việt',       'viet.dv@gmail.com',           '0922123451', '048291653456', '1991-06-12', '99 Nguyễn Chí Thanh, Đống Đa, Hà Nội',         '9704123400010050', 'ACC1001000050',  11900000.00, 'verified', 'teller01')
ON CONFLICT DO NOTHING;
