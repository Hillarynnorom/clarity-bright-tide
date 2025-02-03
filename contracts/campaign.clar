;; Campaign Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-params (err u101))
(define-constant err-campaign-ended (err u102))

;; Data vars
(define-map campaigns
  { campaign-id: uint }
  {
    creator: principal,
    title: (string-utf8 100),
    target: uint,
    deadline: uint,
    raised: uint,
    active: bool
  }
)

(define-data-var campaign-nonce uint u0)

;; Public functions
(define-public (create-campaign (title (string-utf8 100)) (target uint) (deadline uint))
  (let
    (
      (campaign-id (var-get campaign-nonce))
    )
    (asserts! (> deadline block-height) (err u103))
    (asserts! (> target u0) (err u104))
    
    (map-set campaigns
      { campaign-id: campaign-id }
      {
        creator: tx-sender,
        title: title,
        target: target,
        deadline: deadline,
        raised: u0,
        active: true
      }
    )
    
    (var-set campaign-nonce (+ campaign-id u1))
    (ok campaign-id)
  )
)

(define-public (donate (campaign-id uint) (amount uint))
  (let
    (
      (campaign (unwrap! (get-campaign campaign-id) (err u105)))
    )
    (asserts! (get active campaign) (err u106))
    (asserts! (<= block-height (get deadline campaign)) (err u107))
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { raised: (+ (get raised campaign) amount) })
    )
    
    (contract-call? .rewards award-points tx-sender amount)
  )
)

;; Read only functions
(define-read-only (get-campaign (campaign-id uint))
  (ok (map-get? campaigns { campaign-id: campaign-id }))
)
