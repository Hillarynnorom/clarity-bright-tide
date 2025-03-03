;; Rewards Contract

;; Constants
(define-constant bronze-threshold u1000)
(define-constant silver-threshold u5000)
(define-constant gold-threshold u10000)

;; NFT definitions
(define-non-fungible-token donor-badge uint)

;; Data vars
(define-map donor-points
  { donor: principal }
  { 
    points: uint,
    current-badge: (optional uint),
    total-donated: uint
  }
)

(define-map badge-metadata
  { badge-id: uint }
  {
    badge-type: uint,
    issued-at: uint,
    donor: principal
  }
)

(define-data-var badge-nonce uint u0)

;; Public functions
(define-public (award-points (donor principal) (amount uint))
  (let
    (
      (current-data (default-to { points: u0, current-badge: none, total-donated: u0 }
        (map-get? donor-points { donor: donor })))
      (new-points (+ (get points current-data) amount))
      (new-total (+ (get total-donated current-data) amount))
    )
    
    (map-set donor-points
      { donor: donor }
      { 
        points: new-points,
        current-badge: (get current-badge current-data),
        total-donated: new-total
      }
    )
    
    (match (check-badge-eligibility new-points)
      badge-type (mint-badge donor badge-type)
      false (ok false)
    )
  )
)

;; Internal functions
(define-private (check-badge-eligibility (points uint))
  (if (>= points gold-threshold)
      (some u3)
      (if (>= points silver-threshold)
          (some u2)
          (if (>= points bronze-threshold)
              (some u1)
              none
          )
      )
  )
)

(define-private (mint-badge (recipient principal) (badge-type uint))
  (let
    (
      (badge-id (var-get badge-nonce))
    )
    (try! (nft-mint? donor-badge badge-id recipient))
    
    (map-set badge-metadata
      { badge-id: badge-id }
      {
        badge-type: badge-type,
        issued-at: block-height,
        donor: recipient
      }
    )
    
    (map-set donor-points
      { donor: recipient }
      (merge (unwrap-panic (map-get? donor-points { donor: recipient }))
        { current-badge: (some badge-id) })
    )
    
    (var-set badge-nonce (+ badge-id u1))
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-points (donor principal))
  (ok (map-get? donor-points { donor: donor }))
)

(define-read-only (get-badge-info (badge-id uint))
  (ok (map-get? badge-metadata { badge-id: badge-id }))
)
