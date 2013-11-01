;; Copyright (C) 2013 Dave Griffiths
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

#lang racket
(require (planet jaymccarthy/sqlite:5:1/sqlite))
(provide (all-defined-out))
(require "logger.ss")

(define (setup db)
  (exec/ignore db "CREATE TABLE player ( id INTEGER PRIMARY KEY AUTOINCREMENT, species TEXT, played_before INTEGER, age_range INTEGER, score INTEGER)")
  (exec/ignore db "CREATE TABLE click ( id INTEGER PRIMARY KEY AUTOINCREMENT, player_id INTEGER, photo_name TEXT, photo_offset_x INTEGER, photo_offset_y INTEGER, time_stamp INTEGER, x_position INTEGER, y_position INTEGER, success INTEGER )")
  )

(define (insert-player db species played_before age_range)
  (log "player " species " " played_before " " age_range)
  (insert db (string-append
              "INSERT INTO player VALUES (NULL, '"
              species "', '"
              (if (equal? played_before "false") "0" "1") "', '"
              age_range "', 999999)")))

(define (insert-click db player_id photo_name photo_offset_x photo_offset_y time_stamp x_position y_position success)
  (log "click " player_id " " photo_name " " photo_offset_x " " photo_offset_y " " time_stamp " " x_position " " y_position " " success)
  (insert db (string-append
              "INSERT INTO click VALUES (NULL, '"
              player_id "', '"
              photo_name "', '"
              photo_offset_x "', '"
              photo_offset_y "', '"
              time_stamp "', '"
              x_position "', '"
              y_position "', '"
              success "')")))

;(define (get-player-averages db)
;  (let ((players (cdr (select db "SELECT * from player"))))
;    (filter
;     (lambda (av)
;       (not (false? av)))
;     (map
;      (lambda (player)
;        (get-player-average-min db (vector-ref player 0)))
;      players))))

(define (get-player-averages db)
  (map
   (lambda (i) (vector-ref i 0))
   (cdr (select db "SELECT score from player"))))

(define (get-player-average db player-id)
  (let ((v (cadr
            (select db (string-append
                        "SELECT avg(time_stamp), count(time_stamp) from click where success = 1 and player_id = "
                        (number->string player-id))))))
    (when (> (vector-ref v 1) 5)
          (exec/ignore
           db (string-append
               "UPDATE player SET score = "
               (number->string (vector-ref v 0))
               " where id = " (number->string player-id))))
    (vector-ref v 0)))

(define (get-player-count db player-id)
  (let ((v (cadr (select db (string-append
                             "SELECT count(time_stamp) from click where success = 1 and player_id = "
                             (number->string player-id))))))
    (vector-ref v 0)))

(define (get-position v ol)
  (define (_ n l)
    (cond
      ((null? l) n)
      ((> (car l) v) n)
      (else (_ (+ n 1) (cdr l)))))
  (_ 1 ol))

(define (get-player-rank db av)
  (if av
      (let ((rank (sort (get-player-averages db) <)))
        (get-position av rank))
      999))
