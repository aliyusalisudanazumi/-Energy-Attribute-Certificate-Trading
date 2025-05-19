;; Production Tracking Contract
;; Records energy generation amounts

(define-data-var admin principal tx-sender)

;; Define generator record structure
(define-map production-records
  {generator: principal, period: uint}
  {
    energy-kwh: uint,
    timestamp: uint,
    verified: bool
  }
)

;; Tracking production periods
(define-data-var current-period uint u0)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_RECORDED u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_INVALID_GENERATOR u4)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Contract for generator verification
(define-trait generator-verification-trait
  (
    (is-verified-generator (principal) (response {name: (string-utf8 100), location: (string-utf8 100), capacity-kw: uint, energy-type: (string-utf8 20), verified: bool} uint))
  )
)

;; Record energy production
(define-public (record-production
  (generator principal)
  (energy-kwh uint)
  (verification-contract <generator-verification-trait>))
  (let
    (
      (period (var-get current-period))
      (record-key {generator: generator, period: period})
      (generator-verified (contract-call? verification-contract is-verified-generator generator))
    )

    ;; Verify generator is registered
    (asserts! (is-ok generator-verified) (err ERR_INVALID_GENERATOR))

    ;; Verify production not already recorded for this period
    (asserts! (is-none (map-get? production-records record-key)) (err ERR_ALREADY_RECORDED))

    ;; Only generator or admin can record production
    (asserts! (or (is-eq tx-sender generator) (is-admin)) (err ERR_UNAUTHORIZED))

    ;; Record the production
    (map-set production-records record-key
      {
        energy-kwh: energy-kwh,
        timestamp: block-height,
        verified: (is-admin) ;; Auto-verified if admin is recording
      }
    )

    (ok true)
  )
)

;; Admin can verify a production record
(define-public (verify-production (generator principal) (period uint))
  (let
    (
      (record-key {generator: generator, period: period})
    )

    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (match (map-get? production-records record-key)
      record
        (begin
          (map-set production-records record-key
            (merge record {verified: true})
          )
          (ok true)
        )
      (err ERR_NOT_FOUND)
    )
  )
)

;; Get production details
(define-read-only (get-production (generator principal) (period uint))
  (match (map-get? production-records {generator: generator, period: period})
    record (ok record)
    (err ERR_NOT_FOUND)
  )
)

;; Start a new production period
(define-public (start-new-period)
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (var-set current-period (+ (var-get current-period) u1))
    (ok (var-get current-period))
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)
