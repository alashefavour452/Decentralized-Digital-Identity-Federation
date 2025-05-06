;; Audit Trail Contract
;; Records identity verification activities

(define-data-var admin principal tx-sender)

;; Audit events
(define-map audit-events
  { event-id: (buff 32) }
  {
    event-type: (string-ascii 64), ;; "verification", "authentication", "revocation", etc.
    user-id: (string-ascii 64),
    provider-id: (string-ascii 64),
    timestamp: uint,
    details: (string-ascii 255),
    success: bool
  }
)

;; Public function to record an audit event
(define-public (record-event
    (event-id (buff 32))
    (event-type (string-ascii 64))
    (user-id (string-ascii 64))
    (provider-id (string-ascii 64))
    (details (string-ascii 255))
    (success bool))
  (begin
    ;; Check if event already exists
    (asserts! (is-none (map-get? audit-events { event-id: event-id }))
              (err u100))

    ;; Record the event
    (map-set audit-events
      { event-id: event-id }
      {
        event-type: event-type,
        user-id: user-id,
        provider-id: provider-id,
        timestamp: block-height,
        details: details,
        success: success
      }
    )
    (ok true)
  )
)

;; Public function to get an audit event
(define-read-only (get-event (event-id (buff 32)))
  (match (map-get? audit-events { event-id: event-id })
    event (ok event)
    (err u404)
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
