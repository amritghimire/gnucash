;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; html-piechart.scm : generate HTML programmatically, with support
;; for simple style elements. 
;; Copyright 2000 Bill Gribble <grib@gnumatic.com>
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
;; 51 Franklin Street, Fifth Floor    Fax:    +1-617-542-2652
;; Boston, MA  02110-1301,  USA       gnu@gnu.org
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define <html-piechart>
  (make-record-type "<html-piechart>"
                    '(width
                      height
                      title
                      subtitle
                      data
                      colors
                      labels
                      button-1-slice-urls
                      button-2-slice-urls 
                      button-3-slice-urls
                      button-1-legend-urls
                      button-2-legend-urls 
                      button-3-legend-urls)))


(define gnc:html-piechart? 
  (record-predicate <html-piechart>))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  <html-piechart> class
;;  generate the <object> form for a piechart. 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define gnc:make-html-piechart-internal
  (record-constructor <html-piechart>))

(define (gnc:make-html-piechart)
  (gnc:make-html-piechart-internal -1 -1 #f #f #f #f #f #f #f #f #f #f #f))

(define gnc:html-piechart-data
  (record-accessor <html-piechart> 'data))

(define gnc:html-piechart-set-data!
  (record-modifier <html-piechart> 'data))

(define gnc:html-piechart-width
  (record-accessor <html-piechart> 'width))

(define gnc:html-piechart-set-width!
  (record-modifier <html-piechart> 'width))

(define gnc:html-piechart-height
  (record-accessor <html-piechart> 'height))

(define gnc:html-piechart-set-height!
  (record-modifier <html-piechart> 'height))

(define gnc:html-piechart-labels
  (record-accessor <html-piechart> 'labels))

(define gnc:html-piechart-set-labels!
  (record-modifier <html-piechart> 'labels))

(define gnc:html-piechart-colors
  (record-accessor <html-piechart> 'colors))

(define gnc:html-piechart-set-colors!
  (record-modifier <html-piechart> 'colors))

(define gnc:html-piechart-title
  (record-accessor <html-piechart> 'title))

(define gnc:html-piechart-set-title!
  (record-modifier <html-piechart> 'title))

(define gnc:html-piechart-subtitle
  (record-accessor <html-piechart> 'subtitle))

(define gnc:html-piechart-set-subtitle!
  (record-modifier <html-piechart> 'subtitle))

(define gnc:html-piechart-button-1-slice-urls
  (record-accessor <html-piechart> 'button-1-slice-urls))

(define gnc:html-piechart-set-button-1-slice-urls!
  (record-modifier <html-piechart> 'button-1-slice-urls))

(define gnc:html-piechart-button-2-slice-urls
  (record-accessor <html-piechart> 'button-2-slice-urls))

(define gnc:html-piechart-set-button-2-slice-urls!
  (record-modifier <html-piechart> 'button-2-slice-urls))

(define gnc:html-piechart-button-3-slice-urls
  (record-accessor <html-piechart> 'button-3-slice-urls))

(define gnc:html-piechart-set-button-3-slice-urls!
  (record-modifier <html-piechart> 'button-3-slice-urls))

(define gnc:html-piechart-button-1-legend-urls
  (record-accessor <html-piechart> 'button-1-legend-urls))

(define gnc:html-piechart-set-button-1-legend-urls!
  (record-modifier <html-piechart> 'button-1-legend-urls))

(define gnc:html-piechart-button-2-legend-urls
  (record-accessor <html-piechart> 'button-2-legend-urls))

(define gnc:html-piechart-set-button-2-legend-urls!
  (record-modifier <html-piechart> 'button-2-legend-urls))

(define gnc:html-piechart-button-3-legend-urls
  (record-accessor <html-piechart> 'button-3-legend-urls))

(define gnc:html-piechart-set-button-3-legend-urls!
  (record-modifier <html-piechart> 'button-3-legend-urls))

(define (gnc:html-piechart-render piechart doc)
  (define (ensure-positive-numbers nlist)
    (map
     (lambda (elt)
       (cond ((number? elt)
              (exact->inexact (abs elt)))
             ((string? elt)
              (with-input-from-string elt
                (lambda ()
                  (let ((n (read)))
                    (if (number? n) (abs n) 0.0)))))
             ((gnc:gnc-numeric? elt)
              (abs (gnc-numeric-to-double elt)))
             (#t 
              0.0)))
     nlist))
  
  (define (catenate-escaped-strings nlist)
    (if (not (list? nlist))
        ""
        (with-output-to-string
          (lambda ()
            (for-each 
             (lambda (s)
               (let ((escaped 
                      (regexp-substitute/global 
                       #f " " 
                       (regexp-substitute/global 
                        #f "\\\\" s
                        'pre "\\\\" 'post)
                       'pre "\\ " 'post)))
                 (display escaped)
                 (display " ")))
             nlist)))))
  
  (let* ((retval '())
         (push (lambda (l) (set! retval (cons l retval))))
         (title (gnc:html-piechart-title piechart))
         (subtitle (gnc:html-piechart-subtitle piechart))
         (url-1
          (catenate-escaped-strings 
           (gnc:html-piechart-button-1-slice-urls piechart)))
         (url-2 
          (catenate-escaped-strings 
           (gnc:html-piechart-button-2-slice-urls piechart)))
         (url-3
          (catenate-escaped-strings 
           (gnc:html-piechart-button-3-slice-urls piechart)))
         (legend-1
          (catenate-escaped-strings 
           (gnc:html-piechart-button-1-legend-urls piechart)))
         (legend-2 
          (catenate-escaped-strings 
           (gnc:html-piechart-button-2-legend-urls piechart)))
         (legend-3
          (catenate-escaped-strings 
           (gnc:html-piechart-button-3-legend-urls piechart)))
         (data 
          (ensure-positive-numbers (gnc:html-piechart-data piechart)))
         (labels 
          (catenate-escaped-strings (gnc:html-piechart-labels piechart)))
         (colors 
          (catenate-escaped-strings (gnc:html-piechart-colors piechart))))
    (if (and (list? data) 
             (not (null? data)))
        (begin 
            (push (gnc:html-js-include "gnucash/jqplot/jquery-1.4.2.min.js"))
            (push (gnc:html-js-include "gnucash/jqplot/jquery.jqplot.js"))
            (push (gnc:html-js-include "gnucash/jqplot/jqplot.pieRenderer.js"))
            (push (gnc:html-css-include "gnucash/jqplot/jquery.jqplot.css"))

            (push "<div id=\"placeholder\" style=\"width:")
            (push (gnc:html-piechart-width piechart))
            (push "px;height:")
            (push (gnc:html-piechart-height piechart))
            (push "px;\"></div>")
            (push "<script id=\"source\">\n$(function () {")

            (push "var data = [];")

            (if (and data (list? data))
              (begin 
                (for-each 
                 (lambda (datum label)
                   (push "  data.push(['")
                   (push label)
                   (push "',")
                   (push datum)
                   (push "]);\n"))
                 data (gnc:html-piechart-labels piechart))))

            (push "var options = {
                    seriesDefaults: {
                        renderer: $.jqplot.PieRenderer,
                    },
                    legend: { show: true, },
                   };")

            (if title
              (begin 
                (push "  options.title = \"")
                (push title) (push "\";\n")))
            (if subtitle
              (begin 
                (push "  options.title += \" (")
                (push subtitle) (push ")\";\n")))

            (push "$.jqplot.config.enablePlugins = true;")
            (push "var plot = $.jqplot('placeholder', [data], options);")
            (push "});</script>")


          (push "<object classid=\"")(push GNC-CHART-PIE)(push "\" width=")
          (push (gnc:html-piechart-width piechart))
          (push " height=") 
          (push (gnc:html-piechart-height piechart))
          (push ">\n")
          (if title
              (begin 
                (push "  <param name=\"title\" value=\"")
                (push title) (push "\">\n")))
          (if subtitle
              (begin 
                (push "  <param name=\"subtitle\" value=\"")
                (push subtitle) (push "\">\n")))
          (if (and data (list? data))
              (begin 
                (push "  <param name=\"datasize\" value=\"")
                (push (length data)) (push "\">\n")
                (push "  <param name=\"data\" value=\"")
                (for-each 
                 (lambda (datum)
                   (push datum)
                   (push " "))
                 data)
                (push "\">\n")))
          (if (and (string? colors)
                   (> (string-length colors) 0))
              (begin 
                (push "  <param name=\"colors\" value=\"")
                (push colors)
                (push "\">\n")))
          (if (and (string? labels)
                   (> (string-length labels) 0))
              (begin 
                (push "  <param name=\"labels\" value=\"")
                (push labels)
                (push "\">\n")))
          (if url-1 
              (begin 
                (push "  <param name=\"slice_urls_1\" value=\"")
                (push url-1)
                (push "\">\n")))
          (if url-2
              (begin 
                (push "  <param name=\"slice_urls_2\" value=\"")
                (push url-2)
                (push "\">\n")))
          (if url-3 
              (begin 
                (push "  <param name=\"slice_urls_3\" value=\"")
                (push url-3)
                (push "\">\n")))
          (if legend-1 
              (begin 
                (push "  <param name=\"legend_urls_1\" value=\"")
                (push legend-1)
                (push "\">\n")))
          (if legend-2
              (begin 
                (push "  <param name=\"legend_urls_2\" value=\"")
                (push legend-2)
                (push "\">\n")))
          (if legend-3 
              (begin 
                (push "  <param name=\"legend_urls_3\" value=\"")
                (push legend-3)
                (push "\">\n")))
          (push "Unable to display pie chart\n")
          (push "</object> &nbsp;\n"))
	(begin (gnc:warn "null-data, not rendering piechart")
	       " "))
    retval))










