(in-package :om)

(defvar *general-mixer-window* nil)
(defvar *general-mixer-values* (make-hash-table))
(defun init-genmixer-values ()
  (loop for i from 0 to (- las-channels 1) do
        (setf (gethash i *general-mixer-values*) (list 0 100))))



(defun build-faust-pool-list ()
  (let ((n (- (las-get-number-faust-effects-register) 1))
        (final-list (list "-"))) 
    (loop for i from 0 to n do
          (setf final-list (append final-list (list (nth 2 (gethash i *faust-effects-register*))))))
    final-list))

(defun update-faust-pool-list)



(defclass omgenmixer-window (om-window)
  ())

(defclass omgenmixer-view (om-view) ())

(defun make-general-mixer-win ()
  (let ((newwindow (om-make-window 'omgenmixer-window :window-title "OpenMusic General Mixer" 
                                   :size (om-make-point (+ 5 (* *channel-w* 10)) 370) 
                                   :scrollbars :h
                                   :position (om-make-point 100 50) :close t :resizable nil))
        panel)
    (setf panel (om-make-view 'omgenmixer-view
                              :owner newwindow
                              :position (om-make-point 0 0) 
                              :scrollbars :h
                              :retain-scrollbars t
                              :field-size  (om-make-point (+ 5 (* *channel-w* las-channels)) 350)
                              :size (om-make-point (w newwindow) (h newwindow))))
    (om-add-subviews newwindow panel)
    (loop for i from 0 to (- las-channels 1) do
          (om-add-subviews panel (genmixer-make-single-channel-view panel i)))
    (print (om-subviews (car (om-subviews panel))))
    newwindow))

(defun omG-make-genmixer-dialog ()
  (if (and *general-mixer-window* (om-window-open-p *general-mixer-window*))
      (om-select-window *general-mixer-window*)
    (setf *general-mixer-window* (om-select-window (make-general-mixer-win)))))

(defun genmixer-make-single-channel-view (panel channel)
  (let ((main-view (om-make-view 'om-view 
                                 :owner panel
                                 :position (om-make-point (+ 5 (* channel *channel-w*)) 5) 
                                 :scrollbars nil
                                 :retain-scrollbars nil
                                 :field-size  (om-make-point (- *channel-w* 5) 345)
                                 :size (om-make-point (- *channel-w* 5) 345)
                                 :bg-color *om-light-gray-color*))
        (pos 8)
        (volval (cadr (gethash channel *general-mixer-values*)))
        (panval (car (gethash channel *general-mixer-values*)))
        channel-text bar1 pan-text pan-val pan-slider bar2 vol-text vol-val vol-slider
        bar3 faust-text effect1 effect2 effect3 effect4 effect5)

    (setf channel-text (om-make-dialog-item 'om-static-text
                                            (if (< channel 10) (om-make-point 4 pos) (om-make-point 1 pos))
                                            (om-make-point 80 20) (format nil "CHANNEL ~A" (+ 1 channel))
                                            :font *om-default-font1*))

    (incf pos 20)
    (setf bar1 (om-make-view 'bar-item 
                             :position (om-make-point 3 pos) 
                             :size (om-make-point 69 10)
                             :bg-color *om-light-gray-color*))

    (incf pos 10)
    (setf pan-text (om-make-dialog-item 'om-static-text
                                        (om-make-point 14 pos) 
                                        (om-make-point 40 16)
                                        "Pan"
                                        :font *om-default-font2*))
    (setf pan-val (om-make-dialog-item 'om-static-text
                                       (om-make-point 45 pos) 
                                       (om-make-point 30 16)
                                       (number-to-string panval)
                                       :font *om-default-font2*))

    (incf pos 16)
    (setf pan-slider (om-make-view 'graphic-numbox :position (om-make-point 28 pos) 
                                   :size (om-make-point 20 20)
                                   :pict (om-load-and-store-picture "dial" 'di)
                                   :nbpict 65
                                   :pict-size (om-make-point 24 24)
                                   :di-action (om-dialog-item-act item
                                                (change-genmixer-channel-pan (+ channel 1) (value item))
                                                (om-set-dialog-item-text pan-val (number-to-string (value item))))
                                   :font *om-default-font2*
                                   :value panval
                                   :min-val -100
                                   :max-val 100))

    (incf pos 25)
    (setf bar2 (om-make-view 'bar-item 
                             :position (om-make-point 3 pos) 
                             :size (om-make-point 69 10)
                             :bg-color *om-light-gray-color*))

    (incf pos 10)
    (setf vol-text (om-make-dialog-item 'om-static-text 
                                        (om-make-point 11 pos) 
                                        (om-make-point 40 16)
                                        "Vol"
                                        :font *om-default-font2*))
    (setf vol-val (om-make-dialog-item 'om-static-text 
                                       (om-make-point 40 pos) 
                                       (om-make-point 30 16)
                                       (number-to-string volval)
                                       :font *om-default-font2*))
    
    (incf pos 20)
    (setf vol-slider (om-make-dialog-item 'om-slider  
                                          (om-make-point 20 pos) 
                                          (om-make-point 30 100) ""
                                          :di-action (om-dialog-item-act item
                                                       (change-genmixer-channel-vol (+ channel 1) (om-slider-value item))
                                                       (om-set-dialog-item-text vol-val (number-to-string (om-slider-value item))))
                                          :increment 1
                                          :range '(0 100)
                                          :value volval
                                          :direction :vertical
                                          :tick-side :none))

    (incf pos 110)
    (setf bar3 (om-make-view 'bar-item 
                             :position (om-make-point 3 pos) 
                             :size (om-make-point 69 10)
                             :bg-color *om-light-gray-color*))

    (incf pos 4)
    (setf faust-text (om-make-dialog-item 'om-static-text 
                                          (om-make-point 7 pos) 
                                          (om-make-point 75 16)
                                          "Faust Pool"
                                          :font *om-default-font1*))

    (incf pos 20)
    (setf effect1 (om-make-dialog-item 'om-pop-up-dialog-item 
                                       (om-make-point 0 pos) 
                                       (om-make-point 75 12)
                                       ""
                                       :di-action (om-dialog-item-act item
                                                    (om-get-selected-item-index item))
                                       :font *om-default-font1*
                                       :range (build-faust-pool-list)
                                       :value nil))

    (incf pos 20)
    (setf effect2 (om-make-dialog-item 'om-pop-up-dialog-item 
                                       (om-make-point 0 pos) 
                                       (om-make-point 75 12)
                                       ""
                                       :di-action (om-dialog-item-act item
                                                    )
                                       :font *om-default-font1*
                                       :range (build-faust-pool-list)
                                       :value nil))

    (incf pos 20)
    (setf effect3 (om-make-dialog-item 'om-pop-up-dialog-item 
                                       (om-make-point 0 pos) 
                                       (om-make-point 75 12)
                                       ""
                                       :di-action (om-dialog-item-act item
                                                    )
                                       :font *om-default-font1*
                                       :range (build-faust-pool-list)
                                       :value nil))

    (incf pos 20)
    (setf effect4 (om-make-dialog-item 'om-pop-up-dialog-item 
                                       (om-make-point 0 pos) 
                                       (om-make-point 75 12)
                                       ""
                                       :di-action (om-dialog-item-act item
                                                    )
                                       :font *om-default-font1*
                                       :range (build-faust-pool-list)
                                       :value nil))

    (incf pos 20)
    (setf effect5 (om-make-dialog-item 'om-pop-up-dialog-item 
                                       (om-make-point 0 pos) 
                                       (om-make-point 75 12)
                                       ""
                                       :di-action (om-dialog-item-act item
                                                    )
                                       :font *om-default-font1*
                                       :range (build-faust-pool-list)
                                       :value nil))



    (if (= 0 (om-get-selected-item-index effect1))
        (progn
          (om-enable-dialog-item effect2 nil)
          (om-enable-dialog-item effect3 nil)
          (om-enable-dialog-item effect4 nil)
          (om-enable-dialog-item effect5 nil)
          )
      (if (= 0 (om-get-selected-item-index effect2))
          (progn
            (om-enable-dialog-item effect3 nil)
            (om-enable-dialog-item effect4 nil)
            (om-enable-dialog-item effect5 nil)
            )
        (if (= 0 (om-get-selected-item-index effect3))
            (progn
              (om-enable-dialog-item effect4 nil)
              (om-enable-dialog-item effect5 nil)
              )
          (if (= 0 (om-get-selected-item-index effect4))
              (progn
                (om-enable-dialog-item effect5 nil)
                )))))


    (om-add-subviews main-view 
                     channel-text
                     bar1
                     pan-text
                     pan-val
                     pan-slider
                     bar2
                     vol-text
                     vol-val
                     vol-slider
                     bar3
                     faust-text
                     effect1
                     effect2
                     effect3
                     effect4
                     effect5)
    main-view))


(defun change-genmixer-channel-vol (channel value)
  (progn
    (las-change-channel-vol-visible channel (float (/ value 100)))
    (setf (cadr (gethash (- channel 1) *general-mixer-values*)) value)))

(defun change-genmixer-channel-pan (channel value)
  (progn
    (las-change-channel-pan-visible channel (- 1.0 (float (/ (+ value 100) 200))))
    (setf (car (gethash (- channel 1) *general-mixer-values*)) value)))
