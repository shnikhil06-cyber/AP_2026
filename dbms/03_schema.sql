-- ============================================================================
-- Rishi Healthcare & Hospital Management System (HMS)
-- Database Schema DDL (PostgreSQL)
-- Fully normalized to 3NF / BCNF with strict Referential Integrity
-- ============================================================================

-- Enable pgcrypto / uuid generation (built-in in PostgreSQL 13+)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. USER & AUTHENTICATION TABLE
-- ============================================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(30) DEFAULT 'PATIENT',
    name VARCHAR(255),
    phone VARCHAR(30),
    avatar VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. CLINICAL DEPARTMENT TABLE
-- ============================================================================
CREATE TABLE department (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) UNIQUE NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(100) DEFAULT 'Building2',
    head_doctor VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. MEDICAL PRACTITIONER / DOCTOR TABLE
-- ============================================================================
CREATE TABLE doctor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES department(id) ON DELETE RESTRICT,
    specialization VARCHAR(200) NOT NULL,
    qualification VARCHAR(200) NOT NULL,
    experience_years INT DEFAULT 0,
    consultation_fee NUMERIC(10,2) DEFAULT 500.00,
    room_no VARCHAR(50),
    working_hours VARCHAR(100) DEFAULT '09:00 AM - 05:00 PM',
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. PATIENT DEMOGRAPHICS & EMR PROFILE TABLE
-- ============================================================================
CREATE TABLE patient (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    patient_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(30) NOT NULL,
    date_of_birth DATE,
    age INT,
    gender VARCHAR(20) NOT NULL,
    blood_group VARCHAR(10),
    address TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(30),
    allergies TEXT,
    chronic_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 5. OUTPATIENT (OPD) APPOINTMENT TABLE
-- ============================================================================
CREATE TABLE appointment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_number VARCHAR(50) UNIQUE NOT NULL,
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctor(id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES department(id) ON DELETE RESTRICT,
    appointment_date TIMESTAMP NOT NULL,
    time_slot VARCHAR(50) NOT NULL,
    type VARCHAR(50) DEFAULT 'CONSULTATION',
    status VARCHAR(50) DEFAULT 'PENDING',
    reason TEXT NOT NULL,
    symptoms TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 6. MEDICAL CONSULTATION RECORD & CLINICAL VITALS TABLE
-- ============================================================================
CREATE TABLE medical_record (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctor(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointment(id) ON DELETE SET NULL,
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diagnosis TEXT NOT NULL,
    symptoms TEXT,
    vitals_bp VARCHAR(20),
    vitals_pulse VARCHAR(20),
    vitals_temp VARCHAR(20),
    vitals_weight VARCHAR(20),
    doctor_notes TEXT,
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 7. PRESCRIPTION HEADER TABLE
-- ============================================================================
CREATE TABLE prescription (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medical_record_id UUID NOT NULL REFERENCES medical_record(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctor(id) ON DELETE CASCADE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 8. PHARMACEUTICAL DRUG INVENTORY TABLE
-- ============================================================================
CREATE TABLE medicine (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),
    category VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(200),
    dosage_form VARCHAR(50) DEFAULT 'TABLET',
    stock INT DEFAULT 0,
    min_stock_alert INT DEFAULT 10,
    unit_price NUMERIC(10,2) NOT NULL,
    expiry_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 9. PRESCRIPTION LINE ITEMS (NORMALIZED TO 3NF / BCNF)
-- ============================================================================
CREATE TABLE prescription_item (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescription(id) ON DELETE CASCADE,
    medicine_id UUID REFERENCES medicine(id) ON DELETE SET NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration_days INT NOT NULL,
    instructions TEXT
);

-- ============================================================================
-- 10. HOSPITAL INPATIENT WARD / ROOM TABLE
-- ============================================================================
CREATE TABLE room (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_number VARCHAR(50) UNIQUE NOT NULL,
    floor INT DEFAULT 1,
    room_type VARCHAR(50) DEFAULT 'GENERAL',
    daily_rate NUMERIC(10,2) NOT NULL,
    total_beds INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 11. INPATIENT BED ALLOCATION TABLE
-- ============================================================================
CREATE TABLE bed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bed_number VARCHAR(50) UNIQUE NOT NULL,
    room_id UUID NOT NULL REFERENCES room(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 12. INPATIENT ADMISSION & OCCUPANCY TABLE
-- ============================================================================
CREATE TABLE admission (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admission_code VARCHAR(50) UNIQUE NOT NULL,
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    bed_id UUID NOT NULL REFERENCES bed(id) ON DELETE RESTRICT,
    attending_doctor_id UUID NOT NULL REFERENCES doctor(id) ON DELETE RESTRICT,
    admission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    discharge_date TIMESTAMP,
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'ADMITTED',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 13. BILLING & TAX INVOICE HEADER TABLE
-- ============================================================================
CREATE TABLE bill (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointment(id) ON DELETE SET NULL,
    admission_id UUID REFERENCES admission(id) ON DELETE SET NULL,
    issue_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP,
    subtotal NUMERIC(10,2) DEFAULT 0.00,
    tax_rate NUMERIC(5,2) DEFAULT 5.00,
    tax_amount NUMERIC(10,2) DEFAULT 0.00,
    discount NUMERIC(10,2) DEFAULT 0.00,
    total_amount NUMERIC(10,2) DEFAULT 0.00,
    paid_amount NUMERIC(10,2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'UNPAID',
    payment_method VARCHAR(50) DEFAULT 'CASH',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 14. ITEMIZED INVOICE LINE ITEMS TABLE
-- ============================================================================
CREATE TABLE bill_item (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES bill(id) ON DELETE CASCADE,
    description VARCHAR(255) NOT NULL,
    category VARCHAR(50) DEFAULT 'OTHER',
    quantity INT DEFAULT 1,
    unit_price NUMERIC(10,2) NOT NULL,
    total_price NUMERIC(10,2) NOT NULL
);

-- ============================================================================
-- 15. DIAGNOSTIC LAB TEST CATALOG TABLE
-- ============================================================================
CREATE TABLE lab_test (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_code VARCHAR(50) UNIQUE NOT NULL,
    test_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    sample_type VARCHAR(100) DEFAULT 'Blood',
    cost NUMERIC(10,2) NOT NULL,
    turnaround_hours INT DEFAULT 24,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 16. PATIENT DIAGNOSTIC LAB REPORT TABLE
-- ============================================================================
CREATE TABLE lab_report (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_code VARCHAR(50) UNIQUE NOT NULL,
    lab_test_id UUID NOT NULL REFERENCES lab_test(id) ON DELETE RESTRICT,
    patient_id UUID NOT NULL REFERENCES patient(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctor(id) ON DELETE RESTRICT,
    test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    result_summary TEXT,
    findings TEXT,
    normal_range VARCHAR(100),
    status VARCHAR(50) DEFAULT 'REQUESTED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
