-- =========================================================================
-- HPID Bank — analytics target schema (cho BDT Phase 4)
-- DB: hpidbank_analytics
-- =========================================================================

-- ----- Phase 4 (Demo chính): plaintext prod → BDT protect → tokenized analytics -----
-- BDT đọc plaintext từ postgres-prod, tokenize CCCD + Credit Card, ghi vào bảng này.
-- VARCHAR(64) để chứa FPE token (kể cả khi token dài hơn giá trị gốc).
CREATE TABLE IF NOT EXISTS customers_tokenized (
    id              INT PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(120),
    phone           VARCHAR(20),
    cccd            VARCHAR(64),               -- FPE-tokenized by BDT (protect)
    dob             DATE,
    address         VARCHAR(255),
    credit_card_no  VARCHAR(64),               -- FPE-tokenized by BDT (protect)
    account_no      VARCHAR(20),
    balance         NUMERIC(30,2),
    kyc_status      VARCHAR(20),
    extracted_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_tok_kyc  ON customers_tokenized(kyc_status);
CREATE INDEX IF NOT EXISTS idx_customers_tok_dob  ON customers_tokenized(dob);

-- ----- Tham khảo (use case ngược): tokenized prod → BDT reveal → plaintext analytics -----
-- Dùng khi muốn demo chiều detokenize: analytics team cần dữ liệu clear để train model.
CREATE TABLE IF NOT EXISTS customers_clear (
    id              INT PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(120),
    phone           VARCHAR(20),
    cccd            VARCHAR(64),               -- plaintext (revealed) by BDT
    dob             DATE,
    address         VARCHAR(255),
    credit_card_no  VARCHAR(64),               -- plaintext (revealed) by BDT
    account_no      VARCHAR(20),
    balance         NUMERIC(30,2),
    kyc_status      VARCHAR(20),
    extracted_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_clear_dob ON customers_clear(dob);
