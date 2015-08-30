;; for SpacEmacs https://github.com/syl20bnr/spacemacs
;; venmos .site-elisp/init-org.el
;; http://venmos.com
;; venmos@fuck.gfw.es

(setq org-directory "~/.org/")
(setq org-agenda-files (list "~/.org/todo.org"))
(setq org-default-notes-file "~/.org/note.org")

(setq org-capture-templates
      `(("i" "Inbox" entry (file+headline ,"~/.org/todo.org" "Inbox")
         "* TODO %?\n%U\n%a\n")
        ("e" "Emacs" entry (file+headline ,"~/.org/todo.org" "Emacs")
         "* TODO %?\n%U\n%a\n")
				("w" "Wiki" entry (file+headline ,"~/.org/todo.org" "Wiki")
         "* TODO %?\n%U\n%a\n")
        ("s" "Study" entry (file+headline ,"~/.org/todo.org" "Study")
         "* TODO %?\n%U\n%a\n")
				("w" "Work-Todo" entry (file+headline ,"~/.org/todo.org" "Work-Todo")
         "* TODO %?\n%U\n%a\n")
        ("n" "Note" entry (file+headline ,"~/.org/note.org" "Inbox")
         "* Note %?\n%U\n")))

(require 'org-crypt)
(org-crypt-use-before-save-magic)
(setq org-crypt-tag-matcher "secret")
(setq org-tags-exclude-from-inheritance (quote ("secret")))
(setq org-crypt-key "4A2C5A73")
(global-set-key "\C-cc" 'org-decrypt-entry)

;; provide
(provide 'init-org)
;;; init-org.el end here
