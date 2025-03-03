;; RealBit Shares Token Contract
(define-fungible-token property-share)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-shares (err u101))
(define-constant err-invalid-price (err u102))

;; Data vars
(define-map property-shares 
  uint
  { total-shares: uint,
    price-per-share: uint,
    last-price-update: uint }
)

;; Public functions
(define-public (create-shares 
  (property-id uint) 
  (total-shares uint)
  (price-per-share uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> total-shares u0) err-invalid-price)
    (asserts! (> price-per-share u0) err-invalid-price)
    (try! (ft-mint? property-share total-shares contract-owner))
    (map-set property-shares property-id
      { total-shares: total-shares,
        price-per-share: price-per-share,
        last-price-update: block-height })
    (ok true)))

(define-public (update-share-price
  (property-id uint)
  (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-price u0) err-invalid-price)
    (map-set property-shares property-id
      (merge (unwrap! (map-get? property-shares property-id) err-insufficient-shares)
        { price-per-share: new-price,
          last-price-update: block-height }))
    (ok true)))

(define-public (transfer-shares 
  (amount uint)
  (recipient principal))
  (begin
    (asserts! (>= (ft-get-balance property-share tx-sender) amount) err-insufficient-shares)
    (ft-transfer? property-share amount tx-sender recipient)))

;; Read only functions
(define-read-only (get-shares-info (property-id uint))
  (map-get? property-shares property-id))

(define-read-only (get-balance (owner principal))
  (ok (ft-get-balance property-share owner)))
