;; Generator Verification Contract
;; This contract validates energy producers

(define-data-var admin principal tx-sender)

;; Map to store verified generators
(define-map verified-generators principal
  {
    name: (string-utf8 100),
    location: (string-utf8 100),
    capacity-kw: uint,
    energy-type: (string-utf8 20),
    verified: bool
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_VERIFIED u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new generator (only admin can do this)
(define-public (register-generator (generator-id principal) (name (string-utf8 100)) (location (string-utf8 100)) (capacity-kw uint) (energy-type (string-utf8 20)))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? verified-generators generator-id)) (err ERR_ALREADY_VERIFIED))

    (map-set verified-generators generator-id
      {
        name: name,
        location: location,
        capacity-kw: capacity-kw,
        energy-type: energy-type,
        verified: true
      }
    )
    (ok true)
  )
)

;; Verify if a generator is registered
(define-read-only (is-verified-generator (generator-id principal))
  (match (map-get? verified-generators generator-id)
    generator (ok generator)
    (err ERR_NOT_FOUND)
  )
)

;; Remove a generator's verification
(define-public (revoke-verification (generator-id principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? verified-generators generator-id)) (err ERR_NOT_FOUND))

    (map-delete verified-generators generator-id)
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
