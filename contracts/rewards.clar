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
  { points: uint }
)

(define-data-var badge-nonce uint u0)

;; Public functions
(define-public (award-points (donor principal) (amount uint))
  (let
    (
      (current-points (default-to u0 (get points (map-get? donor-points { donor: donor }))))
      (new-points (+ current-points amount))
    )
    
    (map-set donor-points
      { donor: donor }
      { points: new-points }
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
    (var-set badge-nonce (+ badge-id u1))
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-points (donor principal))
  (ok (default-to u0 (get points (map-get? donor-points { donor: donor }))))
)
