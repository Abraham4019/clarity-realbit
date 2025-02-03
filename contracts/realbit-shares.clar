;; RealBit Shares Token Contract
(define-fungible-token property-share)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-shares (err u101))

;; Data vars
(define-map property-shares 
  uint
  { total-shares: uint,
    price-per-share: uint }
)

;; Public functions
(define-public (create-shares 
  (property-id uint) 
  (total-shares uint)
  (price-per-share uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? property-share total-shares contract-owner))
    (map-set property-shares property-id
      { total-shares: total-shares,
        price-per-share: price-per-share })
    (ok true)))

(define-public (transfer-shares 
  (amount uint)
  (recipient principal))
  (ft-transfer? property-share amount tx-sender recipient))

;; Read only functions
(define-read-only (get-shares-info (property-id uint))
  (map-get? property-shares property-id))
