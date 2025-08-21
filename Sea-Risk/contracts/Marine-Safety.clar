;; Maritime Risk Management Smart Contract
;; A comprehensive system for managing maritime risks, vessel registration,
;; insurance claims, and compliance monitoring

;; CONSTANTS AND ERROR CODES

;; Contract owner and admin addresses
(define-constant contract-owner tx-sender)
(define-constant admin-role u1)
(define-constant inspector-role u2)
(define-constant vessel-owner-role u3)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-VESSEL-NOT-FOUND (err u101))
(define-constant ERR-VESSEL-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-RISK-SCORE (err u103))
(define-constant ERR-CLAIM-NOT-FOUND (err u104))
(define-constant ERR-CLAIM-ALREADY-PROCESSED (err u105))
(define-constant ERR-INSUFFICIENT-PREMIUM (err u106))
(define-constant ERR-VESSEL-NOT-INSURED (err u107))
(define-constant ERR-INVALID-INSPECTION-DATE (err u108))
(define-constant ERR-COMPLIANCE-EXPIRED (err u109))
(define-constant ERR-INVALID-VESSEL-TYPE (err u110))
(define-constant ERR-INVALID-ROLE (err u111))
(define-constant ERR-CONTRACT-INACTIVE (err u112))
(define-constant ERR-EMERGENCY-PAUSE (err u113))
(define-constant ERR-INVALID-YEAR (err u114))
(define-constant ERR-INVALID-TONNAGE (err u115))
(define-constant ERR-INVALID-VESSEL-VALUE (err u116))
(define-constant ERR-INVALID-COVERAGE-PERIOD (err u117))
(define-constant ERR-CLAIM-AMOUNT-TOO-HIGH (err u118))
(define-constant ERR-INVALID-INCIDENT-DATE (err u119))
(define-constant ERR-INVALID-COMPLIANCE-SCORE (err u120))
(define-constant ERR-INVALID-INPUT (err u121))
(define-constant ERR-EMPTY-STRING (err u122))
(define-constant ERR-INVALID-LIST-ITEM (err u123))

;; Risk assessment constants
(define-constant max-risk-score u100)
(define-constant min-risk-score u1)
(define-constant high-risk-threshold u70)
(define-constant medium-risk-threshold u40)

;; Insurance constants
(define-constant base-premium-rate u1000) ;; Base rate in microSTX
(define-constant risk-multiplier u10)
(define-constant max-claim-amount u10000000000) ;; 10,000 STX in microSTX

;; DATA STRUCTURES

;; Vessel information structure
(define-map vessels
  { vessel-id: (string-ascii 20) }
  {
    owner: principal,
    vessel-name: (string-ascii 50),
    vessel-type: (string-ascii 20),
    imo-number: (string-ascii 15),
    flag-state: (string-ascii 3),
    gross-tonnage: uint,
    year-built: uint,
    current-risk-score: uint,
    insurance-premium: uint,
    insurance-expiry: uint,
    last-inspection: uint,
    compliance-status: bool,
    active: bool,
    registration-date: uint
  }
)

;; Risk assessment data
(define-map risk-assessments
  { vessel-id: (string-ascii 20), assessment-id: uint }
  {
    assessor: principal,
    risk-factors: {
      age-factor: uint,
      maintenance-factor: uint,
      route-risk: uint,
      crew-experience: uint,
      weather-exposure: uint,
      cargo-type-risk: uint
    },
    total-risk-score: uint,
    assessment-date: uint,
    valid-until: uint,
    notes: (string-ascii 200)
  }
)

;; Insurance claims
(define-map insurance-claims
  { claim-id: uint }
  {
    vessel-id: (string-ascii 20),
    claimant: principal,
    claim-amount: uint,
    claim-type: (string-ascii 30),
    incident-date: uint,
    claim-date: uint,
    description: (string-ascii 300),
    status: (string-ascii 20), ;; "pending", "approved", "rejected", "paid"
    approved-amount: uint,
    processed-by: (optional principal),
    processed-date: (optional uint)
  }
)

;; Compliance records
(define-map compliance-records
  { vessel-id: (string-ascii 20), record-id: uint }
  {
    inspector: principal,
    inspection-type: (string-ascii 30),
    inspection-date: uint,
    compliance-score: uint,
    deficiencies: (list 10 (string-ascii 100)),
    corrective-actions: (list 10 (string-ascii 100)),
    next-inspection-due: uint,
    certificate-issued: bool
  }
)

;; User roles and permissions
(define-map user-roles
  { user: principal }
  { role: uint, active: bool, assigned-by: principal, assigned-date: uint }
)

;; DATA VARIABLES

(define-data-var next-assessment-id uint u1)
(define-data-var next-claim-id uint u1)
(define-data-var next-record-id uint u1)
(define-data-var contract-active bool true)
(define-data-var emergency-pause bool false)

;; INPUT VALIDATION FUNCTIONS

(define-private (validate-string-not-empty (str (string-ascii 200)))
  (> (len str) u0)
)

(define-private (validate-vessel-id (vessel-id (string-ascii 20)))
  (and 
    (> (len vessel-id) u0)
    (<= (len vessel-id) u20)
  )
)

(define-private (validate-string-length (str (string-ascii 300)) (max-len uint))
  (and 
    (> (len str) u0)
    (<= (len str) max-len)
  )
)

(define-private (validate-role (role uint))
  (and (>= role u1) (<= role u3))
)

(define-private (validate-risk-factor (factor uint))
  (and (>= factor u0) (<= factor u100))
)

(define-private (validate-compliance-score (score uint))
  (and (>= score u0) (<= score u100))
)

(define-private (validate-principal (user principal))
  (not (is-eq user 'SP000000000000000000002Q6VF78))
)

(define-private (validate-claim-id (claim-id uint))
  (and (> claim-id u0) (< claim-id u4294967295))
)

(define-private (validate-string-list-item (str (string-ascii 100)))
  (and (>= (len str) u0) (<= (len str) u100))
)

(define-private (validate-string-list (str-list (list 10 (string-ascii 100))))
  (fold validate-list-fold str-list true)
)

(define-private (validate-list-fold (item (string-ascii 100)) (acc bool))
  (and acc (validate-string-list-item item))
)

;; AUTHORIZATION FUNCTIONS

(define-read-only (is-contract-owner (user principal))
  (is-eq user contract-owner)
)

(define-read-only (has-role (user principal) (required-role uint))
  (match (map-get? user-roles { user: user })
    role-data (and (>= (get role role-data) required-role) (get active role-data))
    false
  )
)

(define-read-only (is-authorized (user principal) (required-role uint))
  (or (is-contract-owner user) (has-role user required-role))
)

;; EMERGENCY FUNCTIONS

(define-public (set-emergency-pause (paused bool))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (var-set emergency-pause paused)
    (ok paused)
  )
)

(define-public (deactivate-contract)
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (var-set contract-active false)
    (ok true)
  )
)

;; ROLE MANAGEMENT FUNCTIONS

(define-public (assign-role (user principal) (role uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-principal user) ERR-INVALID-INPUT)
    (asserts! (validate-role role) ERR-INVALID-ROLE)
    (ok (map-set user-roles
      { user: user }
      {
        role: role,
        active: true,
        assigned-by: tx-sender,
        assigned-date: block-height
      }
    ))
  )
)

(define-public (revoke-role (user principal))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-principal user) ERR-INVALID-INPUT)
    (ok (map-set user-roles
      { user: user }
      {
        role: u0,
        active: false,
        assigned-by: tx-sender,
        assigned-date: block-height
      }
    ))
  )
)

;; VESSEL MANAGEMENT FUNCTIONS

(define-public (register-vessel 
  (vessel-id (string-ascii 20))
  (vessel-name (string-ascii 50))
  (vessel-type (string-ascii 20))
  (imo-number (string-ascii 15))
  (flag-state (string-ascii 3))
  (gross-tonnage uint)
  (year-built uint))
  
  (let ((current-block block-height)
        (validated-vessel-id vessel-id)
        (validated-vessel-name vessel-name)
        (validated-vessel-type vessel-type)
        (validated-imo-number imo-number)
        (validated-flag-state flag-state)
        (validated-tonnage gross-tonnage)
        (validated-year year-built))
    (begin
      (asserts! (var-get contract-active) ERR-CONTRACT-INACTIVE)
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (asserts! (validate-string-length validated-vessel-name u50) ERR-EMPTY-STRING)
      (asserts! (validate-string-length validated-vessel-type u20) ERR-EMPTY-STRING)
      (asserts! (validate-string-length validated-imo-number u15) ERR-EMPTY-STRING)
      (asserts! (validate-string-length validated-flag-state u3) ERR-EMPTY-STRING)
      (asserts! (is-none (map-get? vessels { vessel-id: validated-vessel-id })) ERR-VESSEL-ALREADY-EXISTS)
      (asserts! (> validated-year u1900) ERR-INVALID-YEAR)
      (asserts! (> validated-tonnage u0) ERR-INVALID-TONNAGE)
      
      (ok (map-set vessels
        { vessel-id: validated-vessel-id }
        {
          owner: tx-sender,
          vessel-name: validated-vessel-name,
          vessel-type: validated-vessel-type,
          imo-number: validated-imo-number,
          flag-state: validated-flag-state,
          gross-tonnage: validated-tonnage,
          year-built: validated-year,
          current-risk-score: u50, ;; Default medium risk
          insurance-premium: u0,
          insurance-expiry: u0,
          last-inspection: u0,
          compliance-status: false,
          active: true,
          registration-date: current-block
        }
      ))
    )
  )
)

(define-public (update-vessel-status (vessel-id (string-ascii 20)) (active bool))
  (let ((validated-vessel-id vessel-id)
        (vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND)))
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (asserts! (or (is-eq tx-sender (get owner vessel-data)) 
                   (is-authorized tx-sender admin-role)) ERR-NOT-AUTHORIZED)
      
      (ok (map-set vessels
        { vessel-id: validated-vessel-id }
        (merge vessel-data { active: active })
      ))
    )
  )
)

;; RISK ASSESSMENT FUNCTIONS

(define-private (calculate-risk-score 
  (age-factor uint)
  (maintenance-factor uint)
  (route-risk uint)
  (crew-experience uint)
  (weather-exposure uint)
  (cargo-type-risk uint))
  
  (let ((weighted-score (+ 
    (* age-factor u15)           ;; 15% weight
    (* maintenance-factor u25)   ;; 25% weight
    (* route-risk u20)          ;; 20% weight
    (* crew-experience u15)     ;; 15% weight
    (* weather-exposure u15)    ;; 15% weight
    (* cargo-type-risk u10)     ;; 10% weight
  )))
    (/ weighted-score u100)
  )
)

(define-public (conduct-risk-assessment
  (vessel-id (string-ascii 20))
  (age-factor uint)
  (maintenance-factor uint)
  (route-risk uint)
  (crew-experience uint)
  (weather-exposure uint)
  (cargo-type-risk uint)
  (notes (string-ascii 200)))
  
  (let (
    (validated-vessel-id vessel-id)
    (validated-age-factor age-factor)
    (validated-maintenance-factor maintenance-factor)
    (validated-route-risk route-risk)
    (validated-crew-experience crew-experience)
    (validated-weather-exposure weather-exposure)
    (validated-cargo-type-risk cargo-type-risk)
    (validated-notes notes)
    (vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND))
    (assessment-id (var-get next-assessment-id))
    (risk-score (calculate-risk-score validated-age-factor validated-maintenance-factor validated-route-risk 
                                    validated-crew-experience validated-weather-exposure validated-cargo-type-risk))
  )
    (begin
      (asserts! (is-authorized tx-sender inspector-role) ERR-NOT-AUTHORIZED)
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (asserts! (validate-risk-factor validated-age-factor) ERR-INVALID-RISK-SCORE)
      (asserts! (validate-risk-factor validated-maintenance-factor) ERR-INVALID-RISK-SCORE)
      (asserts! (validate-risk-factor validated-route-risk) ERR-INVALID-RISK-SCORE)
      (asserts! (validate-risk-factor validated-crew-experience) ERR-INVALID-RISK-SCORE)
      (asserts! (validate-risk-factor validated-weather-exposure) ERR-INVALID-RISK-SCORE)
      (asserts! (validate-risk-factor validated-cargo-type-risk) ERR-INVALID-RISK-SCORE)
      (asserts! (validate-string-length validated-notes u200) ERR-EMPTY-STRING)
      
      ;; Create risk assessment record
      (map-set risk-assessments
        { vessel-id: validated-vessel-id, assessment-id: assessment-id }
        {
          assessor: tx-sender,
          risk-factors: {
            age-factor: validated-age-factor,
            maintenance-factor: validated-maintenance-factor,
            route-risk: validated-route-risk,
            crew-experience: validated-crew-experience,
            weather-exposure: validated-weather-exposure,
            cargo-type-risk: validated-cargo-type-risk
          },
          total-risk-score: risk-score,
          assessment-date: block-height,
          valid-until: (+ block-height u8640), ;; Valid for ~60 days
          notes: validated-notes
        }
      )
      
      ;; Update vessel risk score
      (map-set vessels
        { vessel-id: validated-vessel-id }
        (merge vessel-data { current-risk-score: risk-score })
      )
      
      (var-set next-assessment-id (+ assessment-id u1))
      (ok risk-score)
    )
  )
)

;; INSURANCE MANAGEMENT FUNCTIONS

(define-private (calculate-premium (risk-score uint) (vessel-value uint))
  (let ((risk-multiplier-calc (+ u100 (* risk-score risk-multiplier))))
    (/ (* vessel-value risk-multiplier-calc) u10000)
  )
)

(define-public (purchase-insurance 
  (vessel-id (string-ascii 20))
  (vessel-value uint)
  (coverage-period uint))
  
  (let (
    (validated-vessel-id vessel-id)
    (vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND))
    (premium (calculate-premium (get current-risk-score vessel-data) vessel-value))
  )
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (asserts! (is-eq tx-sender (get owner vessel-data)) ERR-NOT-AUTHORIZED)
      (asserts! (> vessel-value u0) ERR-INVALID-VESSEL-VALUE)
      (asserts! (and (>= coverage-period u30) (<= coverage-period u365)) ERR-INVALID-COVERAGE-PERIOD)
      (ok (map-set vessels
        { vessel-id: validated-vessel-id }
        (merge vessel-data {
          insurance-premium: premium,
          insurance-expiry: (+ block-height (* coverage-period u144)) ;; Approximate blocks per day
        })
      ))
    )
  )
)

(define-public (file-insurance-claim
  (vessel-id (string-ascii 20))
  (claim-amount uint)
  (claim-type (string-ascii 30))
  (incident-date uint)
  (description (string-ascii 300)))
  
  (let (
    (validated-vessel-id vessel-id)
    (validated-claim-type claim-type)
    (validated-description description)
    (vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND))
    (claim-id (var-get next-claim-id))
  )
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (asserts! (validate-string-length validated-claim-type u30) ERR-EMPTY-STRING)
      (asserts! (validate-string-length validated-description u300) ERR-EMPTY-STRING)
      (asserts! (is-eq tx-sender (get owner vessel-data)) ERR-NOT-AUTHORIZED)
      (asserts! (> (get insurance-expiry vessel-data) block-height) ERR-VESSEL-NOT-INSURED)
      (asserts! (<= claim-amount max-claim-amount) ERR-CLAIM-AMOUNT-TOO-HIGH)
      (asserts! (<= incident-date block-height) ERR-INVALID-INCIDENT-DATE)
      
      (map-set insurance-claims
        { claim-id: claim-id }
        {
          vessel-id: validated-vessel-id,
          claimant: tx-sender,
          claim-amount: claim-amount,
          claim-type: validated-claim-type,
          incident-date: incident-date,
          claim-date: block-height,
          description: validated-description,
          status: "pending",
          approved-amount: u0,
          processed-by: none,
          processed-date: none
        }
      )
      
      (var-set next-claim-id (+ claim-id u1))
      (ok claim-id)
    )
  )
)

(define-public (process-claim 
  (claim-id uint)
  (approved bool)
  (approved-amount uint))
  
  (let ((claim-data (unwrap! (map-get? insurance-claims { claim-id: claim-id }) ERR-CLAIM-NOT-FOUND)))
    (begin
      (asserts! (is-authorized tx-sender admin-role) ERR-NOT-AUTHORIZED)
      (asserts! (validate-claim-id claim-id) ERR-INVALID-INPUT)
      (asserts! (is-eq (get status claim-data) "pending") ERR-CLAIM-ALREADY-PROCESSED)
      
      (ok (map-set insurance-claims
        { claim-id: claim-id }
        (merge claim-data {
          status: (if approved "approved" "rejected"),
          approved-amount: (if approved approved-amount u0),
          processed-by: (some tx-sender),
          processed-date: (some block-height)
        })
      ))
    )
  )
)

;; COMPLIANCE MONITORING FUNCTIONS

(define-public (conduct-compliance-inspection
  (vessel-id (string-ascii 20))
  (inspection-type (string-ascii 30))
  (compliance-score uint)
  (deficiencies (list 10 (string-ascii 100)))
  (corrective-actions (list 10 (string-ascii 100))))
  
  (let (
    (validated-vessel-id vessel-id)
    (validated-inspection-type inspection-type)
    (validated-compliance-score compliance-score)
    (vessel-data (unwrap! (map-get? vessels { vessel-id: vessel-id }) ERR-VESSEL-NOT-FOUND))
    (record-id (var-get next-record-id))
  )
    (begin
      (asserts! (is-authorized tx-sender inspector-role) ERR-NOT-AUTHORIZED)
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (asserts! (validate-string-length validated-inspection-type u30) ERR-EMPTY-STRING)
      (asserts! (validate-compliance-score validated-compliance-score) ERR-INVALID-COMPLIANCE-SCORE)
      (asserts! (validate-string-list deficiencies) ERR-INVALID-LIST-ITEM)
      (asserts! (validate-string-list corrective-actions) ERR-INVALID-LIST-ITEM)
      
      (map-set compliance-records
        { vessel-id: validated-vessel-id, record-id: record-id }
        {
          inspector: tx-sender,
          inspection-type: validated-inspection-type,
          inspection-date: block-height,
          compliance-score: validated-compliance-score,
          deficiencies: deficiencies,
          corrective-actions: corrective-actions,
          next-inspection-due: (+ block-height u4320), ;; ~30 days
          certificate-issued: (>= validated-compliance-score u80)
        }
      )
      
      ;; Update vessel compliance status
      (map-set vessels
        { vessel-id: validated-vessel-id }
        (merge vessel-data {
          last-inspection: block-height,
          compliance-status: (>= validated-compliance-score u80)
        })
      )
      
      (var-set next-record-id (+ record-id u1))
      (ok record-id)
    )
  )
)

;; QUERY FUNCTIONS

(define-read-only (get-vessel-info (vessel-id (string-ascii 20)))
  (let ((validated-vessel-id vessel-id))
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (ok (map-get? vessels { vessel-id: validated-vessel-id }))
    )
  )
)

(define-read-only (get-risk-assessment (vessel-id (string-ascii 20)) (assessment-id uint))
  (let ((validated-vessel-id vessel-id))
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (ok (map-get? risk-assessments { vessel-id: validated-vessel-id, assessment-id: assessment-id }))
    )
  )
)

(define-read-only (get-insurance-claim (claim-id uint))
  (ok (map-get? insurance-claims { claim-id: claim-id }))
)

(define-read-only (get-compliance-record (vessel-id (string-ascii 20)) (record-id uint))
  (let ((validated-vessel-id vessel-id))
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (ok (map-get? compliance-records { vessel-id: validated-vessel-id, record-id: record-id }))
    )
  )
)

(define-read-only (get-user-role (user principal))
  (ok (map-get? user-roles { user: user }))
)

(define-read-only (get-vessel-risk-level (vessel-id (string-ascii 20)))
  (let ((validated-vessel-id vessel-id))
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (ok (match (map-get? vessels { vessel-id: validated-vessel-id })
        vessel-data 
        (let ((risk-score (get current-risk-score vessel-data)))
          (if (>= risk-score high-risk-threshold)
            "HIGH"
            (if (>= risk-score medium-risk-threshold)
              "MEDIUM"
              "LOW"
            )
          )
        )
        "UNKNOWN"
      ))
    )
  )
)

(define-read-only (is-vessel-compliant (vessel-id (string-ascii 20)))
  (let ((validated-vessel-id vessel-id))
    (begin
      (asserts! (validate-vessel-id validated-vessel-id) ERR-INVALID-INPUT)
      (ok (match (map-get? vessels { vessel-id: validated-vessel-id })
        vessel-data 
        (and 
          (get compliance-status vessel-data)
          (> (get insurance-expiry vessel-data) block-height)
        )
        false
      ))
    )
  )
)

;; INITIALIZATION

;; Initialize contract owner with admin role
(map-set user-roles
  { user: contract-owner }
  {
    role: admin-role,
    active: true,
    assigned-by: contract-owner,
    assigned-date: block-height
  }
)