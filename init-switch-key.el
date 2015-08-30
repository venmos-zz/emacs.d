;; for SpacEmacs https://github.com/syl20bnr/spacemacs
;; venmos .site-elisp/init-switch-key.el
;; http://venmos.com
;; venmos@fuck.gfw.es

;; Keybonds
(global-set-key [(hyper a)] 'mark-whole-buffer)
(global-set-key [(hyper v)] 'yank)
(global-set-key [(hyper c)] 'kill-ring-save)
(global-set-key [(hyper s)] 'save-buffer)
(global-set-key [(hyper l)] 'goto-line)
(global-set-key [(hyper w)]
                (lambda () (interactive) (delete-window)))
(global-set-key [(hyper z)] 'undo)

;; mac switch meta key
(setq mac-option-modifier 'hyper)
(setq mac-command-modifier 'meta)

;; provide
(provide 'init-switch-key)
;;; init-switch-key.el.el ends here
