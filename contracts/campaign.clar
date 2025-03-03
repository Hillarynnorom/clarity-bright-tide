;; Campaign Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-params (err u101))
(define-constant err-campaign-ended (err u102))
(define-constant err-unauthorized (err u108))
(define-constant err-insufficient-funds (err u109))
(define-constant err-reentrancy (err u110))

;; Data vars
(define-data-var is-busy bool false)

(define-map campaigns
  { campaign-id: uint }
  {
    creator: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    target: uint,
    deadline: uint,
    raised: uint,
    active: bool,
    funds-withdrawn: bool
  }
)

(define-data-var campaign-nonce uint u0)

;; Events
(define-data-var last-event-id uint u0)

(define-map events 
  { event-id: uint }
  {
    event-type: (string-utf8 20),
    campaign-id: uint,
    data: (optional (string-utf8 50))
  }
)

;; Reentrancy protection
(define-private (begin-atomic)
  (if (var-get is-busy)
      (err err-reentrancy)
      (ok (var-set is-busy true))))

(define-private (end-atomic)
  (var-set is-busy false)
  (ok true))

;; Public functions
(define-public (create-campaign (title (string-utf8 100)) (description (string-utf8 500)) (target uint) (deadline uint))
  (let
    (
      (campaign-id (var-get campaign-nonce))
    )
    (asserts! (> deadline block-height) (err u103))
    (asserts! (> target u0) (err u104))
    (asserts! (not (is-eq description "")) (err u111))
    
    (map-set campaigns
      { campaign-id: campaign-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        target: target,
        deadline: deadline,
        raised: u0,
        active: true,
        funds-withdrawn: false
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
    (try! (begin-atomic))
    (asserts! (get active campaign) (err u106))
    (asserts! (<= block-height (get deadline campaign)) (err u107))
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { raised: (+ (get raised campaign) amount) })
    )
    
    (try! (contract-call? .rewards award-points tx-sender amount))
    (try! (end-atomic))
    (ok true)
  )
)

(define-public (withdraw-funds (campaign-id uint))
  (let
    (
      (campaign (unwrap! (get-campaign campaign-id) (err u105)))
    )
    (try! (begin-atomic))
    (asserts! (is-eq (get creator campaign) tx-sender) err-unauthorized)
    (asserts! (not (get funds-withdrawn campaign)) err-unauthorized)
    (asserts! (>= block-height (get deadline campaign)) err-invalid-params)
    
    (try! (as-contract (stx-transfer? (get raised campaign) (as-contract tx-sender) (get creator campaign))))
    
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { funds-withdrawn: true, active: false })
    )
    (try! (end-atomic))
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-campaign (campaign-id uint))
  (ok (map-get? campaigns { campaign-id: campaign-id }))
)

(define-read-only (get-campaign-status (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u105)))
    )
    (ok {
      active: (get active campaign),
      target-reached: (>= (get raised campaign) (get target campaign)),
      deadline-passed: (>= block-height (get deadline campaign)),
      funds-withdrawn: (get funds-withdrawn campaign)
    })
  )
)
