;; for SpacEmacs https://github.com/syl20bnr/spacemacs
;; venmos .site-elisp/init-tabbar.el
;; http://venmos.com
;; venmos@fuck.gfw.es

;; require
(require 'uniquify)
(require 'tabbar)
(require 'ibuf-ext)

;; tabbar-extension

(defun tabbar-select-end-tab ()
  "Select end tab of current tabset."
  (interactive)
  (tabbar-select-beg-tab t))

(defun tabbar-select-beg-tab (&optional backward type)
  "Select beginning tab of current tabs.
If BACKWARD is non-nil, move backward, otherwise move forward.
TYPE is default option."
  (interactive)
  (let* ((tabset (tabbar-current-tabset t))
         (ttabset (tabbar-get-tabsets-tabset))
         (cycle (if (and (eq tabbar-cycle-scope 'groups)
                         (not (cdr (tabbar-tabs ttabset))))
                    'tabs
                  tabbar-cycle-scope))
         selected tab)
    (when tabset
      (setq selected (tabbar-selected-tab tabset))
      (setq tabset (tabbar-tabs tabset)
            tab (car (if backward (last tabset) tabset)))
      (tabbar-click-on-tab tab type))))

(defun tabbar-backward-tab-other-window (&optional reversed)
  "Move to left tab in other window.
Optional argument REVERSED default is move backward, if reversed is non-nil move forward."
  (interactive)
  (other-window 1)
  (if reversed
      (tabbar-forward-tab)
    (tabbar-backward-tab))
  (other-window -1))

(defun tabbar-forward-tab-other-window ()
  "Move to right tab in other window."
  (interactive)
  (tabbar-backward-tab-other-window t))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq uniquify-buffer-name-style 'forward)
(tabbar-mode t)
;; shortcuts
(global-set-key (kbd "s-{") 'tabbar-backward)
(global-set-key (kbd "s-}") 'tabbar-forward)
(global-set-key (kbd "C-c [") 'tabbar-backward-group)
(global-set-key (kbd "C-c ]") 'tabbar-forward-group)
;; hide-header-button
(defcustom tabbar-hide-header-button t
  "Hide header button at left-up corner.
Default is t."
  :type 'boolean
  :set (lambda (symbol value)
         (set symbol value)
         (if value
             (setq
              tabbar-scroll-left-help-function nil ;don't show help information
              tabbar-scroll-right-help-function nil
              tabbar-help-on-tab-function nil
              tabbar-home-help-function nil
              tabbar-buffer-home-button (quote (("") "")) ;don't show tabbar button
              tabbar-scroll-left-button (quote (("") ""))
              tabbar-scroll-right-button (quote (("") "")))))
  :group 'tabbar)
;; tabbar-theme-configure
(set-face-attribute 'tabbar-default nil
         :background "#272822"
         :family "Source Code Pro"
         :foreground "#272822"
         :height 1)
(set-face-attribute 'tabbar-unselected nil
         :inherit 'tabbar-default
         :background "#272822"
         :foreground "#75715D"
         :box nil)
(set-face-attribute 'tabbar-selected nil
         :inherit 'tabbar-default
         :background "#EEAD0E"
         :foreground "#272822"
         :box nil)
(set-face-attribute 'tabbar-separator nil
         :height 1)

;; provide
(provide 'init-tabbar)
;;; init-tabbar.el ends here
