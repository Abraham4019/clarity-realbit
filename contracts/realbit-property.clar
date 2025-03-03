;; RealBit Property NFT Contract
(define-non-fungible-token property uint)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))

;; Data vars
(define-map property-details
  uint 
  {
    name: (string-utf8 100),
    location: (string-utf8 200),
    value: uint,
    agent: principal,
    last-updated: uint
  }
)

(define-data-var last-token-id uint u0)

;; Public functions
(define-public (register-property 
  (name (string-utf8 100))
  (location (string-utf8 200))
  (value uint)
  (agent principal))
  (let ((token-id (+ (var-get last-token-id) u1)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> value u0) err-invalid-input)
    (try! (nft-mint? property token-id agent))
    (map-set property-details token-id
      { name: name, 
        location: location, 
        value: value, 
        agent: agent,
        last-updated: block-height })
    (var-set last-token-id token-id)
    (ok token-id)))

(define-public (update-property-details
  (token-id uint)
  (name (string-utf8 100))
  (location (string-utf8 200))
  (value uint))
  (let ((current-owner (unwrap! (nft-get-owner? property token-id) err-not-found)))
    (asserts! (or (is-eq tx-sender current-owner) (is-eq tx-sender contract-owner)) err-unauthorized)
    (asserts! (> value u0) err-invalid-input)
    (map-set property-details token-id
      (merge (unwrap! (map-get? property-details token-id) err-not-found)
        { name: name,
          location: location,
          value: value,
          last-updated: block-height }))
    (ok true)))

;; Read only functions
(define-read-only (get-property (token-id uint))
  (map-get? property-details token-id))

(define-read-only (get-property-owner (token-id uint))
  (nft-get-owner? property token-id))
