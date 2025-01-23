;; //can buy sip10 and stx- assume price of stx and sip10


;; trait is a set of method signatures a contract must implement.
;;  (imp-trait 'STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-trait.sip-trait) 
;;  (use-trait sip-trait 'STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-trait.sip-trait) 
 (use-trait sip-trait .sip-trait.sip-trait) 
;; error constants
(define-constant ERR-UNAUTHORIZED (err u401))
(define-constant ERR-UNAUTHORIZED-TOKEN (err u402))
(define-constant ERR-TRADING-DISABLED (err u1001))
(define-constant DEX-HAS-NOT-ENOUGH-STX (err u1002))
(define-constant ERR-NOT-ENOUGH-STX-BALANCE (err u1003))
(define-constant ERR-NOT-ENOUGH-TOKEN-BALANCE (err u1004))
(define-constant BUY-INFO-ERROR (err u2001))
(define-constant SELL-INFO-ERROR (err u2002))

(define-constant token-supply u100000000) ;; match with the token's supply (6 decimals)
;; -BONDING-DEX-ADDRESS refers to the address of the deployed contract itself
(define-constant BONDING-DEX-ADDRESS (as-contract tx-sender)) ;; one contract per token-.


;; This value sets the target number of STX tokens to be collected by the contract before certain operations,
;;  like redistributing tokens or performing specific financial transactions, are triggered

;; bonding curve config
;;  Once this target is reached, the contract might take special actions, 
;;like distributing fees, stopping operations, or notifying stakeholders.
(define-constant STX_TARGET_AMOUNT u20000000)
;; The purpose is to simulate the presence of STX in the DEX to stabilize the bonding curve at the beginning.
;;virtual amount of STX (Stacks tokens) that is added to the contract's liquidity pool calculation
(define-constant VIRTUAL_STX_VALUE u4000000) ;; 1/5 of STX_TARGET_AMOUNT
;;  Represents a profit or operational fee collected after the bonding curve is successfully completed.
(define-constant COMPLETE_FEE u40000000) ;; 2% of STX_TARGET_AMOUNT

;; FEE AND DEX WALLETS
(define-constant STX_CITY_SWAP_FEE_WALLET 'SP1WRH525WGKZJDCY8FSYASWVNVYB62580QNARMXP);; swap fee (a small fee taken for executing token swaps on the DEX) is sent.
(define-constant STX_CITY_COMPLETE_FEE_WALLET 'SP1JYZFESCWMGPWQR4BJTDZRXTHTXXYFEVJECNTY7);;where the complete fee (e.g., 2% fee defined earlier) is sent.
;;It could be used to distribute rewards to contract owners, developers, or participants.

(define-constant AMM_WALLET 'SP2BN9JN4WEG02QYVX5Y21VMB2JWV3W0KNHPH9R4P);; interacts with the AMM system
(define-constant BURN_ADDRESS 'SP000000000000000000002Q6VF78) ;; burn mainnet

(define-constant deployer tx-sender)
(define-constant allow-token 'STXWGJQ101N1C1FYHK64TGTHN4793CHVKRW3ZGVV.sip-token);;token contract

;; data vars
(define-data-var tradable bool false);;when this is false, the item is not tradable, and when it's set to true, it means the item can be traded
(define-data-var virtual-stx-amount uint u0);;This variable might represent a virtual amount of STX (Stacks tokens) used in the contract for specific calculations or actions.initialized to u0
(define-data-var token-balance uint u0)
(define-data-var stx-balance uint u0);; uint variable that stores the balance of STX -intialize with 0
(define-data-var burn-percent uint u10);; percentage of tokens that will be burned (removed from circulation) in certain operations.
(define-data-var deployer-percent uint u10);; deployer's share in some transaction or operation
(define-public (buy (token-trait <sip-trait>) (stx-amount uint) ) 
  (begin
    (asserts! (var-get tradable) ERR-TRADING-DISABLED)
    (asserts! (> stx-amount u0) ERR-NOT-ENOUGH-STX-BALANCE)
    (asserts! (is-eq allow-token (contract-of token-trait)) ERR-UNAUTHORIZED-TOKEN );;Ensures that the token being bought is the authorized token
    (let (
      (buy-info (unwrap! (get-buyable-tokens stx-amount) BUY-INFO-ERROR))
      (stx-fee (get fee buy-info))
      (stx-after-fee (get stx-buy buy-info))
      (tokens-out (get buyable-token buy-info))
      (new-token-balance (get new-token-balance buy-info))
      (recipient tx-sender)
      (new-stx-balance (+ (var-get stx-balance) stx-after-fee))
      
    )
      ;; user send stx fee to stxcity
      (try! (stx-transfer? stx-fee tx-sender STX_CITY_SWAP_FEE_WALLET))
      ;; user send stx to dex
      (try! (stx-transfer? stx-after-fee tx-sender (as-contract tx-sender)))
      ;; dex send token to user
      (try! (as-contract (contract-call? token-trait transfer tokens-out tx-sender recipient none)))
      (var-set stx-balance new-stx-balance )
      (var-set token-balance new-token-balance)
      (if (>= new-stx-balance  STX_TARGET_AMOUNT)
        (begin
          (let (
            (contract-token-balance (var-get token-balance))
            (burn-percent-val (var-get burn-percent) )
            (burn-amount (/ (* contract-token-balance burn-percent-val) u100)) ;; burn tokens for a deflationary boost after the bonding curve completed
            (remain-tokens (- contract-token-balance burn-amount))
            (remain-stx (- (var-get stx-balance) COMPLETE_FEE))
            (deployer-amount (/ (* burn-amount (var-get deployer-percent)) u100)) ;; deployer-amount is based on the burn amount
            (burn-after-deployer-amount (- burn-amount deployer-amount))
          )
            ;; burn tokens
            (try! (as-contract (contract-call? token-trait transfer burn-after-deployer-amount tx-sender BURN_ADDRESS none)))
            ;; send to deployer
            (try! (as-contract (contract-call? token-trait transfer deployer-amount tx-sender deployer none)))
            ;; send to AMM's address
            (try! (as-contract (contract-call? token-trait transfer remain-tokens tx-sender AMM_WALLET none)))
            (try! (as-contract (stx-transfer? remain-stx tx-sender AMM_WALLET)))
            ;; send fee
            (try! (as-contract (stx-transfer? COMPLETE_FEE tx-sender STX_CITY_COMPLETE_FEE_WALLET)))
            ;; update global variables
            (var-set tradable false)
            (var-set stx-balance u0)
            (var-set token-balance u0) 
            (print {tokens-receive: tokens-out, stx-fee: stx-fee, final-fee: COMPLETE_FEE, tokens-burn: burn-amount, tokens-to-dex: remain-tokens, stx-to-dex: remain-stx,
                current-stx-balance: (var-get stx-balance), token-balance: (var-get token-balance), tradable: (var-get tradable) })    
            (ok tokens-out)
          )
        )
        (begin 
          (print {tokens-receive: tokens-out, stx-fee: stx-fee, current-stx-balance: (var-get stx-balance), token-balance: (var-get token-balance), tradable: (var-get tradable) })  
          (ok tokens-out)
        )
      )
    )
  )
)
(define-public (sell (token-trait <sip-trait>) (tokens-in uint) ) ;; swap out for virtual trading
  (begin
    (asserts! (var-get tradable) ERR-TRADING-DISABLED)
    (asserts! (> tokens-in u0) ERR-NOT-ENOUGH-TOKEN-BALANCE)
    (asserts! (is-eq allow-token (contract-of token-trait)) ERR-UNAUTHORIZED-TOKEN )
    (let (
      (sell-info (unwrap! (get-sellable-stx tokens-in) SELL-INFO-ERROR))
      (stx-fee (get fee sell-info))
      (stx-receive (get stx-receive sell-info))
      (current-stx-balance (get current-stx-balance sell-info))
      (stx-out (get stx-out sell-info))
      (new-token-balance (get new-token-balance sell-info))
      (recipient tx-sender)
    )
      (asserts! (>= current-stx-balance stx-receive) DEX-HAS-NOT-ENOUGH-STX)
      (asserts! (is-eq contract-caller recipient) ERR-UNAUTHORIZED)
      ;; user send token to dex
      (try! (contract-call? token-trait transfer tokens-in tx-sender BONDING-DEX-ADDRESS none))
      ;; dex transfer stx to user and stxcity
      (try! (as-contract (stx-transfer? stx-receive tx-sender recipient)))
      (try! (as-contract (stx-transfer? stx-fee tx-sender STX_CITY_SWAP_FEE_WALLET)))
      ;; update global variable
      (var-set stx-balance (- (var-get stx-balance) stx-out))
      (var-set token-balance new-token-balance)
      (print {stx-receive: stx-receive, stx-fee: stx-fee, current-stx-balance: (var-get stx-balance), token-balance: (var-get token-balance), tradable: (var-get tradable) })
      (ok stx-receive)
    )
  )
)
;; stx -> token. Estimate the number of token you can receive with a stx amount
(define-read-only (get-buyable-tokens (stx-amount uint)) 
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
      (recommend-stx-amount (- STX_TARGET_AMOUNT (var-get stx-balance) ))
      (recommend-stx-amount-after-fee (/ (* recommend-stx-amount u103) u100)) ;; 3% (including 2% fee)
  )
   (ok  {fee: stx-fee, buyable-token: tokens-out, stx-buy: stx-after-fee, 
        new-token-balance: new-token-balance, stx-balance: (var-get stx-balance), 
      recommend-stx-amount: recommend-stx-amount-after-fee, token-balance: (var-get token-balance) } ) ))  

;; token -> stx. Estimate the number of stx you can receive with a token amount
(define-read-only (get-sellable-stx (token-amount uint)) 
  (let 
      (
      (tokens-in token-amount)
      (current-stx-balance (+ (var-get stx-balance) (var-get virtual-stx-amount)))
      (current-token-balance (var-get token-balance))
      (k (* current-token-balance current-stx-balance )) ;; k = x*y 
      (new-token-balance (+ current-token-balance tokens-in))
      (new-stx-balance (/ k new-token-balance)) ;; y' = k / x'
      (stx-out (- (- current-stx-balance new-stx-balance) u1)) ;; prevent the round number
      (stx-fee (/ (* stx-out u2) u100)) ;; 2% fee
      (stx-receive (- stx-out stx-fee))
  )
   (ok  {fee: stx-fee, 
        current-stx-balance: current-stx-balance,
        receivable-stx: stx-receive, 
        stx-receive: stx-receive,
        new-token-balance: new-token-balance, 
        stx-out: stx-out,
        stx-balance: (var-get stx-balance), 
        token-balance: (var-get token-balance) } ) ))  

(define-read-only (get-tradable) 
  (ok (var-get tradable))
)

;; initialize contract based on token's details
(begin
  (var-set virtual-stx-amount VIRTUAL_STX_VALUE)
  
    (var-set token-balance u975609756097560)
    (var-set stx-balance u10000000)
  (var-set tradable true)
  (var-set burn-percent u20)
  (var-set deployer-percent u10) ;; based on the burn-amount. It's about ~0.1 to 0.5% supply
  (try! (stx-transfer? u500000 tx-sender 'SP1WG62TA0D3K980WGSTZ0QA071TZD4ZXNKP0FQZ7))
  (ok true)
)
