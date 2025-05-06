;; Attribute Mapping Contract
;; Standardizes identity claims across systems

(define-data-var admin principal tx-sender)

;; Map of attribute schemas
(define-map attribute-schemas
  { schema-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    description: (string-ascii 255),
    version: (string-ascii 20),
    created-at: uint
  }
)

;; Map of attribute mappings between schemas
(define-map attribute-mappings
  {
    source-schema: (string-ascii 64),
    source-attribute: (string-ascii 64),
    target-schema: (string-ascii 64)
  }
  {
    target-attribute: (string-ascii 64),
    transformation: (string-ascii 255), ;; Optional transformation rule
    confidence: uint ;; 0-100 scale
  }
)

;; Public function to register a new attribute schema
(define-public (register-schema
    (schema-id (string-ascii 64))
    (name (string-ascii 100))
    (description (string-ascii 255))
    (version (string-ascii 20)))
  (begin
    ;; Only admin can register schemas
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Check if schema already exists
    (asserts! (is-none (map-get? attribute-schemas { schema-id: schema-id }))
              (err u100))

    ;; Add the schema to the map
    (map-set attribute-schemas
      { schema-id: schema-id }
      {
        name: name,
        description: description,
        version: version,
        created-at: block-height
      }
    )
    (ok true)
  )
)

;; Public function to create attribute mapping
(define-public (create-mapping
    (source-schema (string-ascii 64))
    (source-attribute (string-ascii 64))
    (target-schema (string-ascii 64))
    (target-attribute (string-ascii 64))
    (transformation (string-ascii 255))
    (confidence uint))
  (begin
    ;; Only admin can create mappings
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Validate confidence (0-100)
    (asserts! (<= confidence u100) (err u101))

    ;; Verify both schemas exist
    (asserts! (is-some (map-get? attribute-schemas { schema-id: source-schema }))
              (err u102))
    (asserts! (is-some (map-get? attribute-schemas { schema-id: target-schema }))
              (err u103))

    ;; Create the mapping
    (map-set attribute-mappings
      {
        source-schema: source-schema,
        source-attribute: source-attribute,
        target-schema: target-schema
      }
      {
        target-attribute: target-attribute,
        transformation: transformation,
        confidence: confidence
      }
    )
    (ok true)
  )
)

;; Public function to look up attribute mapping
(define-read-only (get-attribute-mapping
    (source-schema (string-ascii 64))
    (source-attribute (string-ascii 64))
    (target-schema (string-ascii 64)))
  (match (map-get? attribute-mappings
          {
            source-schema: source-schema,
            source-attribute: source-attribute,
            target-schema: target-schema
          })
    mapping (ok mapping)
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
