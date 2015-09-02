;; for SpacEmacs https://github.com/syl20bnr/spacemacs
;; venmos .site-elisp/init-org.el
;; http://venmos.com
;; venmos@fuck.gfw.es

(setq org-directory "~/Dropbox/Org/")
(setq org-agenda-files (list "~/Dropbox/Org/todo.org"))
(setq org-default-notes-file "~/Dropbox/Org/note.org")

(setq org-capture-templates
      `(("t" "TODO" entry (file+headline ,"~/Dropbox/Org/todo.org" "Inbox")
         "* TODO :: %?\n%T\n%a\n")
				("p" "Passwd" entry (file+headline ,"~/Dropbox/Org/passwd.org" "Inbox")
         "* Passwd :: %?\n%U\n")
				("N" "Network" entry (file+headline ,"~/Dropbox/Org/network.org" "Inbox")
         "* Network :: %?\n%U\n")
        ("n" "Note" entry (file+headline ,"~/Dropbox/Org/note.org" "Inbox")
         "* Note :: %?\n%U\n")))

(setq org-todo-keywords
      '((sequence "TODO(t)" "VERIFY(v)" "|" "DONE(d)")
        (sequence "REPORT(r)" "BUG(b)" "|" "FIXED(f)")
        (sequence "|" "CANCELED(c)")))

(setq org-log-done 'time)

(require 'org-crypt)
(org-crypt-use-before-save-magic)
(setq org-crypt-tag-matcher "secret")
(setq org-tags-exclude-from-inheritance (quote ("secret")))
(setq org-crypt-key "4A2C5A73")
(global-set-key "\C-cc" 'org-decrypt-entry)

;; provide
(provide 'init-org)
;;; init-org.el end here
