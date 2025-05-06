;; Identity Provider Verification Contract
;; Validates legitimate credential issuers

(define-data-var admin principal tx-sender)

;; Map of verified identity providers
(define-map verified-providers
  { provider-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    url: (string-ascii 255),
    public-key: (buff 33),
    verified: bool,
    verification-date: uint
  }
)

;; Public function to verify a new identity provider
(define-public (register-provider
    (provider-id (string-ascii 64))
    (name (string-ascii 100))
    (url (string-ascii 255))
    (public-key (buff 33)))
  (begin
    ;; Only admin can register new providers
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Check if provider already exists
    (asserts! (is-none (map-get? verified-providers { provider-id: provider-id }))
              (err u100))

    ;; Add the provider to the map
    (map-set verified-providers
      { provider-id: provider-id }
      {
        name: name,
        url: url,
        public-key: public-key,
        verified: true,
        verification-date: block-height
      }
    )
    (ok true)
  )
)

;; Public function to check if a provider is verified
(define-read-only (is-verified-provider (provider-id (string-ascii 64)))
  (match (map-get? verified-providers { provider-id: provider-id })
    provider (ok (get verified bool provider))
    (err u404)
  )
)

;; Public function to revoke a provider's verification
(define-public (revoke-provider (provider-id (string-ascii 64)))
  (begin
    ;; Only admin can revoke providers
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Check if provider exists
    (match (map-get? verified-providers { provider-id: provider-id })
      provider
        (map-set verified-providers
          { provider-id: provider-id }
          (merge provider { verified: false })
        )
      (err u404)
    )
    (ok true)
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
