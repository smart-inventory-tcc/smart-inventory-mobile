# Mermaid Diagrams Smart Inventory UMKM

Dokumen ini berisi kumpulan diagram utama untuk laporan akhir: arsitektur, ERD/RAT, use case, flow proses, sequence, dan deployment.

## 1. System Context dan Integrasi Layanan

```mermaid
flowchart LR
    Owner[Owner Web App] --> FE[Frontend Web]
    Staff[Pegawai Mobile App] --> MOB[Mobile App]

    FE --> A[Service A\nIdentity and Supplier]
    FE --> B[Service B\nInventory and Storage]
    FE --> C[Service C\nIntelligence and Notifications]

    MOB --> A
    MOB --> B
    MOB --> C

    A --> SQL[(Cloud SQL)]
    B --> SQL
    C --> SQL

    B --> FS[(Firestore)]
    C --> FS

    B --> GCS[(Google Cloud Storage)]
```

## 2. ERD SQL (5 Tabel Utama)

```mermaid
erDiagram
    USERS {
        bigint id PK
        string username
        string password_hash
        string role
        datetime created_at
    }

    SUPPLIERS {
        bigint id PK
        string name
        string phone
        string address
        string email
        datetime created_at
    }

    CATEGORIES {
        bigint id PK
        string category_name
        string description
        datetime created_at
    }

    ITEMS {
        bigint id PK
        string barcode UK
        string name
        decimal price
        int stock
        int min_stock
        bigint category_id FK
        bigint supplier_id FK
        string image_url
        datetime created_at
        datetime updated_at
    }

    STOCK_TRANSACTIONS {
        bigint id PK
        bigint item_id FK
        bigint user_id FK
        string type
        int quantity
        datetime created_at
    }

    CATEGORIES ||--o{ ITEMS : classifies
    SUPPLIERS ||--o{ ITEMS : supplies
    USERS ||--o{ STOCK_TRANSACTIONS : performs
    ITEMS ||--o{ STOCK_TRANSACTIONS : records
```

## 3. RAT (Requirement Traceability Diagram)

```mermaid
flowchart TD
    R1[RQ1: REST CRUD + 3 Service + Cloud Run]
    R2[RQ2: Database di Cloud SQL atau GCE]
    R3[RQ3: Tech Stack Bebas]
    R4[RQ4: Minimal 15 Endpoint]
    R5[RQ5: Minimal 5 Tabel pada Kedua Database]
    R6[RQ6: Laporan Akhir Sesuai Template]

    A1[Artifact: 3 Microservices\nIdentity, Inventory, Intelligence]
    A2[Artifact: Cloud Run Deployment]
    A3[Artifact: Cloud SQL Schema]
    A4[Artifact: Endpoint Catalog 18 API]
    A5[Artifact: SQL 5 Tabel + Firestore 5 Collection]
    A6[Artifact: Final Report Package]

    R1 --> A1
    R1 --> A2
    R2 --> A3
    R3 --> A1
    R4 --> A4
    R5 --> A5
    R6 --> A6

    A1 --> E1[Evidence: Swagger per Service]
    A2 --> E2[Evidence: URL Cloud Run]
    A3 --> E3[Evidence: Migration Script dan ERD]
    A4 --> E4[Evidence: OpenAPI Docs]
    A5 --> E5[Evidence: Firestore Collections Snapshot]
    A6 --> E6[Evidence: Dokumen Laporan Final]
```

## 4. Use Case Diagram (Owner dan Staff)

```mermaid
flowchart LR
    Owner((Owner))
    Staff((Staff))

    UC1([Login])
    UC2([Kelola Supplier])
    UC3([Kelola Barang])
    UC4([Lihat Dashboard Analitik])
    UC5([Lihat Notifikasi Low Stock])
    UC6([Scan Barang Masuk])
    UC7([Scan Barang Keluar])
    UC8([Lihat Histori Transaksi])

    Owner --> UC1
    Owner --> UC2
    Owner --> UC3
    Owner --> UC4
    Owner --> UC5
    Owner --> UC8

    Staff --> UC1
    Staff --> UC6
    Staff --> UC7
    Staff --> UC8
```

## 5. Flow Diagram Proses Transaksi Keluar dan Alert

```mermaid
flowchart TD
    S0[Start: Staff scan barcode keluar] --> S1[Validasi JWT]
    S1 -->|Invalid| E1[Return 401]
    S1 -->|Valid| S2[Ambil item dari SQL]
    S2 -->|Tidak ditemukan| E2[Return 404]
    S2 -->|Ditemukan| S3{Stok cukup?}
    S3 -->|Tidak| E3[Return 400 stok tidak cukup]
    S3 -->|Ya| S4[Kurangi stok dalam SQL transaction]
    S4 --> S5[Insert stock_transactions type OUT]
    S5 --> S6{stok_akhir <= min_stock?}
    S6 -->|Ya| S7[Tulis Firestore notifications]
    S7 --> S8[Tulis Firestore stock_alerts_history]
    S8 --> S9[Return 200 sukses]
    S6 -->|Tidak| S9
```

## 6. Sequence Diagram Low Stock Alert

```mermaid
sequenceDiagram
    actor Staff
    participant Mobile as Mobile App
    participant Inv as Inventory Service
    participant SQL as Cloud SQL
    participant FS as Firestore
    participant Intel as Intelligence Service

    Staff->>Mobile: Scan barcode dan submit transaksi keluar
    Mobile->>Inv: POST /transactions/out
    Inv->>SQL: SELECT item by barcode
    SQL-->>Inv: item + stock + min_stock
    Inv->>SQL: UPDATE items set stock = stock - qty
    Inv->>SQL: INSERT stock_transactions(OUT)

    alt stok_akhir <= min_stock
        Inv->>FS: create notifications doc
        Inv->>FS: create stock_alerts_history doc
    end

    Inv-->>Mobile: 200 OK + stok_akhir
    Intel->>FS: read notifications/alerts
    Intel-->>Mobile: data alert untuk dashboard/feed
```

## 7. Deployment Diagram (Cloud Run)

```mermaid
flowchart TB
    subgraph GCP[Google Cloud Platform]
        subgraph CR[Cloud Run Services]
            A[identity-supplier-service]
            B[inventory-storage-service]
            C[intelligence-analytics-service]
        end

        SQL[(Cloud SQL)]
        FS[(Firestore)]
        GCS[(Cloud Storage Bucket\nsmart-inventory-assets)]
        SM[Secret Manager]
    end

    A --> SQL
    B --> SQL
    C --> SQL

    B --> FS
    C --> FS

    B --> GCS

    A -. env secrets .-> SM
    B -. env secrets .-> SM
    C -. env secrets .-> SM
```

## 8. Diagram Struktur NoSQL (Collection Model)

```mermaid
classDiagram
    class notifications {
        +string id
        +string item_id
        +string message
        +boolean is_read
        +string level
        +timestamp timestamp
    }

    class user_activity_logs {
        +string id
        +string user_id
        +string action
        +string device_info
        +timestamp timestamp
    }

    class stock_alerts_history {
        +string id
        +string item_id
        +string item_name
        +number threshold_hit
        +timestamp timestamp
    }

    class temp_scan_sessions {
        +string session_id
        +string user_id
        +array items_list
        +timestamp last_updated
    }

    class system_config {
        +string config_key
        +string config_value
        +timestamp updated_at
    }
```

## 9. Catatan Pemakaian di Laporan

- Gunakan ERD SQL pada bagian desain basis data relasional.
- Gunakan RAT untuk menunjukkan keterlacakan requirement ke artefak implementasi.
- Gunakan flow dan sequence diagram pada bagian logika stok menipis.
- Gunakan deployment diagram pada bagian arsitektur cloud.
