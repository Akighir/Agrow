;; Urban Farming Collective Contract
;; Enables fractional ownership of vertical farms with automated crop sales revenue distribution

;; Constants
(define-constant FARM_COORDINATOR tx-sender)
(define-constant ERR_UNAUTHORIZED_GROWER (err u1100))
(define-constant ERR_INSUFFICIENT_PLOTS (err u1101))
(define-constant ERR_FARM_NOT_FOUND (err u1102))
(define-constant ERR_INVALID_AMOUNT (err u1103))
(define-constant ERR_HARVEST_NOT_FOUND (err u1104))
(define-constant ERR_ALREADY_VOTED (err u1105))

;; Data Variables
(define-data-var next-farm-id uint u1)
(define-data-var next-harvest-id uint u1)

;; Farm Structure
(define-map vertical-farms 
  { farm-id: uint }
  {
    farm-location: (string-ascii 100),
    total-plots: uint,
    plot-price: uint,
    crop-revenue: uint,
    head-agriculturist: principal,
    is-growing: bool
  }
)

;; Plot Ownership
(define-map grower-plots
  { farm-id: uint, grower: principal }
  { plots: uint }
)

;; Harvest Decisions
(define-map crop-harvests
  { harvest-id: uint }
  {
    farm-id: uint,
    crop-type: (string-ascii 100),
    growing-method: (string-ascii 500),
    proposer: principal,
    support-votes: uint,
    oppose-votes: uint,
    harvest-deadline: uint,
    approved: bool
  }
)

;; Voting Records
(define-map harvest-votes
  { harvest-id: uint, voter: principal }
  { voted: bool, supports: bool }
)

;; Revenue Distribution Tracking
(define-map sales-claims
  { farm-id: uint, grower: principal, cycle: uint }
  { claimed: bool }
)

;; Farm Establishment
(define-public (establish-farm 
  (farm-location (string-ascii 100))
  (total-plots uint)
  (plot-price uint)
  (crop-revenue uint)
  (head-agriculturist principal))
  (let ((farm-id (var-get next-farm-id)))
    (asserts! (is-eq tx-sender FARM_COORDINATOR) ERR_UNAUTHORIZED_GROWER)
    (asserts! (> total-plots u0) ERR_INVALID_AMOUNT)
    (asserts! (> plot-price u0) ERR_INVALID_AMOUNT)
    
    (map-set vertical-farms
      { farm-id: farm-id }
      {
        farm-location: farm-location,
        total-plots: total-plots,
        plot-price: plot-price,
        crop-revenue: crop-revenue,
        head-agriculturist: head-agriculturist,
        is-growing: true
      }
    )
    
    (var-set next-farm-id (+ farm-id u1))
    (ok farm-id)
  )
)

;; Purchase Farm Plots
(define-public (lease-plots (farm-id uint) (plot-amount uint))
  (let (
    (farm (unwrap! (map-get? vertical-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (total-cost (* plot-amount (get plot-price farm)))
    (current-plots (default-to u0 (get plots (map-get? grower-plots { farm-id: farm-id, grower: tx-sender }))))
  )
    (asserts! (get is-growing farm) ERR_FARM_NOT_FOUND)
    (asserts! (> plot-amount u0) ERR_INVALID_AMOUNT)
    
    (map-set grower-plots
      { farm-id: farm-id, grower: tx-sender }
      { plots: (+ current-plots plot-amount) }
    )
    
    (ok plot-amount)
  )
)

;; Distribute Crop Sales Revenue
(define-public (distribute-sales (farm-id uint) (cycle uint))
  (let (
    (farm (unwrap! (map-get? vertical-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (crop-revenue (get crop-revenue farm))
    (total-plots (get total-plots farm))
  )
    (asserts! (is-eq tx-sender (get head-agriculturist farm)) ERR_UNAUTHORIZED_GROWER)
    (asserts! (get is-growing farm) ERR_FARM_NOT_FOUND)
    
    (ok true)
  )
)

;; Claim Sales Revenue Share
(define-public (claim-sales (farm-id uint) (cycle uint))
  (let (
    (farm (unwrap! (map-get? vertical-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (plot-balance (default-to u0 (get plots (map-get? grower-plots { farm-id: farm-id, grower: tx-sender }))))
    (already-claimed (default-to false (get claimed (map-get? sales-claims { farm-id: farm-id, grower: tx-sender, cycle: cycle }))))
    (crop-revenue (get crop-revenue farm))
    (total-plots (get total-plots farm))
    (sales-share (/ (* crop-revenue plot-balance) total-plots))
  )
    (asserts! (> plot-balance u0) ERR_INSUFFICIENT_PLOTS)
    (asserts! (not already-claimed) ERR_UNAUTHORIZED_GROWER)
    
    (map-set sales-claims
      { farm-id: farm-id, grower: tx-sender, cycle: cycle }
      { claimed: true }
    )
    
    (ok sales-share)
  )
)

;; Create Harvest Proposal
(define-public (create-harvest 
  (farm-id uint)
  (crop-type (string-ascii 100))
  (growing-method (string-ascii 500))
  (voting-period uint))
  (let (
    (harvest-id (var-get next-harvest-id))
    (plot-balance (default-to u0 (get plots (map-get? grower-plots { farm-id: farm-id, grower: tx-sender }))))
    (harvest-deadline (+ block-height voting-period))
  )
    (asserts! (> plot-balance u0) ERR_UNAUTHORIZED_GROWER)
    
    (map-set crop-harvests
      { harvest-id: harvest-id }
      {
        farm-id: farm-id,
        crop-type: crop-type,
        growing-method: growing-method,
        proposer: tx-sender,
        support-votes: u0,
        oppose-votes: u0,
        harvest-deadline: harvest-deadline,
        approved: false
      }
    )
    
    (var-set next-harvest-id (+ harvest-id u1))
    (ok harvest-id)
  )
)

;; Vote on Harvest
(define-public (vote-harvest (harvest-id uint) (supports bool))
  (let (
    (harvest (unwrap! (map-get? crop-harvests { harvest-id: harvest-id }) ERR_HARVEST_NOT_FOUND))
    (farm-id (get farm-id harvest))
    (plot-balance (default-to u0 (get plots (map-get? grower-plots { farm-id: farm-id, grower: tx-sender }))))
    (already-voted (default-to false (get voted (map-get? harvest-votes { harvest-id: harvest-id, voter: tx-sender }))))
    (current-support (get support-votes harvest))
    (current-oppose (get oppose-votes harvest))
  )
    (asserts! (> plot-balance u0) ERR_UNAUTHORIZED_GROWER)
    (asserts! (<= block-height (get harvest-deadline harvest)) ERR_UNAUTHORIZED_GROWER)
    (asserts! (not already-voted) ERR_ALREADY_VOTED)
    
    (map-set harvest-votes
      { harvest-id: harvest-id, voter: tx-sender }
      { voted: true, supports: supports }
    )
    
    (if supports
      (map-set crop-harvests
        { harvest-id: harvest-id }
        (merge harvest { support-votes: (+ current-support plot-balance) })
      )
      (map-set crop-harvests
        { harvest-id: harvest-id }
        (merge harvest { oppose-votes: (+ current-oppose plot-balance) })
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-farm (farm-id uint))
  (map-get? vertical-farms { farm-id: farm-id })
)

(define-read-only (get-plot-balance (farm-id uint) (grower principal))
  (default-to u0 (get plots (map-get? grower-plots { farm-id: farm-id, grower: grower })))
)

(define-read-only (get-harvest (harvest-id uint))
  (map-get? crop-harvests { harvest-id: harvest-id })
)

(define-read-only (calculate-sales-share (farm-id uint) (grower principal))
  (let (
    (farm (unwrap! (map-get? vertical-farms { farm-id: farm-id }) ERR_FARM_NOT_FOUND))
    (plot-balance (default-to u0 (get plots (map-get? grower-plots { farm-id: farm-id, grower: grower }))))
    (crop-revenue (get crop-revenue farm))
    (total-plots (get total-plots farm))
  )
    (if (> plot-balance u0)
      (ok (/ (* crop-revenue plot-balance) total-plots))
      (ok u0)
    )
  )
)