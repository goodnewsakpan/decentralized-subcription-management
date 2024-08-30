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

(define-map subscriptions { subscriber: principal, creator-id: uint } { expiration: uint })

;; Helper functions
(define-private (creator-exists (creator-id uint))
    (is-some (map-get? creators creator-id)))

;; Read-only functions
(define-read-only (get-creator-details (creator-id uint))
    (match (map-get? creators creator-id)
        creator (ok creator)
        (err err-not-found)))

(define-read-only (get-subscription-status (subscriber principal) (creator-id uint))
    (match (map-get? subscriptions { subscriber: subscriber, creator-id: creator-id })
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
  (match (map-get? creators creator-id)
    creator 
      (begin
        (asserts! (is-eq (get address creator) tx-sender) (err err-owner-only))
        (map-set creators creator-id 
          (merge creator { content-hash: new-content-hash }))
        (ok creator-id))  ;; Return the creator-id after successful update
    (err err-not-found)))


(define-public (cancel-subscription (creator-id uint))
    (match (map-get? subscriptions { subscriber: tx-sender, creator-id: creator-id })
        subscription 
            (begin
                (var-set next-subscription-id (- (var-get next-subscription-id) u1))
                (ok (map-delete subscriptions { subscriber: tx-sender, creator-id: creator-id })))
        (err err-not-subscribed)))

