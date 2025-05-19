;; Retirement Contract
;; Records permanent removal of certificates from circulation

(define-data-var admin principal tx-sender)

;; Retirement records
(define-map retirement-records uint
  {
    retiree: principal,
    retirement-time: uint,
    reason: (string-utf8 100),
    beneficiary: (optional principal)
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_ALREADY_RETIRED u3)
(define-constant ERR_NOT_OWNER u4)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Certificate contract interface
(define-trait certificate-trait
  (
    (get-certificate-info (uint) (response {generator: principal, period: uint, energy-kwh: uint, energy-type: (string-utf8 20), location: (string-utf8 100), issuance-time: uint, retired: bool} uint))
    (transfer (uint principal principal) (response bool uint))
  )
)

;; Retire a certificate permanently
(define-public (retire-certificate
  (certificate-id uint)
  (reason (string-utf8 100))
  (beneficiary (optional principal))
  (certificate-contract <certificate-trait>))
  (let
    (
      (certificate-info-result (contract-call? certificate-contract get-certificate-info certificate-id))
    )

    ;; Check if certificate exists
    (asserts! (is-ok certificate-info-result) (err ERR_NOT_FOUND))
    (let
      (
        (certificate-info (unwrap! certificate-info-result (err ERR_NOT_FOUND)))
      )
      ;; Check if already retired
      (asserts! (not (get retired certificate-info)) (err ERR_ALREADY_RETIRED))

      ;; Verify ownership (in a real implementation, check NFT ownership)
      ;; For simplicity, we're assuming the caller is the owner

      ;; Record retirement
      (map-set retirement-records certificate-id
        {
          retiree: tx-sender,
          retirement-time: block-height,
          reason: reason,
          beneficiary: beneficiary
        }
      )

      ;; Transfer to retirement address (in a real implementation)
      ;; Here we would transfer the NFT to a burn address

      (ok true)
    )
  )
)

;; Get retirement details
(define-read-only (get-retirement-info (certificate-id uint))
  (match (map-get? retirement-records certificate-id)
    record (ok record)
    (err ERR_NOT_FOUND)
  )
)

;; Admin can retire on behalf of someone
(define-public (admin-retire-certificate
  (certificate-id uint)
  (owner principal)
  (reason (string-utf8 100))
  (beneficiary (optional principal))
  (certificate-contract <certificate-trait>))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (let
      (
        (certificate-info-result (contract-call? certificate-contract get-certificate-info certificate-id))
      )

      ;; Check if certificate exists
      (asserts! (is-ok certificate-info-result) (err ERR_NOT_FOUND))
      (let
        (
          (certificate-info (unwrap! certificate-info-result (err ERR_NOT_FOUND)))
        )
        ;; Check if already retired
        (asserts! (not (get retired certificate-info)) (err ERR_ALREADY_RETIRED))

        ;; Record retirement
        (map-set retirement-records certificate-id
          {
            retiree: owner,
            retirement-time: block-height,
            reason: reason,
            beneficiary: beneficiary
          }
        )

        ;; Transfer to retirement address (in a real implementation)
        ;; Here we would transfer the NFT to a burn address

        (ok true)
      )
    )
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
