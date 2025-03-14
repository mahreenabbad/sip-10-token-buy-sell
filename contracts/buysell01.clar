(use-trait sip-trait .sip-trait.sip-trait)

;; Error constants
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-UNAUTHORIZED-TOKEN (err u402))
(define-constant DEX-HAS-NOT-ENOUGH-STX (err u1002))
(define-constant ERR-NOT-ENOUGH-TOKEN-BALANCE (err u1004))
(define-constant BUY-INFO-ERROR (err u2001))
(define-constant SELL-INFO-ERROR (err u2002))
(define-constant ERR-TRANSFER-FAILED (err u3001))

;; (define-constant token-supply u100000000) ;; match with the token's supply (6 decimals), serves as a reference for calculations involving the token.
(define-constant FEE_WALLET 'STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV) ;; Swap fee wallet address
(define-constant allow-token 'STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-token) ;; Authorized token contract

;; Data variables
(define-data-var virtual-stx-amount uint u0)
(define-data-var token-balance uint u0)
(define-data-var stx-balance uint u0)

;; Allows a user to purchase tokens from the contract by sending STX or another SIP-10 token
(define-public (buy (token-trait <sip-trait>) (amount uint) (pay-with-stx bool)) 
  (begin
    (asserts! (> amount u0) ERR-NOT-ENOUGH-TOKEN-BALANCE)
    (asserts! (is-eq allow-token (contract-of token-trait)) ERR-UNAUTHORIZED-TOKEN)
    
    (let (
      (buy-info (unwrap! (get-buyable-tokens amount pay-with-stx) BUY-INFO-ERROR))
      (fee (get fee buy-info))
      (tokens-out (get buyable-token buy-info))
      (new-token-balance (get new-token-balance buy-info))
      (new-stx-balance (+ (var-get stx-balance) (if pay-with-stx (get stx-buy buy-info) u0)))
      (recipient tx-sender)
    )
      (if pay-with-stx
        (begin
          ;; Handle payment with STX
          (try! (stx-transfer? fee tx-sender FEE_WALLET)) ;; Fee transfer to wallet
          (try! (stx-transfer? (- amount fee) tx-sender (as-contract tx-sender))) ;; STX transfer to contract
        )
        (begin
          ;; Handle payment with SIP-10 token
         (asserts! (is-ok (contract-call? token-trait transfer amount tx-sender (as-contract tx-sender) none)) ERR-TRANSFER-FAILED) ;; Transfer SIP-10 token to contract
        )
      ) 
      ;; Transfer tokens to the buyer- token-trait transfer from the contract to the recipient
      (asserts! (is-ok (as-contract (contract-call? token-trait transfer tokens-out (as-contract tx-sender) recipient none))) ERR-TRANSFER-FAILED)
      ;; Update balances
      (var-set token-balance new-token-balance)
      (var-set stx-balance new-stx-balance)
    )
  )
)

;; Allows a user to sell tokens to the contract for STX or another SIP-10 token
;;only an authorized token contract is used for operations like buy or sell
(define-public (sell (token-trait <sip-trait>) (tokens-in uint) (pay-with-stx bool)) 
  (begin
    (asserts! (> tokens-in u0) ERR-NOT-ENOUGH-TOKEN-BALANCE)
    ;; (asserts! (is-contract-of? token-trait) ERR-UNAUTHORIZED-TOKEN)

    (asserts! (is-eq allow-token (contract-of token-trait)) ERR-UNAUTHORIZED-TOKEN)
    
    (let (
      (sell-info (unwrap! (get-sellable-tokens tokens-in pay-with-stx) SELL-INFO-ERROR))
      (fee (get fee sell-info))
      (stx-receive (get stx-receive sell-info))
      (current-stx-balance (get current-stx-balance sell-info))
      (stx-out (get stx-out sell-info))
      (new-token-balance (get new-token-balance sell-info))
      (recipient tx-sender)
    )
      (asserts! (>= current-stx-balance stx-receive) DEX-HAS-NOT-ENOUGH-STX)
      (asserts! (is-eq contract-caller recipient) ERR-UNAUTHORIZED)
      
      ;; User sends token to the contract
      (asserts! (is-eq (contract-call? token-trait transfer tokens-in tx-sender (as-contract tx-sender) none)) ERR-TRANSFER-FAILED)
      
      ;; Handle payment type (STX or SIP-10)
      (if pay-with-stx
        (begin
          ;; STX payment to user and fee to wallet
          (try! (stx-transfer? stx-receive tx-sender recipient))
          (try! (stx-transfer? fee tx-sender FEE_WALLET))
        )
        (begin
          ;; SIP-10 payment to user
          (asserts! (is-eq (contract-call? token-trait transfer stx-receive tx-sender recipient none)) ERR-TRANSFER-FAILED)
        )
      )
      
      ;; Update global variables
      (var-set stx-balance (- (var-get stx-balance) stx-out))
      (var-set token-balance new-token-balance)
      (print {stx-receive: stx-receive, fee: fee, token-balance: (var-get token-balance)})
      (ok stx-receive)
    )
  )
)

;; Estimate the number of tokens you can receive with a given STX amount
(define-read-only (get-buyable-tokens (stx-amount uint) (pay-with-stx bool)) 
  (let 
      (
      (current-stx-balance (+ (var-get stx-balance) (var-get virtual-stx-amount)))
      (current-token-balance (var-get token-balance))
      (stx-fee (/ (* stx-amount u2) u100)) ;; 2% fee
      (stx-after-fee (- stx-amount stx-fee))
      (k (* current-token-balance current-stx-balance )) ;; k = x*y 
      (new-stx-balance (+ current-stx-balance stx-after-fee)) 
      (new-token-balance (/ k new-stx-balance)) ;; x' = k / y'
      (tokens-out (- current-token-balance new-token-balance))
  )
   (ok  {fee: stx-fee, buyable-token: tokens-out, stx-buy: stx-after-fee, 
        new-token-balance: new-token-balance, stx-balance: (var-get stx-balance), 
        token-balance: (var-get token-balance) } ) ))

;; Estimate the number of STX you can receive with a given token amount
(define-read-only (get-sellable-tokens (token-amount uint) (pay-with-stx bool)) 
  (let 
      (
      (tokens-in token-amount)
      (current-stx-balance (+ (var-get stx-balance) (var-get virtual-stx-amount)))
      (current-token-balance (var-get token-balance))
      (k (* current-token-balance current-stx-balance )) ;; k = x*y 
      (new-token-balance (+ current-token-balance tokens-in))
      (new-stx-balance (/ k new-token-balance)) ;; y' = k / x'
      (stx-out (- (- current-stx-balance new-stx-balance) u1)) ;; prevent round number
      (stx-fee (/ (* stx-out u2) u100)) ;; 2% fee
      (stx-receive (- stx-out stx-fee))
  )
   (ok  {fee: stx-fee, 
        receivable-stx: stx-receive, 
        new-token-balance: new-token-balance, 
        stx-balance: (var-get stx-balance), 
        token-balance: (var-get token-balance) } ) ))
