;; RealBit Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-listing-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-price (err u103))
(define-constant err-unauthorized (err u104))

;; Data vars
(define-map share-listings
  { property-id: uint, seller: principal }
  { amount: uint, 
    price-per-share: uint,
    status: (string-utf8 10) }  ;; active, completed, cancelled
)

(define-map escrow-balance
  { buyer: principal, listing-id: (tuple (property-id uint) (seller principal)) }
  uint
)

;; Public functions
(define-public (list-shares 
  (property-id uint)
  (amount uint)
  (price-per-share uint))
  (begin
    (asserts! (> price-per-share u0) err-invalid-price)
    (try! (contract-call? .realbit-shares get-balance tx-sender))
    (map-set share-listings
      { property-id: property-id, 
        seller: tx-sender }
      { amount: amount,
        price-per-share: price-per-share,
        status: "active" })
    (ok true)))

(define-public (buy-shares
  (property-id uint)
  (seller principal)
  (amount uint))
  (let (
    (listing (unwrap! (map-get? share-listings 
            { property-id: property-id, seller: seller })
            err-listing-not-found))
    (total-cost (* amount (get price-per-share listing))))
    
    ;; Validate listing status
    (asserts! (is-eq (get status listing) "active") err-listing-not-found)
    
    ;; Check if buyer has sufficient balance
    (asserts! (>= (stx-get-balance tx-sender) total-cost) 
             err-insufficient-balance)
    
    ;; Transfer STX to escrow
    (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
    
    ;; Update escrow balance
    (map-set escrow-balance
      { buyer: tx-sender, 
        listing-id: {property-id: property-id, seller: seller} }
      total-cost)
    
    ;; Transfer shares
    (try! (contract-call? .realbit-shares transfer-shares 
           amount seller tx-sender))
    
    ;; Update listing status
    (map-set share-listings
      { property-id: property-id, seller: seller }
      (merge listing { status: "completed" }))
    
    ;; Release payment to seller
    (try! (as-contract (stx-transfer? total-cost tx-sender seller)))
    
    (ok true)))

(define-public (cancel-listing
  (property-id uint))
  (let ((listing (unwrap! (map-get? share-listings 
                { property-id: property-id, seller: tx-sender })
                err-listing-not-found)))
    (asserts! (is-eq (get status listing) "active") err-unauthorized)
    (map-set share-listings
      { property-id: property-id, seller: tx-sender }
      (merge listing { status: "cancelled" }))
    (ok true)))

;; Read only functions
(define-read-only (get-listing 
  (property-id uint)
  (seller principal))
  (map-get? share-listings { property-id: property-id, seller: seller }))

(define-read-only (get-escrow-balance
  (buyer principal)
  (property-id uint)
  (seller principal))
  (map-get? escrow-balance 
    { buyer: buyer, 
      listing-id: {property-id: property-id, seller: seller} }))
