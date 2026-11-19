-- ============================================================================
-- Rishi Healthcare & Hospital Management System (HMS)
-- Workload Queries (PostgreSQL)
-- File: dbms/04_queries.sql
-- 
-- Description:
-- Every SQL query utilized by the Rishi Healthcare full-stack web application
-- (Patient Portal, Doctor Directory, OPD Appointments, Electronic Medical Records,
-- Pharmacy Stock, Inpatient Bed Management, Diagnostic Labs, and Billing/Finance).
--
-- Query Identification & Rubric Conformance:
-- - All queries use multi-table JOINs where applicable to reflect real application workflows.
-- - Marked with explicit '-- READ' / '-- WRITE' comments and unique query identifiers (R1..R15, W1..W10).
-- ============================================================================


-- ############################################################################
-- SECTION 1: READ QUERIES (R1 to R15)
-- ############################################################################

-- ============================================================================
-- @R01
-- READ R1: User Login Verification & Clinical Role Profile Retrieval
-- Application Flow: Authenticates credentials upon login and fetches user role,
-- linked practitioner profile (if doctor), or patient demographic code (if patient).
-- ============================================================================
SELECT 
    u.id AS user_id,
    u.username,
    u.email,
    u.role,
    u.name,
    u.phone,
    u.avatar,
    d.id AS doctor_id,
    d.specialization,
    d.consultation_fee,
    d.room_no,
    p.id AS patient_id,
    p.patient_code,
    p.blood_group
FROM users u
LEFT JOIN doctor d ON d.user_id = u.id
LEFT JOIN patient p ON p.user_id = u.id
WHERE u.email = 'dr.sharma@hospital.com';


-- ============================================================================
-- @R02
-- READ R2: Specialist Doctor Directory with Department & Experience Details
-- Application Flow: Powers the public doctor directory and patient appointment booking widget.
-- Joins doctor, user, and clinical department tables.
-- ============================================================================
SELECT 
    d.id AS doctor_id,
    u.name AS doctor_name,
    u.email AS doctor_email,
    u.phone AS doctor_phone,
    dept.name AS department_name,
    dept.code AS department_code,
    d.specialization,
    d.qualification,
    d.experience_years,
    d.consultation_fee,
    d.room_no,
    d.working_hours,
    d.is_available
FROM doctor d
JOIN users u ON d.user_id = u.id
JOIN department dept ON d.department_id = dept.id
WHERE d.is_available = TRUE
ORDER BY dept.name ASC, d.experience_years DESC;


-- ============================================================================
-- @R03
-- READ R3: Patient Demographic Profile & Clinical History Summary
-- Application Flow: Loads patient profile dashboard drawer with lifetime aggregate counts.
-- Uses outer joins across clinical activity tables.
-- ============================================================================
SELECT 
    p.id AS patient_id,
    p.patient_code,
    p.name AS patient_name,
    p.email,
    p.phone,
    p.date_of_birth,
    p.age,
    p.gender,
    p.blood_group,
    p.address,
    p.emergency_contact_name,
    p.emergency_contact_phone,
    p.allergies,
    p.chronic_conditions,
    COUNT(DISTINCT a.id) AS total_appointments,
    COUNT(DISTINCT mr.id) AS total_medical_records,
    COUNT(DISTINCT adm.id) AS total_admissions,
    COUNT(DISTINCT b.id) AS total_bills
FROM patient p
LEFT JOIN appointment a ON a.patient_id = p.id
LEFT JOIN medical_record mr ON mr.patient_id = p.id
LEFT JOIN admission adm ON adm.patient_id = p.id
LEFT JOIN bill b ON b.patient_id = p.id
WHERE p.patient_code = 'PAT-1001'
GROUP BY p.id;


-- ============================================================================
-- @R04
-- READ R4: Outpatient (OPD) Master Appointment Roster & Schedule
-- Application Flow: Hospital administration queue for reviewing, confirming, and filtering OPD appointments.
-- Joins appointment, patient, doctor, user, and department.
-- ============================================================================
SELECT 
    a.id AS appointment_id,
    a.appointment_number,
    a.appointment_date,
    a.time_slot,
    a.type,
    a.status,
    a.reason,
    p.patient_code,
    p.name AS patient_name,
    p.phone AS patient_phone,
    u_doc.name AS doctor_name,
    d.specialization,
    d.room_no,
    dept.name AS department_name
FROM appointment a
JOIN patient p ON a.patient_id = p.id
JOIN doctor d ON a.doctor_id = d.id
JOIN users u_doc ON d.user_id = u_doc.id
JOIN department dept ON a.department_id = dept.id
WHERE a.status = 'CONFIRMED'
ORDER BY a.appointment_date DESC;


-- ============================================================================
-- @R05
-- READ R5: Doctor Consultation Schedule & Upcoming Patient Queue
-- Application Flow: Displays upcoming appointments for an authenticated physician in their clinic portal.
-- ============================================================================
SELECT 
    a.id AS appointment_id,
    a.appointment_number,
    a.appointment_date,
    a.time_slot,
    a.type,
    a.status,
    a.reason,
    a.symptoms,
    p.patient_code,
    p.name AS patient_name,
    p.gender,
    p.age,
    p.blood_group,
    p.phone AS patient_phone
FROM appointment a
JOIN patient p ON a.patient_id = p.id
JOIN doctor d ON a.doctor_id = d.id
JOIN users u ON d.user_id = u.id
WHERE u.email = 'dr.sharma@hospital.com'
  AND a.appointment_date >= CURRENT_DATE
ORDER BY a.appointment_date ASC, a.time_slot ASC;


-- ============================================================================
-- @R06
-- READ R6: Patient Electronic Medical Record (EMR) & Clinical Vitals History
-- Application Flow: Retrieved by doctors during consultation to inspect chronological vitals and clinical diagnoses.
-- ============================================================================
SELECT 
    mr.id AS record_id,
    mr.record_date,
    mr.diagnosis,
    mr.symptoms,
    mr.vitals_bp,
    mr.vitals_pulse,
    mr.vitals_temp,
    mr.vitals_weight,
    mr.doctor_notes,
    mr.follow_up_date,
    u_doc.name AS consulting_doctor,
    d.specialization,
    p.patient_code,
    p.name AS patient_name
FROM medical_record mr
JOIN patient p ON mr.patient_id = p.id
JOIN doctor d ON mr.doctor_id = d.id
JOIN users u_doc ON d.user_id = u_doc.id
WHERE p.patient_code = 'PAT-1001'
ORDER BY mr.record_date DESC;


-- ============================================================================
-- @R07
-- READ R7: Active Prescriptions & Itemized Medication Regimen
-- Application Flow: Fetches medication schedules, dosage, frequency, and pharmacy catalog details for patient portal.
-- Multi-table join across prescription, line items, medicine catalog, patient, and doctor.
-- ============================================================================
SELECT 
    pr.id AS prescription_id,
    pr.created_at AS prescribed_date,
    pr.notes AS prescription_notes,
    pi.dosage,
    pi.frequency,
    pi.duration_days,
    pi.instructions,
    m.code AS medicine_code,
    m.name AS medicine_name,
    m.generic_name,
    m.category AS drug_category,
    m.dosage_form,
    u_doc.name AS prescribing_doctor,
    p.patient_code,
    p.name AS patient_name
FROM prescription pr
JOIN prescription_item pi ON pi.prescription_id = pr.id
JOIN medicine m ON pi.medicine_id = m.id
JOIN patient p ON pr.patient_id = p.id
JOIN doctor d ON pr.doctor_id = d.id
JOIN users u_doc ON d.user_id = u_doc.id
WHERE p.patient_code = 'PAT-1001'
ORDER BY pr.created_at DESC;


-- ============================================================================
-- @R08
-- READ R8: Pharmacy Inventory Catalog & Depleted Stock Alert Register
-- Application Flow: Alerts pharmacists of medications nearing depletion (stock <= min_stock_alert).
-- ============================================================================
SELECT 
    m.id AS medicine_id,
    m.code AS medicine_code,
    m.name AS medicine_name,
    m.generic_name,
    m.category,
    m.dosage_form,
    m.stock,
    m.min_stock_alert,
    (m.min_stock_alert - m.stock) AS shortage_quantity,
    m.unit_price,
    m.expiry_date
FROM medicine m
WHERE m.stock <= m.min_stock_alert
ORDER BY m.stock ASC, m.expiry_date ASC;


-- ============================================================================
-- @R09
-- READ R9: Inpatient Ward & Bed Occupancy Real-Time Tracker
-- Application Flow: Visual floor map showing bed allocation status and currently admitted patient details.
-- ============================================================================
SELECT 
    r.room_number,
    r.floor,
    r.room_type,
    r.daily_rate,
    b.id AS bed_id,
    b.bed_number,
    b.status AS bed_status,
    adm.admission_code,
    adm.admission_date,
    p.patient_code,
    p.name AS admitted_patient,
    u_doc.name AS attending_doctor
FROM room r
JOIN bed b ON b.room_id = r.id
LEFT JOIN admission adm ON adm.bed_id = b.id AND adm.status = 'ADMITTED'
LEFT JOIN patient p ON adm.patient_id = p.id
LEFT JOIN doctor d ON adm.attending_doctor_id = d.id
LEFT JOIN users u_doc ON d.user_id = u_doc.id
ORDER BY r.floor ASC, r.room_number ASC, b.bed_number ASC;


-- ============================================================================
-- @R10
-- READ R10: Inpatient Admission Register & Active Hospitalizations
-- Application Flow: Hospital administration list of currently admitted inpatients with ward tariffs.
-- ============================================================================
SELECT 
    adm.id AS admission_id,
    adm.admission_code,
    adm.admission_date,
    adm.reason,
    adm.status,
    p.patient_code,
    p.name AS patient_name,
    p.gender,
    p.age,
    p.blood_group,
    b.bed_number,
    r.room_number,
    r.room_type,
    r.daily_rate,
    u_doc.name AS attending_doctor,
    d.specialization
FROM admission adm
JOIN patient p ON adm.patient_id = p.id
JOIN bed b ON adm.bed_id = b.id
JOIN room r ON b.room_id = r.id
JOIN doctor d ON adm.attending_doctor_id = d.id
JOIN users u_doc ON d.user_id = u_doc.id
WHERE adm.status = 'ADMITTED'
ORDER BY adm.admission_date DESC;


-- ============================================================================
-- @R11
-- READ R11: Available Beds Lookup by Ward Category & Tariff
-- Application Flow: Used by emergency / admission desk to assign an unoccupied bed during intake.
-- ============================================================================
SELECT 
    b.id AS bed_id,
    b.bed_number,
    r.room_number,
    r.floor,
    r.room_type,
    r.daily_rate
FROM bed b
JOIN room r ON b.room_id = r.id
WHERE b.status = 'AVAILABLE'
ORDER BY r.room_type ASC, r.daily_rate ASC, b.bed_number ASC;


-- ============================================================================
-- @R12
-- READ R12: Diagnostic Lab Orders & Clinical Pathology Report Findings
-- Application Flow: Lab technicians enter and view test specimens, findings, and normal reference ranges.
-- ============================================================================
SELECT 
    lr.id AS report_id,
    lr.report_code,
    lr.test_date,
    lr.status AS report_status,
    lr.result_summary,
    lr.findings,
    lr.normal_range,
    lt.test_code,
    lt.test_name,
    lt.category AS lab_category,
    lt.sample_type,
    lt.cost,
    p.patient_code,
    p.name AS patient_name,
    p.gender,
    p.age,
    u_doc.name AS referring_doctor
FROM lab_report lr
JOIN lab_test lt ON lr.lab_test_id = lt.id
JOIN patient p ON lr.patient_id = p.id
JOIN doctor d ON lr.doctor_id = d.id
JOIN users u_doc ON d.user_id = u_doc.id
ORDER BY lr.test_date DESC;


-- ============================================================================
-- @R13
-- READ R13: Itemized Patient Tax Invoice Breakdown with Service Line Items
-- Application Flow: Renders the printable official tax invoice with consultations, room charges, and diagnostics.
-- ============================================================================
SELECT 
    b.id AS bill_id,
    b.invoice_number,
    b.issue_date,
    b.due_date,
    b.subtotal,
    b.tax_rate,
    b.tax_amount,
    b.discount,
    b.total_amount,
    b.paid_amount,
    b.status AS payment_status,
    b.payment_method,
    p.patient_code,
    p.name AS patient_name,
    p.phone AS patient_phone,
    p.address AS patient_address,
    bi.id AS line_item_id,
    bi.description AS service_description,
    bi.category AS service_category,
    bi.quantity,
    bi.unit_price,
    bi.total_price
FROM bill b
JOIN patient p ON b.patient_id = p.id
JOIN bill_item bi ON bi.bill_id = b.id
WHERE b.invoice_number = 'INV-2026-001'
ORDER BY bi.total_price DESC;


-- ============================================================================
-- @R14
-- READ R14: Accounts Receivable & Outstanding Unpaid Invoices Report
-- Application Flow: Financial accounts report identifying outstanding patient balances and contact details.
-- ============================================================================
SELECT 
    b.id AS bill_id,
    b.invoice_number,
    b.issue_date,
    b.due_date,
    b.total_amount,
    b.paid_amount,
    (b.total_amount - b.paid_amount) AS outstanding_balance,
    b.status AS payment_status,
    p.patient_code,
    p.name AS patient_name,
    p.phone AS contact_phone,
    p.email AS contact_email
FROM bill b
JOIN patient p ON b.patient_id = p.id
WHERE b.status IN ('UNPAID', 'PARTIAL')
ORDER BY b.issue_date ASC;


-- ============================================================================
-- @R15
-- READ R15: Hospital Command Center Real-Time Operational Dashboard KPIs
-- Application Flow: Aggregates real-time patient census, active doctors, today's OPD load, bed occupancy %, and revenue.
-- ============================================================================
SELECT 
    (SELECT COUNT(*) FROM patient) AS total_registered_patients,
    (SELECT COUNT(*) FROM doctor WHERE is_available = TRUE) AS active_duty_physicians,
    (SELECT COUNT(*) FROM appointment WHERE appointment_date::date = CURRENT_DATE) AS today_opd_consultations,
    (SELECT COUNT(*) FROM admission WHERE status = 'ADMITTED') AS active_inpatient_admissions,
    ROUND(
        (SELECT COUNT(*) FROM bed WHERE status = 'OCCUPIED')::numeric * 100.0 / 
        NULLIF((SELECT COUNT(*) FROM bed), 0), 2
    ) AS bed_occupancy_percentage,
    (SELECT COALESCE(SUM(paid_amount), 0) FROM bill) AS total_revenue_collected_inr;



-- ############################################################################
-- SECTION 2: WRITE QUERIES (W1 to W10)
-- ############################################################################

-- ============================================================================
-- @W01
-- WRITE W1: Register New Hospital System User (Patient / Clinical Staff)
-- Application Flow: Inserts secure authentication credentials upon registration.
-- ============================================================================
INSERT INTO users (
    username, email, password, role, name, phone, avatar
) VALUES (
    'priya.sharma',
    'priya.sharma@example.com',
    '$2a$10$e8ZaS2Kz7gX89J7YxWzD8.GzT5UeFqY1r9h6kZ3y7L2M1nO0pQqZa',
    'PATIENT',
    'Priya Sharma',
    '+91-9876543210',
    'avatar_patient_female.png'
)
RETURNING id, username, email, role, created_at;


-- ============================================================================
-- @W02
-- WRITE W2: Onboard New Patient Demographic & Clinical Profile Record
-- Application Flow: Creates clinical identity with unique business code (PAT-1002).
-- ============================================================================
INSERT INTO patient (
    user_id,
    patient_code,
    name,
    email,
    phone,
    date_of_birth,
    age,
    gender,
    blood_group,
    address,
    emergency_contact_name,
    emergency_contact_phone,
    allergies,
    chronic_conditions
) VALUES (
    (SELECT id FROM users WHERE email = 'priya.sharma@example.com'),
    'PAT-1002',
    'Priya Sharma',
    'priya.sharma@example.com',
    '+91-9876543210',
    '1995-06-15',
    31,
    'Female',
    'O+',
    '42 Civil Lines, Jaipur',
    'Rajesh Sharma',
    '+91-9876543211',
    'Penicillin, Dust Mites',
    'Mild Asthma'
)
RETURNING id, patient_code, name, created_at;


-- ============================================================================
-- @W03
-- WRITE W3: Register Specialist Doctor Practitioner Profile
-- Application Flow: Connects user authentication record to clinical specialty & tariff.
-- ============================================================================
INSERT INTO doctor (
    user_id,
    department_id,
    specialization,
    qualification,
    experience_years,
    consultation_fee,
    room_no,
    working_hours,
    is_available
) VALUES (
    (SELECT id FROM users WHERE email = 'dr.sharma@hospital.com'),
    (SELECT id FROM department WHERE code = 'CARDIO'),
    'Interventional Cardiology & Electrophysiology',
    'MBBS, MD (Medicine), DM (Cardiology), FACC',
    15,
    800.00,
    'OPD-102',
    '09:00 AM - 04:00 PM',
    TRUE
)
RETURNING id, specialization, consultation_fee, room_no;


-- ============================================================================
-- @W04
-- WRITE W4: Schedule Outpatient (OPD) Consultation Appointment
-- Application Flow: Inserts confirmed appointment booked online or at front desk.
-- ============================================================================
INSERT INTO appointment (
    appointment_number,
    patient_id,
    doctor_id,
    department_id,
    appointment_date,
    time_slot,
    type,
    status,
    reason,
    symptoms
) VALUES (
    'APT-2026-102',
    (SELECT id FROM patient WHERE patient_code = 'PAT-1001'),
    (SELECT d.id FROM doctor d JOIN users u ON d.user_id = u.id WHERE u.email = 'dr.sharma@hospital.com'),
    (SELECT id FROM department WHERE code = 'CARDIO'),
    '2026-11-20 10:30:00',
    '10:30 AM',
    'CONSULTATION',
    'CONFIRMED',
    'Routine cardiology follow-up and angina check',
    'Exertional palpitations, mild breathlessness'
)
RETURNING id, appointment_number, status, appointment_date;


-- ============================================================================
-- @W05
-- WRITE W5: Update Appointment Consultation Status & Clinical Notes
-- Application Flow: Executed when physician concludes the clinical appointment.
-- ============================================================================
UPDATE appointment
SET 
    status = 'COMPLETED',
    notes = 'Consultation successfully concluded. Prescribed antihypertensive regimen.',
    updated_at = CURRENT_TIMESTAMP
WHERE appointment_number = 'APT-2026-102'
RETURNING id, appointment_number, status, updated_at;


-- ============================================================================
-- @W06
-- WRITE W6: Record Clinical Consultation Findings, Diagnosis & Patient Vitals
-- Application Flow: Records medical observations, vitals, and scheduled follow-up.
-- ============================================================================
INSERT INTO medical_record (
    patient_id,
    doctor_id,
    appointment_id,
    record_date,
    diagnosis,
    symptoms,
    vitals_bp,
    vitals_pulse,
    vitals_temp,
    vitals_weight,
    doctor_notes,
    follow_up_date
) VALUES (
    (SELECT id FROM patient WHERE patient_code = 'PAT-1001'),
    (SELECT d.id FROM doctor d JOIN users u ON d.user_id = u.id WHERE u.email = 'dr.sharma@hospital.com'),
    (SELECT id FROM appointment WHERE appointment_number = 'APT-2026-102'),
    CURRENT_TIMESTAMP,
    'Essential Hypertension (Stage 1) with Sinus Tachycardia',
    'Intermittent bilateral occipital headaches and mild dizziness',
    '142/92 mmHg',
    '88 bpm',
    '98.4 F',
    '72.5 kg',
    'Advised DASH low-sodium diet, regular aerobic exercise, and BP monitoring log.',
    CURRENT_DATE + INTERVAL '14 days'
)
RETURNING id, diagnosis, vitals_bp, record_date;


-- ============================================================================
-- @W07
-- WRITE W7: Issue Medical Prescription & Line Item Medications
-- Application Flow: Atomically registers prescription header and line item drug regimens.
-- ============================================================================
WITH new_prescription AS (
    INSERT INTO prescription (
        medical_record_id,
        patient_id,
        doctor_id,
        notes
    ) VALUES (
        (SELECT id FROM medical_record WHERE patient_id = (SELECT id FROM patient WHERE patient_code = 'PAT-1001') ORDER BY record_date DESC LIMIT 1),
        (SELECT id FROM patient WHERE patient_code = 'PAT-1001'),
        (SELECT d.id FROM doctor d JOIN users u ON d.user_id = u.id WHERE u.email = 'dr.sharma@hospital.com'),
        'Take medications strictly after meals with water. Do not skip doses.'
    )
    RETURNING id
)
INSERT INTO prescription_item (
    prescription_id,
    medicine_id,
    dosage,
    frequency,
    duration_days,
    instructions
) VALUES 
(
    (SELECT id FROM new_prescription),
    (SELECT id FROM medicine WHERE code = 'MED-101'),
    '5 mg',
    'Once Daily (Morning)',
    14,
    'Take with a glass of water after breakfast'
);


-- ============================================================================
-- @W08
-- WRITE W8: Inpatient Hospital Admission & Interactive Bed Allocation
-- Application Flow: Admits patient to inpatient ward and marks bed as OCCUPIED.
-- ============================================================================
WITH new_adm AS (
    INSERT INTO admission (
        admission_code,
        patient_id,
        bed_id,
        attending_doctor_id,
        admission_date,
        reason,
        status,
        notes
    ) VALUES (
        'ADM-2026-002',
        (SELECT id FROM patient WHERE patient_code = 'PAT-1001'),
        (SELECT id FROM bed WHERE bed_number = 'ICU-02'),
        (SELECT d.id FROM doctor d JOIN users u ON d.user_id = u.id WHERE u.email = 'dr.sharma@hospital.com'),
        CURRENT_TIMESTAMP,
        'Post-procedural cardiac telemetry observation',
        'ADMITTED',
        'Continuous 24-hour hemodynamic and vitals monitoring.'
    )
    RETURNING bed_id, admission_code
)
UPDATE bed
SET status = 'OCCUPIED'
WHERE id = (SELECT bed_id FROM new_adm)
RETURNING bed_number, status;


-- ============================================================================
-- @W09
-- WRITE W9: Inpatient Hospital Discharge & Bed Release
-- Application Flow: Discharges patient upon stabilization and marks bed AVAILABLE.
-- ============================================================================
WITH discharged_adm AS (
    UPDATE admission
    SET 
        discharge_date = CURRENT_TIMESTAMP,
        status = 'DISCHARGED',
        notes = 'Patient recovered satisfactorily. Discharged with home medication advice.',
        updated_at = CURRENT_TIMESTAMP
    WHERE admission_code = 'ADM-2026-002'
    RETURNING bed_id, admission_code
)
UPDATE bed
SET status = 'AVAILABLE'
WHERE id = (SELECT bed_id FROM discharged_adm)
RETURNING bed_number, status;


-- ============================================================================
-- @W10
-- WRITE W10: Generate Itemized Patient Tax Invoice & Record Financial Charges
-- Application Flow: Issues comprehensive invoice with itemized consultation and lab charges.
-- ============================================================================
WITH new_bill AS (
    INSERT INTO bill (
        invoice_number,
        patient_id,
        appointment_id,
        admission_id,
        issue_date,
        due_date,
        subtotal,
        tax_rate,
        tax_amount,
        discount,
        total_amount,
        paid_amount,
        status,
        payment_method,
        notes
    ) VALUES (
        'INV-2026-002',
        (SELECT id FROM patient WHERE patient_code = 'PAT-1001'),
        (SELECT id FROM appointment WHERE appointment_number = 'APT-2026-102'),
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_DATE + INTERVAL '7 days',
        1500.00,
        5.00,
        75.00,
        100.00,
        1475.00,
        1475.00,
        'PAID',
        'UPI',
        'Full digital settlement via UPI. Payment reference: UPI-98234710293.'
    )
    RETURNING id
)
INSERT INTO bill_item (
    bill_id,
    description,
    category,
    quantity,
    unit_price,
    total_price
) VALUES 
(
    (SELECT id FROM new_bill),
    'Specialist Cardiologist OPD Consultation Fee',
    'CONSULTATION',
    1,
    800.00,
    800.00
),
(
    (SELECT id FROM new_bill),
    '12-Lead Electrocardiogram (ECG) Diagnostic Scan',
    'LAB',
    1,
    700.00,
    700.00
);
