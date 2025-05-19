;; Certificate Issuance Contract
;; Creates tradable energy attribute certificates

(define-data-var admin principal tx-sender)
(define-data-var certificate-counter uint u0)

;; Certificate NFT
(define-non-fungible-token energy-certificate uint)

;; Certificate metadata
(define-map certificate-data uint
  {
    generator: principal,
    period: uint,
    energy-kwh: uint,
    energy-type: (string-utf8 20),
    location: (string-utf8 100),
    issuance-time: uint,
    retired: bool
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_PRODUCTION_NOT_FOUND u2)
(define-constant ERR_CERTIFICATE_NOT_FOUND u3)
(define-constant ERR_NOT_VERIFIED u4)
(define-constant ERR_ALREADY_ISSUED u5)

;; Track which production records have been issued certificates
(define-map issued-for-production
  {generator: principal, period: uint}
  bool
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Contract for production tracking
(define-trait production-tracking-trait
  (
    (get-production (principal uint) (response {energy-kwh: uint, timestamp: uint, verified: bool} uint))
  )
)

;; Contract for generator verification
(define-trait generator-verification-trait
  (
    (is-verified-generator (principal) (response {name: (string-utf8 100), location: (string-utf8 100), capacity-kw: uint, energy-type: (string-utf8 20), verified: bool} uint))
  )
)

;; Issue a certificate for verified production
(define-public (issue-certificate
  (generator principal)
  (period uint)
  (tracking-contract <production-tracking-trait>)
  (verification-contract <generator-verification-trait>))
  (let
    (
      (production-result (contract-call? tracking-contract get-production generator period))
      (generator-result (contract-call? verification-contract is-verified-generator generator))
      (production-key {generator: generator, period: period})
    )

    ;; Check if caller is authorized
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))

    ;; Check if production data exists and is verified
    (asserts! (is-ok production-result) (err ERR_PRODUCTION_NOT_FOUND))
    (let
      (
        (production (unwrap! production-result (err ERR_PRODUCTION_NOT_FOUND)))
      )
      (asserts! (get verified production) (err ERR_NOT_VERIFIED))

      ;; Check if generator is verified
      (asserts! (is-ok generator-result) (err ERR_NOT_VERIFIED))
      (let
        (
          (generator-data (unwrap! generator-result (err ERR_NOT_VERIFIED)))
          (certificate-id (+ (var-get certificate-counter) u1))
        )

        ;; Check if certificate was already issued for this production
        (asserts! (is-none (map-get? issued-for-production production-key)) (err ERR_ALREADY_ISSUED))

        ;; Mint the certificate
        (try! (nft-mint? energy-certificate certificate-id generator))

        ;; Store certificate data
        (map-set certificate-data certificate-id
          {
            generator: generator,
            period: period,
            energy-kwh: (get energy-kwh production),
            energy-type: (get energy-type generator-data),
            location: (get location generator-data),
            issuance-time: block-height,
            retired: false
          }
        )

        ;; Mark this production as having a certificate issued
        (map-set issued-for-production production-key true)

        ;; Increment certificate counter
        (var-set certificate-counter certificate-id)

        (ok certificate-id)
      )
    )
  )
)

;; Get certificate information
(define-read-only (get-certificate-info (id uint))
  (match (map-get? certificate-data id)
    data (ok data)
    (err ERR_CERTIFICATE_NOT_FOUND)
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
