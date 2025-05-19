;; Trading Contract
;; Manages buying and selling of energy certificates

(define-data-var admin principal tx-sender)
(define-data-var fee-percentage uint u1) ;; 1% fee
(define-data-var fee-recipient principal tx-sender)

;; Listing structure
(define-map certificate-listings uint
  {
    seller: principal,
    price: uint,
    active: bool
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_NOT_OWNER u3)
(define-constant ERR_ALREADY_LISTED u4)
(define-constant ERR_NOT_ACTIVE u5)
(define-constant ERR_INSUFFICIENT_FUNDS u6)
(define-constant ERR_INVALID_PRICE u7)
(define-constant ERR_RETIRED u8)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Certificate NFT interface
(define-trait certificate-trait
  (
    (get-certificate-info (uint) (response {generator: principal, period: uint, energy-kwh: uint, energy-type: (string-utf8 20), location: (string-utf8 100), issuance-time: uint, retired: bool} uint))
    (transfer (uint principal principal) (response bool uint))
  )
)

;; List a certificate for sale
(define-public (list-certificate
  (certificate-id uint)
  (price uint)
  (certificate-contract <certificate-trait>))
  (let
    (
      (certificate-info-result (contract-call? certificate-contract get-certificate-info certificate-id))
      (owner tx-sender)
    )

    ;; Verify price is valid
    (asserts! (> price u0) (err ERR_INVALID_PRICE))

    ;; Check if certificate exists and not retired
    (asserts! (is-ok certificate-info-result) (err ERR_NOT_FOUND))
    (let
      (
        (certificate-info (unwrap! certificate-info-result (err ERR_NOT_FOUND)))
      )
      (asserts! (not (get retired certificate-info)) (err ERR_RETIRED))

      ;; Verify the seller owns the certificate
      ;; In a real implementation, we'd check the NFT ownership
      ;; For simplicity, we're assuming the caller is the owner

      ;; Check if already listed
      (asserts! (is-none (map-get? certificate-listings certificate-id)) (err ERR_ALREADY_LISTED))

      ;; Create listing
      (map-set certificate-listings certificate-id
        {
          seller: owner,
          price: price,
          active: true
        }
      )

      (ok true)
    )
  )
)

;; Cancel a listing
(define-public (cancel-listing
  (certificate-id uint))
  (let
    (
      (listing (unwrap! (map-get? certificate-listings certificate-id) (err ERR_NOT_FOUND)))
    )

    ;; Verify caller is the seller
    (asserts! (is-eq tx-sender (get seller listing)) (err ERR_NOT_OWNER))

    ;; Remove listing
    (map-delete certificate-listings certificate-id)

    (ok true)
  )
)

;; Buy a certificate
(define-public (buy-certificate
  (certificate-id uint)
  (certificate-contract <certificate-trait>))
  (let
    (
      (listing (unwrap! (map-get? certificate-listings certificate-id) (err ERR_NOT_FOUND)))
      (price (get price listing))
      (seller (get seller listing))
      (active (get active listing))
      (fee (/ (* price (var-get fee-percentage)) u100))
      (seller-amount (- price fee))
    )

    ;; Check if listing is active
    (asserts! active (err ERR_NOT_ACTIVE))

    ;; Transfer payment to seller (fee goes to fee-recipient)
    (asserts! (>= (stx-get-balance tx-sender) price) (err ERR_INSUFFICIENT_FUNDS))
    (try! (stx-transfer? seller-amount tx-sender seller))
    (try! (stx-transfer? fee tx-sender (var-get fee-recipient)))

    ;; Transfer certificate ownership
    (try! (contract-call? certificate-contract transfer certificate-id seller tx-sender))

    ;; Remove listing
    (map-delete certificate-listings certificate-id)

    (ok true)
  )
)

;; Get listing details
(define-read-only (get-listing (certificate-id uint))
  (match (map-get? certificate-listings certificate-id)
    listing (ok listing)
    (err ERR_NOT_FOUND)
  )
)

;; Set fee percentage (admin only)
(define-public (set-fee-percentage (new-fee-percentage uint))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (<= new-fee-percentage u10) (err ERR_INVALID_PRICE)) ;; Max 10% fee
    (var-set fee-percentage new-fee-percentage)
    (ok true)
  )
)

;; Set fee recipient (admin only)
(define-public (set-fee-recipient (new-fee-recipient principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (var-set fee-recipient new-fee-recipient)
    (ok true)
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
