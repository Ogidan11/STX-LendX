
;; STX-LendX
;; lending-pool.clar

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_INSUFFICIENT_COLLATERAL (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_PAUSED (err u104))
(define-constant ERR_INVALID_RATIO (err u105))
(define-constant ERR_INVALID_RATE (err u106))
(define-constant ERR_LIQUIDATION_FAILED (err u107))

;; Data vars
(define-data-var min-collateral-ratio uint u150) ;; 150% collateralization ratio
(define-data-var liquidation-threshold uint u120) ;; 120% liquidation threshold
(define-data-var interest-rate uint u5) ;; 5% annual interest rate
(define-data-var total-deposits uint u0)
(define-data-var total-borrows uint u0)
(define-data-var paused bool false)
(define-data-var liquidation-fee uint u5) ;; 5% liquidation fee

;; Data maps
(define-map user-deposits { user: principal } { amount: uint, last-update: uint })
(define-map user-borrows { user: principal } { amount: uint, last-update: uint })
(define-map whitelisted-liquidators { user: principal } { active: bool })

;; Read-only functions
(define-read-only (get-deposit (user principal))
  (ok (get amount (default-to {amount: u0, last-update: u0} (map-get? user-deposits {user: user})))))

(define-read-only (get-borrow (user principal))
  (ok (get amount (default-to {amount: u0, last-update: u0} (map-get? user-borrows {user: user})))))

(define-read-only (check-collateral-ratio (user principal) (collateral uint) (debt uint))
  (if (is-eq debt u0)
    (ok true)
    (if (>= (* collateral u100) (* debt (var-get min-collateral-ratio)))
      (ok true)
      (err ERR_INSUFFICIENT_COLLATERAL))))

(define-read-only (calculate-collateral-ratio (collateral uint) (debt uint))
  (if (is-eq debt u0)
    (ok u0)
    (ok (/ (* collateral u100) debt))))

(define-read-only (get-total-deposits)
  (ok (var-get total-deposits)))

(define-read-only (get-total-borrows)
  (ok (var-get total-borrows)))

(define-read-only (is-underwater (user principal))
  (let
    (
      (current-deposit (default-to {amount: u0, last-update: u0} (map-get? user-deposits {user: user})))
      (current-borrow (default-to {amount: u0, last-update: u0} (map-get? user-borrows {user: user})))
      (collateral (get amount current-deposit))
      (debt (get amount current-borrow))
    )
    (if (is-eq debt u0)
      (ok false)
      (ok (< (* collateral u100) (* debt (var-get liquidation-threshold)))))))



;; Events
(define-private (deposit-event (user principal) (amount uint))
  (print {event: "deposit", user: user, amount: amount}))

(define-private (withdraw-event (user principal) (amount uint))
  (print {event: "withdraw", user: user, amount: amount}))

(define-private (borrow-event (user principal) (amount uint))
  (print {event: "borrow", user: user, amount: amount}))

(define-private (repay-event (user principal) (amount uint))
  (print {event: "repay", user: user, amount: amount}))

(define-private (liquidation-event (liquidator principal) (borrower principal) (amount uint) (fee uint))
  (print {event: "liquidation", liquidator: liquidator, borrower: borrower, amount: amount, fee: fee}))

(define-private (interest-accrued-event (user principal) (amount uint))
  (print {event: "interest-accrued", user: user, amount: amount}))

;; Public functions
(define-public (deposit (amount uint))
  (let 
    (
      (sender tx-sender)
      (current-deposit (default-to {amount: u0, last-update: u0} (map-get? user-deposits {user: sender})))
    )
    (asserts! (not (var-get paused)) ERR_PAUSED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount sender (as-contract tx-sender)))
    (map-set user-deposits 
      {user: sender} 
      {
        amount: (+ (get amount current-deposit) amount), 
        last-update: stacks-block-height
      }
    )
    (var-set total-deposits (+ (var-get total-deposits) amount))
    (deposit-event sender amount)
    (ok amount)
  )
)

(define-public (withdraw (amount uint))
  (let
    (
      (sender tx-sender)
      (current-deposit (default-to {amount: u0, last-update: u0} (map-get? user-deposits {user: sender})))
      (current-borrow (default-to {amount: u0, last-update: u0} (map-get? user-borrows {user: sender})))
    )
    (asserts! (not (var-get paused)) ERR_PAUSED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= (get amount current-deposit) amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (is-ok (check-collateral-ratio sender (- (get amount current-deposit) amount) (get amount current-borrow))) ERR_INSUFFICIENT_COLLATERAL)
    (try! (as-contract (stx-transfer? amount tx-sender sender)))
    (map-set user-deposits 
      {user: sender} 
      {
        amount: (- (get amount current-deposit) amount), 
        last-update: stacks-block-height
      }
    )
    (var-set total-deposits (- (var-get total-deposits) amount))
    (withdraw-event sender amount)
    (ok amount)
  )
)
