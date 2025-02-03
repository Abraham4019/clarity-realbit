;; RealBit Property NFT Contract
(define-non-fungible-token property uint)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data vars
(define-map property-details
  uint 
  {
    name: (string-utf8 100),
    location: (string-utf8 200),
    value: uint,
    agent: principal
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
    ;; Only contract owner can register properties
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    ;; Mint new property NFT
    (try! (nft-mint? property token-id agent))
    ;; Store property details
    (map-set property-details token-id
      { name: name, 
        location: location, 
        value: value, 
        agent: agent })
    ;; Update last token id
    (var-set last-token-id token-id)
    (ok token-id)))

;; Read only functions
(define-read-only (get-property (token-id uint))
  (map-get? property-details token-id))

(define-read-only (get-property-owner (token-id uint))
  (nft-get-owner? property token-id))
