
;; STX-DeoCast
;; <add a description here>


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constants and Error Codes ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-PARAMS (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-CONTRACT-PAUSED (err u105))

;;;;;;;;;;;;;;;;;;
;; Data Storage ;;
;;;;;;;;;;;;;;;;;;

;; Platform State
(define-data-var contract-paused bool false)
(define-data-var platform-fee uint u50) ;; 5% represented as 50/1000
(define-data-var next-video-id uint u0)

;; Access Control Maps
(define-map administrators principal bool)
(define-map content-creators principal bool)
(define-map premium-subscribers 
    principal 
    { subscription-expires: uint }
)

;; Content Storage
(define-map videos 
    { video-id: uint }
    {
        creator: principal,
        title: (string-utf8 256),
        description: (string-utf8 1024),
        content-hash: (buff 32),
        price: uint,
        created-at: uint,
        views: uint,
        revenue: uint,
        is-active: bool
    }
)

;; Revenue Tracking
(define-map creator-revenue principal uint)
(define-map platform-revenue (string-ascii 10) uint)

;;;;;;;;;;;;;;;;
;; Governance ;;
;;;;;;;;;;;;;;;;

;; Proposal tracking
(define-map governance-proposals
    uint 
    {
        title: (string-utf8 256),
        description: (string-utf8 1024),
        proposer: principal,
        votes-for: uint,
        votes-against: uint,
        end-height: uint,
        executed: bool
    }
)

;;;;;;;;;;;;;;;;;;;;
;; Authorization ;;
;;;;;;;;;;;;;;;;;;;;

(define-private (is-admin)
    (default-to false (map-get? administrators tx-sender)))

(define-private (is-creator)
    (default-to false (map-get? content-creators tx-sender)))

(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner))

(define-private (check-admin)
    (ok (asserts! (is-admin) ERR-NOT-AUTHORIZED)))

;;;;;;;;;;;;;;;;;;;;
;; Admin Functions ;;
;;;;;;;;;;;;;;;;;;;;

(define-public (set-platform-fee (new-fee uint))
    (begin
        (try! (check-admin))
        (asserts! (<= new-fee u100) ERR-INVALID-PARAMS)
        (ok (var-set platform-fee new-fee))))

(define-public (toggle-contract-pause)
    (begin
        (try! (check-admin))
        (ok (var-set contract-paused (not (var-get contract-paused))))))

(define-public (add-administrator (admin principal))
    (begin
        (try! (check-admin))
        (asserts! (not (is-eq admin 'SP000000000000000000002Q6VF78)) ERR-INVALID-PARAMS)
        (ok (map-set administrators admin true))))

;;;;;;;;;;;;;;;;;;;;;;;
;; Creator Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

(define-public (register-as-creator)
    (begin
        (asserts! (not (is-creator)) ERR-ALREADY-EXISTS)
        (ok (map-set content-creators tx-sender true))))

(define-public (upload-video (title (string-utf8 256)) 
                           (description (string-utf8 1024)) 
                           (content-hash (buff 32)) 
                           (price uint))
    (let ((video-id (var-get next-video-id)))
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (is-creator) ERR-NOT-AUTHORIZED)
        (asserts! (> (len title) u0) ERR-INVALID-PARAMS)
        (asserts! (> (len description) u0) ERR-INVALID-PARAMS)
        (asserts! (not (is-eq content-hash 0x0000000000000000000000000000000000000000000000000000000000000000)) ERR-INVALID-PARAMS)
        (asserts! (>= price u0) ERR-INVALID-PARAMS)
        (map-set videos
            { video-id: video-id }
            {
                creator: tx-sender,
                title: title,
                description: description,
                content-hash: content-hash,
                price: price,
                created-at: block-height,
                views: u0,
                revenue: u0,
                is-active: true
            }
        )
        (var-set next-video-id (+ video-id u1))
        (ok video-id)))

;;;;;;;;;;;;;;;;;;;;
;; User Functions ;;
;;;;;;;;;;;;;;;;;;;;

(define-public (purchase-video (video-id uint))
    (let ((video (unwrap! (map-get? videos { video-id: video-id }) ERR-NOT-FOUND)))
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (< video-id (var-get next-video-id)) ERR-NOT-FOUND)
        (asserts! (get is-active video) ERR-NOT-FOUND)

        ;; Process payment
        (try! (stx-transfer? (get price video) tx-sender (get creator video)))

        ;; Update revenue tracking
        (map-set videos 
            { video-id: video-id }
            (merge video { 
                revenue: (+ (get revenue video) (get price video)),
                views: (+ (get views video) u1)
            })
        )
        (ok true)))

(define-public (subscribe-premium (duration uint))
    (let ((price (* duration u10000000)) ;; 10 STX per period
          (expiry (+ block-height (* duration u144)))) ;; ~1 day blocks
        (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
        (asserts! (> duration u0) ERR-INVALID-PARAMS)
        (try! (stx-transfer? price tx-sender contract-owner))
        (ok (map-set premium-subscribers 
            tx-sender 
            { subscription-expires: expiry }))))

;;;;;;;;;;;;;;;;;;;;;;;
;; Getter Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-video-details (video-id uint))
    (map-get? videos { video-id: video-id }))

(define-read-only (get-creator-revenue (creator principal))
    (default-to u0 (map-get? creator-revenue creator)))

(define-read-only (is-premium-subscriber (user principal))
    (let ((sub (default-to 
            { subscription-expires: u0 } 
            (map-get? premium-subscribers user))))
        (> (get subscription-expires sub) block-height)))

;;;;;;;;;;;;;;;;
;; Initialize ;;
;;;;;;;;;;;;;;;;

;; Initialize contract owner as first administrator
(map-set administrators contract-owner true)

;; Initialize platform revenue
(map-set platform-revenue "total" u0)
