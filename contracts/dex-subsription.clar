;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-subscribed (err u102))
(define-constant err-not-subscribed (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-fee (err u105))
(define-constant err-invalid-hash (err u106))
(define-constant subscription-duration u2592000) ;; 30 days in seconds

;; Data variables
(define-data-var next-creator-id uint u1)
(define-data-var next-subscription-id uint u0)

;; Maps
(define-map creators uint {
    address: principal,
    subscription-fee: uint,
    content-hash: (string-ascii 64)
})

(define-map subscriptions { subscriber: principal, creator-id: uint } { expiration: uint, auto-renew: bool })

;; Helper functions
(define-private (creator-exists (creator-id uint))
    (is-some (map-get? creators creator-id)))

(define-private (get-subscription (subscriber principal) (creator-id uint))
    (map-get? subscriptions { subscriber: subscriber, creator-id: creator-id }))

;; Read-only functions
(define-read-only (get-creator-details (creator-id uint))
    (match (map-get? creators creator-id)
        creator (ok creator)
        (err err-not-found)))

(define-read-only (get-subscription-status (subscriber principal) (creator-id uint))
    (match (get-subscription subscriber creator-id)
        subscription (ok subscription)
        (err err-not-subscribed)))

(define-read-only (get-total-subscriptions)
    (var-get next-subscription-id))

;; Public functions
(define-public (register-creator (subscription-fee uint) (content-hash (string-ascii 64)))
    (begin
        ;; Validate subscription fee is greater than 0
        (asserts! (> subscription-fee u0) err-invalid-fee)
        ;; Validate content-hash length (should be 64 characters)
        (asserts! (is-eq (len content-hash) u64) err-invalid-hash)

        ;; Proceed with registration
        (let ((new-id (var-get next-creator-id)))
            (map-set creators new-id
                { 
                    address: tx-sender,
                    subscription-fee: subscription-fee,
                    content-hash: content-hash
                })
            (var-set next-creator-id (+ new-id u1))
            (ok new-id))))

(define-public (update-content (creator-id uint) (new-content-hash (string-ascii 64)))
  (begin
    ;; Check if creator exists
    (if (creator-exists creator-id)
        (match (map-get? creators creator-id)
          creator 
            (begin
              (asserts! (is-eq (get address creator) tx-sender) (err err-owner-only))
              (map-set creators creator-id 
                (merge creator { content-hash: new-content-hash }))
              (ok creator-id))  ;; Return the creator-id after successful update
          (err err-not-found))
        (err err-not-found)
    )
  )
)

(define-public (cancel-subscription (creator-id uint))
  (begin
    ;; Check if creator exists
    (if (creator-exists creator-id)
        ;; Check if subscription exists
        (match (get-subscription tx-sender creator-id)
          subscription 
            (begin
              (var-set next-subscription-id (- (var-get next-subscription-id) u1))
              (map-delete subscriptions { subscriber: tx-sender, creator-id: creator-id })
              (ok (tuple (status "subscription cancelled") (creator-id creator-id))))
          (err err-not-subscribed))
        (err err-not-found))
  )
)

(define-public (renew-subscription (creator-id uint))
  (begin
    ;; Check if creator exists
    (if (creator-exists creator-id)
        ;; Check if subscription exists
        (match (get-subscription tx-sender creator-id)
          subscription
            (begin
              ;; Check if the current block height is past the expiration
              (if (>= block-height (get expiration subscription))
                  (begin
                    ;; Renew the subscription by extending the expiration
                    (map-set subscriptions { subscriber: tx-sender, creator-id: creator-id }
                        { expiration: (+ block-height subscription-duration), auto-renew: (get auto-renew subscription) })
                    (ok (tuple (status "subscription renewed") (creator-id creator-id))))
                  (err err-already-subscribed))  ;; If subscription is still active
            )
          (err err-not-subscribed))
        (err err-not-found))
  )
)

;; Enable auto-renew for a subscription
(define-public (enable-auto-renew (creator-id uint))
  (begin
    ;; Check if creator exists
    (if (creator-exists creator-id)
        ;; Check if subscription exists
        (match (get-subscription tx-sender creator-id)
          subscription
            (begin
              ;; Set auto-renew to true
              (map-set subscriptions { subscriber: tx-sender, creator-id: creator-id }
                  (merge subscription { auto-renew: true }))
              (ok (tuple (status "auto-renew enabled") (creator-id creator-id)))
            )
          (err err-not-subscribed))
        (err err-not-found))
  )
)

;; Disable auto-renew for a subscription
(define-public (disable-auto-renew (creator-id uint))
  (begin
    ;; Check if creator exists
    (if (creator-exists creator-id)
        ;; Check if subscription exists
        (match (get-subscription tx-sender creator-id)
          subscription
            (begin
              ;; Set auto-renew to false
              (map-set subscriptions { subscriber: tx-sender, creator-id: creator-id }
                  (merge subscription { auto-renew: false }))
              (ok (tuple (status "auto-renew disabled") (creator-id creator-id)))
            )
          (err err-not-subscribed))
        (err err-not-found))
  )
)
