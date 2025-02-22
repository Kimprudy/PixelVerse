;; PixelVerse Protocol - Dynamic NFT Ecosystem
;; Implements market-driven minting mechanics with real-time adjustments

;; Constants
(define-constant admin-address tx-sender)
(define-constant err-admin-restricted (err u100))
(define-constant err-unauthorized-holder (err u101))
(define-constant err-pixel-not-found (err u102))
(define-constant err-balance-too-low (err u103))
(define-constant err-creation-cap-reached (err u104))
(define-constant err-invalid-caller (err u105))
(define-constant err-operation-blocked (err u106))
(define-constant err-creation-timeout (err u107))
(define-constant err-price-threshold (err u108))
(define-constant err-invalid-pixel-id (err u109))
(define-constant err-invalid-metadata (err u110))
(define-constant err-invalid-value (err u111))

;; Data Variables
(define-data-var pixel-count uint u0)
(define-data-var creation-cost uint u100000000) ;; 100 STX
(define-data-var collection-limit uint u1000)
(define-data-var protocol-frozen bool false)

;; Ecosystem Metrics
(define-data-var base-price uint u100000000) ;; 100 STX
(define-data-var trading-volume uint u0)
(define-data-var unique-collectors uint u0)
(define-data-var previous-creation-block uint u0)
(define-data-var creation-delay uint u100) ;; blocks between creations
(define-data-var ecosystem-factor uint u100) ;; base 100 for percentage

;; Validation Functions
(define-private (is-valid-pixel-id (pixel-id uint))
    (and 
        (<= pixel-id (var-get pixel-count))
        (is-some (map-get? pixel-registry {pixel-id: pixel-id}))
    )
)

(define-private (is-valid-metadata (metadata (string-ascii 256)))
    (and
        (not (is-eq metadata ""))
        (<= (len metadata) u256)
    )
)

(define-private (is-valid-amount (amount uint))
    (> amount u0)
)

;; Dynamic Creation Controls
(define-map collector-stats 
    principal 
    {last-action: uint, action-count: uint})

(define-map market-history
    uint  ;; block height
    {rate: uint, turnover: uint})

;; NFT Registry Data Maps
(define-map pixel-registry 
    {pixel-id: uint} 
    {collector: principal, tier: uint, art-uri: (string-ascii 256)})

(define-map collector-balance principal uint)

;; Market Analysis Functions
(define-private (calculate-ecosystem-factor)
    (let
        (
            (adoption-rate (/ (* (var-get unique-collectors) u100) (var-get collection-limit)))
            (volume-impact (/ (var-get trading-volume) (var-get base-price)))
            (base-factor u100)
        )
        (+ base-factor (+ adoption-rate (/ volume-impact u100)))
    )
)

(define-private (update-ecosystem-metrics (price uint))
    (begin
        (if (< price (var-get base-price))
            (var-set base-price price)
            true
        )
        (var-set trading-volume (+ (var-get trading-volume) price))
        (var-set ecosystem-factor (calculate-ecosystem-factor))
        (map-set market-history
            block-height
            {rate: price, turnover: (var-get trading-volume)})
    )
)

(define-private (update-collector-stats (collector principal))
    (let
        (
            (current-stats (default-to 
                {last-action: u0, action-count: u0} 
                (map-get? collector-stats collector)))
        )
        (map-set collector-stats
            collector
            {
                last-action: block-height,
                action-count: (+ (get action-count current-stats) u1)
            }
        )
    )
)

;; Enhanced Creation Function
(define-public (create-pixel (art-uri (string-ascii 256)))
    (let 
        (
            (pixel-id (var-get pixel-count))
            (current-balance (default-to u0 (map-get? collector-balance tx-sender)))
            (dynamic-creation-limit (/ (* (var-get collection-limit) (var-get ecosystem-factor)) u100))
        )
        ;; Input validation
        (asserts! (is-valid-metadata art-uri) err-invalid-metadata)
        
        ;; Protocol state validation
        (asserts! (not (var-get protocol-frozen)) err-operation-blocked)
        (asserts! (< pixel-id dynamic-creation-limit) err-creation-cap-reached)
        (asserts! (>= (- block-height (var-get previous-creation-block)) (var-get creation-delay)) err-creation-timeout)
        
        ;; Process payment
        (try! (stx-transfer? (var-get creation-cost) tx-sender admin-address))
        
        ;; Update ecosystem metrics
        (update-ecosystem-metrics (var-get creation-cost))
        
        ;; Register pixel with validated data
        (map-set pixel-registry 
            {pixel-id: pixel-id}
            {collector: tx-sender, 
             tier: u1,
             art-uri: art-uri})
             
        ;; Update collector metrics
        (if (is-eq current-balance u0)
            (var-set unique-collectors (+ (var-get unique-collectors) u1))
            true
        )
        
        ;; Update collector balance
        (map-set collector-balance 
            tx-sender 
            (+ current-balance u1))
            
        ;; Update creation timing
        (var-set previous-creation-block block-height)
        
        ;; Increment total count
        (var-set pixel-count (+ pixel-id u1))
        (ok pixel-id)
    )
)

;; Enhanced Transfer Function
(define-public (transfer-pixel (pixel-id uint) (recipient principal))
    (let
        (
            (pixel (unwrap! (map-get? pixel-registry {pixel-id: pixel-id}) err-pixel-not-found))
            (sender-balance (default-to u0 (map-get? collector-balance tx-sender)))
            (recipient-balance (default-to u0 (map-get? collector-balance recipient)))
        )
        ;; Input validation
        (asserts! (is-valid-pixel-id pixel-id) err-invalid-pixel-id)
        
        ;; Protocol state validation
        (asserts! (not (var-get protocol-frozen)) err-operation-blocked)
        (asserts! (is-eq (get collector pixel) tx-sender) err-unauthorized-holder)
        
        ;; Update collector metrics
        (if (is-eq recipient-balance u0)
            (var-set unique-collectors (+ (var-get unique-collectors) u1))
            true
        )
        (if (is-eq (- sender-balance u1) u0)
            (var-set unique-collectors (- (var-get unique-collectors) u1))
            true
        )
        
        ;; Update pixel owner with validated pixel-id
        (map-set pixel-registry
            {pixel-id: pixel-id}
            {collector: recipient,
             tier: (get tier pixel),
             art-uri: (get art-uri pixel)})
             
        ;; Update balances
        (map-set collector-balance tx-sender (- sender-balance u1))
        (map-set collector-balance recipient (+ recipient-balance u1))
        
        ;; Update collector stats
        (update-collector-stats tx-sender)
        (update-collector-stats recipient)
            
        (ok true)
    )
)

;; Market Metric Getters
(define-read-only (get-ecosystem-metrics)
    (ok {
        base-price: (var-get base-price),
        trading-volume: (var-get trading-volume),
        unique-collectors: (var-get unique-collectors),
        ecosystem-factor: (var-get ecosystem-factor),
        dynamic-creation-limit: (/ (* (var-get collection-limit) (var-get ecosystem-factor)) u100)
    })
)

(define-read-only (get-collector-stats (collector principal))
    (ok (default-to 
        {last-action: u0, action-count: u0}
        (map-get? collector-stats collector)))
)

;; Enhanced Management Functions
(define-public (set-creation-delay (new-delay uint))
    (begin
        (asserts! (is-eq tx-sender admin-address) err-admin-restricted)
        (asserts! (is-valid-amount new-delay) err-invalid-value)
        (var-set creation-delay new-delay)
        (ok true)
    )
)

(define-public (set-base-price (new-base-price uint))
    (begin
        (asserts! (is-eq tx-sender admin-address) err-admin-restricted)
        (asserts! (is-valid-amount new-base-price) err-invalid-value)
        (var-set base-price new-base-price)
        (ok true)
    )
)