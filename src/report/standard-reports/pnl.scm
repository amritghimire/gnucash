;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pnl.scm : profit-and-loss report 
;;  
;; By Christian Stimming <stimming@tu-harburg.de>
;;
;; This program is free software; you can redistribute it and/or    
;; modify it under the terms of the GNU General Public License as   
;; published by the Free Software Foundation; either version 2 of   
;; the License, or (at your option) any later version.              
;;                                                                  
;; This program is distributed in the hope that it will be useful,  
;; but WITHOUT ANY WARRANTY; without even the implied warranty of   
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    
;; GNU General Public License for more details.                     
;;                                                                  
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, contact:
;;
;; Free Software Foundation           Voice:  +1-617-542-5942
;; 59 Temple Place - Suite 330        Fax:    +1-617-542-2652
;; Boston, MA  02111-1307,  USA       gnu@gnu.org
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-module (gnucash report pnl))

(use-modules (gnucash main)) ;; FIXME: delete after we finish modularizing.
(use-modules (srfi srfi-1))
(use-modules (ice-9 slib))
(use-modules (gnucash gnc-module))

(require 'printf)

(gnc:module-load "gnucash/report/report-system" 0)

;; Profit and loss report. Actually, people in finances might want
;; something different under this name, but they are welcomed to
;; contribute their changes :-)

(define reportname (N_ "Profit And Loss"))

;; define all option's names so that they are properly defined
;; in *one* place.
(define optname-from-date (N_ "From"))
(define optname-to-date (N_ "To"))

(define optname-display-depth (N_ "Account Display Depth"))
(define optname-show-subaccounts (N_ "Always show sub-accounts"))
(define optname-accounts (N_ "Account"))

(define optname-group-accounts (N_ "Group the accounts"))
(define optname-show-parent-balance (N_ "Show balances for parent accounts"))
(define optname-show-parent-total (N_ "Show subtotals"))

(define optname-show-foreign (N_ "Show Foreign Currencies"))
(define optname-report-currency (N_ "Report's currency"))
(define optname-price-source (N_ "Price Source"))
(define optname-show-rates (N_ "Show Exchange Rates"))

;; options generator
(define (pnl-options-generator)
  (let ((options (gnc:new-options)))
    
    ;; date at which to report balance
    (gnc:options-add-date-interval!
     options gnc:pagename-general 
     optname-from-date optname-to-date "a")

    ;; all about currencies
    (gnc:options-add-currency!
     options gnc:pagename-general
     optname-report-currency "b")

    (gnc:options-add-price-source! 
     options gnc:pagename-general
     optname-price-source "c" 'weighted-average)

    ;; accounts to work on
    (gnc:options-add-account-selection! 
     options gnc:pagename-accounts
     optname-display-depth optname-show-subaccounts
     optname-accounts "a" 2
     (lambda ()
       (filter 
        gnc:account-is-inc-exp?
        (gnc:group-get-account-list (gnc:get-current-group))))
     #t)

    ;; with or without grouping
    (gnc:options-add-group-accounts!      
     options gnc:pagename-display optname-group-accounts "b" #t)

    ;; what to show about non-leaf accounts
    (gnc:register-option 
     options
     (gnc:make-simple-boolean-option
      gnc:pagename-display optname-show-parent-balance 
      "c" (N_ "Show balances for parent accounts") #f))

    ;; have a subtotal for each parent account?
    (gnc:register-option 
     options
     (gnc:make-simple-boolean-option
      gnc:pagename-display optname-show-parent-total
      "d" (N_ "Show subtotals for parent accounts") #t))

    (gnc:register-option 
     options
     (gnc:make-simple-boolean-option
      gnc:pagename-display optname-show-foreign 
      "e" (N_ "Display the account's foreign currency amount?") #f))

    (gnc:register-option 
     options
     (gnc:make-simple-boolean-option
      gnc:pagename-display optname-show-rates
      "f" (N_ "Show the exchange rates used") #t))

    ;; Set the general page as default option tab
    (gnc:options-set-default-section options gnc:pagename-general)      

    options))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pnl-renderer
;; set up the document and add the table
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (pnl-renderer report-obj)
  (define (get-option pagename optname)
    (gnc:option-value
     (gnc:lookup-option 
      (gnc:report-options report-obj) pagename optname)))

  (gnc:report-starting reportname)

  ;; get all option's values
  (let* ((display-depth (get-option gnc:pagename-accounts 
                                    optname-display-depth))
         (show-subaccts? (get-option gnc:pagename-accounts
                                     optname-show-subaccounts))
         (accounts (filter gnc:account-is-inc-exp?
                           (get-option gnc:pagename-accounts
                                       optname-accounts)))
         (do-grouping? (get-option gnc:pagename-display
                                   optname-group-accounts))
         (show-parent-balance? (get-option gnc:pagename-display
                                           optname-show-parent-balance))
         (show-parent-total? (get-option gnc:pagename-display
                                         optname-show-parent-total))
         (show-fcur? (get-option gnc:pagename-display
                                 optname-show-foreign))
         (report-currency (get-option gnc:pagename-general
                                      optname-report-currency))
         (price-source (get-option gnc:pagename-general
                                   optname-price-source))
         (show-rates? (get-option gnc:pagename-display 
                                  optname-show-rates))
         (to-date-tp (gnc:timepair-end-day-time 
                      (gnc:date-option-absolute-time
                       (get-option gnc:pagename-general
                                   optname-to-date))))
         (from-date-tp (gnc:timepair-start-day-time 
                        (gnc:date-option-absolute-time
                         (get-option gnc:pagename-general
                                     optname-from-date))))
         (report-title (sprintf #f
                                (_ "%s - %s to %s")
				(get-option gnc:pagename-general gnc:optname-reportname)
                                (gnc:print-date from-date-tp)
                                (gnc:print-date to-date-tp)))
         (doc (gnc:make-html-document)))
    
    (gnc:html-document-set-title! 
     doc report-title)
    (if (not (null? accounts))
        ;; if no max. tree depth is given we have to find the
        ;; maximum existing depth
        (let* ((tree-depth (+ (if (equal? display-depth 'all)
                                  (gnc:get-current-group-depth) 
                                  display-depth)
                              (if do-grouping? 1 0)))

               (exchange-fn #f)
               (table #f))

	  ;; calculate the exchange rates
	  (gnc:report-percent-done 1)
	  (set! exchange-fn (gnc:case-exchange-fn
                             price-source report-currency to-date-tp))
	  (gnc:report-percent-done 10)

	  ;; do the processing here
	  (set! table (gnc:html-build-acct-table 
                       from-date-tp to-date-tp 
                       tree-depth show-subaccts? accounts 10 80 #f
                       #t gnc:accounts-get-comm-total-profit 
                       (_ "Profit") do-grouping? 
                       show-parent-balance? show-parent-total?
                       show-fcur? report-currency exchange-fn #t))
          ;; add the table 
          (gnc:html-document-add-object! doc table)

          ;; add currency information
          (if show-rates?
              (gnc:html-document-add-object! 
               doc ;;(gnc:html-markup-p
               (gnc:html-make-exchangerates 
                report-currency exchange-fn 
                (append-map 
                 (lambda (a)
                   (gnc:group-get-subaccounts
                    (gnc:account-get-children a)))
                 accounts))))
	  (gnc:report-percent-done 100))
        
        ;; error condition: no accounts specified
        
        (gnc:html-document-add-object!
         doc
	 (gnc:html-make-no-account-warning 
	  report-title (gnc:report-id report-obj))))
    (gnc:report-finished)
    doc))

(gnc:define-report 
 'version 1
 'name reportname
 'menu-name (N_ "Profit & Loss")
 'menu-path (list gnc:menuname-income-expense)
 'options-generator pnl-options-generator
 'renderer pnl-renderer)