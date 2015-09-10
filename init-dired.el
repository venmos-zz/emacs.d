;; for SpacEmacs https://github.com/syl20bnr/spacemacs
;; venmos .site-elisp/init-dired.el
;; http://venmos.com
;; venmos@fuck.gfw.es

(add-to-list 'load-path "~/Gitst/venmos-emacs.d")
;; color-dired by https://github.com/mhayashi1120/Emacs-color-dired

(require 'dired+)
(require 'dired-single)
(require 'color-dired)
(require 'dired-rainbow)
(require 'color-moccur)
(require 'dired-x)

;; dired-extension
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar my-dired-omit-status t
  "The status of dired omit file.")
(defvar my-dired-omit-regexp "^#\\|^\\..*"
  "The regexp string that matching omit files.")
(defvar my-dired-omit-extensions '(".cache")
  "The list that matching omit file's extension.")

;; Advice `dired-run-shell-command' with asynchronously.
(defadvice dired-run-shell-command (around dired-run-shell-command-async activate)
  "Postfix COMMAND argument of `dired-run-shell-command' with an ampersand.
If there is none yet, so that it is run asynchronously."
  (let* ((cmd (ad-get-arg 0))
         (cmd-length (length cmd))
         (last-cmd-char (substring cmd
                                   (max 0 (- cmd-length 1))
                                   cmd-length)))
    (unless (string= last-cmd-char "&")
      (ad-set-arg 0 (concat cmd "&")))
    (save-window-excursion ad-do-it)))

(defun dired-sort-method ()
  "The sort method of `dired'."
  (let (buffer-read-only)
    (forward-line 2) ;; beyond dir. header
    (sort-regexp-fields t "^.*$" "[ ]*." (point) (point-max))))

(defun dired-omit-method ()
  "The omit method of dired."
  (when my-dired-omit-status
    (setq dired-omit-mode t)
    (setq dired-omit-files my-dired-omit-regexp)
    (setq dired-omit-extensions my-dired-omit-extensions)))

(defun dired-toggle-omit ()
  "Toggle omit status of dired files."
  (interactive)
  (if my-dired-omit-status
      (let ((dired-omit-size-limit nil))
        (setq dired-omit-mode nil)
        (dired-omit-expunge)
        (setq my-dired-omit-status nil))
    (setq dired-omit-mode t)
    (setq my-dired-omit-status t))
  (revert-buffer))

(defun dired-get-size ()
  "Get total size of marked files with `du' command.
If not marked any files, default is current file or directory."
  (interactive)
  (let ((files (dired-get-marked-files)))
    (with-temp-buffer
      (apply 'call-process "/usr/bin/du" nil t nil "-sch" files)
      (message "Size of all marked files: %s"
               (progn
                 (re-search-backward "\\(^[0-9.,]+[A-Za-z]+\\).*\\(total\\|总用量\\)$")
                 (match-string 1))))))

(defun dired-rename-with-copy ()
  "Rename name in Dired, and copy current name in yank."
  (interactive)
  (dired-copy-filename-as-kill)
  (dired-do-rename))

(defun dired-up-directory-single ()
  "Return up directory in single window.
When others visible window haven't current buffer, kill old buffer after `dired-up-directory'.
Otherwise, just `dired-up-directory'."
  (interactive)
  (let ((old-buffer (current-buffer))
        (current-window (selected-window)))
    (dired-up-directory)
    (catch 'found
      (walk-windows
       (lambda (w)
         (with-selected-window w
           (when (and (not (eq current-window (selected-window)))
                      (equal old-buffer (current-buffer)))
             (throw 'found "Found current dired buffer in others visible window.")))))
      (kill-buffer old-buffer))))

(defun dired-find-file+ ()
  "Like `dired-find-file'.
When open directory, if others visible window have this directory, do `find-file'.
Otherwise do `find-alternate-file'.
When open file, always use `find-file'."
  (interactive)
  (set-buffer-modified-p nil)
  (let ((file (dired-get-file-for-visit))
        (old-buffer (current-buffer))
        (current-window (selected-window)))
    (if (file-directory-p file)
        (catch 'found
          (walk-windows
           (lambda (w)
             (with-selected-window w
               (when (and (not (eq current-window (selected-window)))
                          (equal old-buffer (current-buffer)))
                 (find-file file)
                 (throw 'found "Found current dired buffer in others visible window.")))))
          (find-alternate-file file))
      (find-file file))))

(defun dired-serial-rename (dir ext name start)
  "Rename sequentially a set of file with the extension EXT.
In a repertory DIR with the name name + the start number start."
  (interactive "fDir: \nsExt(no dot): \nsName: \nnStart: ")
  (find-file dir)
  (let (ls-dir
        new-ls-dir
        n
        c)
    (setq ls-dir (file-expand-wildcards (format "*.%s" ext) t))
    (setq new-ls-dir nil)
    (setq n 0)
    (while (< n (length ls-dir))
      (if (< start 10)
          (push (concat dir name (format "0%s" start) "." ext) new-ls-dir)
        (push (concat dir name (format "%s" start) "." ext) new-ls-dir))
      (incf start)
      (incf n))
    (setq ls-dir (reverse ls-dir))
    (setq c 0)
    (dolist (i ls-dir)
      (rename-file i (nth c new-ls-dir))
      (incf c))))

(defun dired-next-file-line ()
  "Move to the next dired line that have a file or directory name on it."
  (interactive)
  (call-interactively 'dired-next-line)
  (if (eobp)
      (dired-previous-line 1)))

(defun dired-move-to-first-file ()
  "Move cursor to first file of dired."
  (interactive)
  (goto-char (point-min))
  (while (not (dired-move-to-filename))
    (call-interactively 'dired-next-line)))

(defun dired-move-to-last-file ()
  "Move cursor to last file of dired."
  (interactive)
  (goto-char (point-max))
  (while (not (dired-move-to-filename))
    (call-interactively 'dired-previous-line)))

(defun dired-previous-file-line ()
  "Move to the previous dired line that have a file or directory name on it."
  (interactive)
  (call-interactively 'dired-previous-line)
  (if (not (dired-move-to-filename))
      (dired-next-line 1)))

(defun dired-nautilus ()
  "Load current directory with nautilus."
  (interactive)
  (shell-command
   (concat "nautilus " (dired-current-directory))))

(defun dired-touch-now (touch-file)
  "Do `touch' command with TOUCH-FILE."
  (interactive "sTouch file: ")
  (cd (dired-current-directory))
  (shell-command
   (concat "touch \""
           ;; if filename is begin with `-', add '-- ' before file-name
           (if (string-match "^-.*" touch-file) "-- ")
           touch-file "\""))
  (sit-for 0.1)
  (revert-buffer)
  (dired-goto-file (concat (dired-current-directory) touch-file)))

(defun dired-gnome-open-file ()
  "Opens the current file in a Dired buffer."
  (interactive)
  (gnome-open-file (dired-get-file-for-visit)))

(defun gnome-open-file (filename)
  "gnome-opens the specified file."
  (interactive "fFile to open: ")
  (let ((process-connection-type nil))
    (start-process "" nil "/usr/bin/xdg-open" filename)))

(defun gnome-open-buffer ()
  "Open current buffer file with gnome."
  (interactive)
  (gnome-open-file buffer-file-name))

(defun dir-file-ext-my (file)
  "Given a full file's path name, returns a list of directory, filename
and extension.  The extension contains the ., and the directory
contains the /
See also file-name-directory and file-name-nondirectory.."
  (interactive "s String: ")
  (with-temp-buffer
    (insert file)
    (goto-char (point-max))
    (let ((aa (progn
                (goto-char (point-max))
                (search-backward "/" nil t)))
          (bb (progn
                (goto-char (point-max))
                (search-backward "." nil t))))
      (setq aa (if (null aa) (point-min) (+ aa 1)))
      (if (null bb) (setq bb (point-max)))
      (if (> aa bb) (setq bb (point-max))) ;that means that the . occurs in
                                        ;the path name rather than filename.
      (let ((cc
             (list
              (buffer-substring (point-min) aa)
              (buffer-substring aa bb)
              (buffer-substring bb (point-max)))))
        (if (interactive-p) (message "%S" cc))
        cc))))

(defun find-lisp-find-dired-pwd (regexp)
  "Find files in DIR, matching REGEXP."
  (interactive "sMatching regexp: ")
  (find-lisp-find-dired default-directory regexp))

(defun moccur-grep-find-pwd (inputs)
  (interactive
   (list (moccur-grep-read-regexp moccur-grep-default-mask)))
  (moccur-grep-find default-directory inputs))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; dired-extension end here

;; dired-isearch
(defun dired-isearch-forward (&optional regexp-p no-recursive-edit)
  "In Dired, run `isearch-forward' but match only at file names."
  (interactive)
  (let ((isearch-search-fun-function 'dired-isearch-search-fun-function))
    (isearch-forward regexp-p no-recursive-edit)))

(defun dired-isearch-backward (&optional regexp-p no-recursive-edit)
  "In Dired, run `isearch-backward' but match only at file names."
  (interactive)
  (let ((isearch-search-fun-function 'dired-isearch-search-fun-function))
    (isearch-backward regexp-p no-recursive-edit)))

(defun dired-isearch-forward-regexp (&optional not-regexp no-recursive-edit)
  "In Dired, run `isearch-forward-regexp' but match only at file names."
  (interactive)
  (let ((isearch-search-fun-function 'dired-isearch-search-fun-function))
    (isearch-forward-regexp not-regexp no-recursive-edit)))

(defun dired-isearch-backward-regexp (&optional not-regexp no-recursive-edit)
  "In Dired, run `isearch-backward-regexp' but match only at file names."
  (interactive)
  (let ((isearch-search-fun-function 'dired-isearch-search-fun-function))
    (isearch-backward-regexp not-regexp no-recursive-edit)))

 
;;; Low Level Functions

(defun dired-isearch-search-fun-function ()
  "Return the isearch function in Dired."
  (cond
       (isearch-word
        (if isearch-forward 'dired-word-search-forward 'dired-word-search-backward))
       (isearch-regexp
        (if isearch-forward 'dired-re-search-forward 'dired-re-search-backward))
       (t
        (if isearch-forward 'dired-search-forward 'dired-search-backward))))

(defun dired-search-forward (string &optional bound noerror count)
  "In Dired, run `search-forward' but match only at file names."
  (let ((point (search-forward string bound noerror count)))
    (catch 'return
      (while point
        (when (get-text-property (1- point) 'help-echo)
          (throw 'return point))
        (setq point (search-forward string bound noerror count))))))

(defun dired-search-backward (string &optional bound noerror count)
  "In Dired, run `search-backward' but match only at file names."
  (let ((point (search-backward string bound noerror count)))
    (catch 'return
      (while point
        (when (get-text-property point 'help-echo)
          (throw 'return point))
        (setq point (search-backward string bound noerror count))))))

(defun dired-re-search-forward (regexp &optional bound noerror count)
  "In Dired, run `re-search-forward' but match only at file names."
  (let ((point (re-search-forward regexp bound noerror count)))
    (catch 'return
      (while point
        (when (get-text-property (1- point) 'help-echo)
          (throw 'return point))
        (setq point (re-search-forward regexp bound noerror count))))))

(defun dired-re-search-backward (regexp &optional bound noerror count)
  "In Dired, run `re-search-backward' but match only at file names."
  (let ((point (re-search-backward regexp bound noerror count)))
    (catch 'return
      (while point
        (when (get-text-property point 'help-echo)
          (throw 'return point))
        (setq point (re-search-backward regexp bound noerror count))))))

(defun dired-word-search-forward (string &optional bound noerror count)
  "In Dired, run `word-search-forward' but match only at file names."
  (let ((point (word-search-forward string bound noerror count)))
    (catch 'return
      (while point
        (when (get-text-property (1- point) 'help-echo)
          (throw 'return point))
        (setq point (word-search-forward string bound noerror count))))))

(defun dired-word-search-backward (string &optional bound noerror count)
  "In Dired, run `word-search-backward' but match only at file names."
  (let ((point (word-search-backward string bound noerror count)))
    (catch 'return
      (while point
        (when (get-text-property point 'help-echo)
          (throw 'return point))
        (setq point (word-search-backward string bound noerror count))))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; dired-isearch end here

;;; dired-file-type-face
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'dired)
(require 'custom)

(defgroup dired-filetype-face nil
  "set faces for different filetype in dired buffer."
  :prefix "dired-filetype-face-"
  :group 'dired-faces)

(defmacro deffiletype-face (type color &optional type-for-symbol)
  "Declare a dired filetype face for displaying TYPE files in the given COLOR.

If TYPE-FOR-SYMBOL is nil, define a face named
  dired-filetype-TYPE

Otherwise, define a face named
  dired-filetype-TYPE-FOR-SYMBOL

COLOR may be a string or a list of face properties. If a string,
it is either a color name such as \"Chartreuse\" or a color
hexadecimal RGB number such as \"#xaaaaaa\"."
  `(defface ,(intern (concat "dired-filetype-" (downcase (or type-for-symbol type))))
     ,(if (stringp color)
       `(quote ((t (:foreground ,color))))
       color)
     ,(format "Face for displaying %s files in dired." type)
     :group 'dired-filetype-face))

(defmacro deffiletype-face-regexp (regexp type-for-symbol &optional type-for-docstring)
  "Declare a filetype REGEXP option for dired to colorize matching files.

Use TYPE-FOR-SYMBOL to derive the option symbol.

If TYPE-FOR-DOCSTRING is not nil, use that in the option
docstring instead of TYPE-FOR-SYMBOL."
  `(defcustom ,(intern (format "dired-filetype-%s-regexp" type-for-symbol))
     ,regexp
     ,(format "Regexp to match %s file-types in dired." (or type-for-docstring type-for-symbol))
     :type 'string
     :group 'dired-filetype-face))

(defconst dired-filetype-face-font-lock-keywords
  '(("(\\(deffiletype\\(?:-\\(?:face\\|face-regexp\\|setup\\)\\)?\\)\\_>"
     (1 font-lock-keyword-face))))

(font-lock-add-keywords 'emacs-lisp-mode dired-filetype-face-font-lock-keywords)

(defvar dired-filetype-setup-hook nil)

(deffiletype-face "omit" "Chartreuse")

(deffiletype-face-regexp
  "^  .*\\.\\(elc\\|class\\|so\\|ko\\|la\\|o\\|al\\|ix\\|db\\|td\\|\\|dat\\|dll\\|Dll\\|DLL\\|sav\\|rdp\\|sys\\|SYS\\|prf\\|tlb\\|cat\\|bak\\)$"
  "omit1"
  "unimportant")

(deffiletype-face-regexp
  "^  .*\\(\\.git\\|\\.svn\\|~\\|#\\|%\\|\\.tmp\\|\\$DATA\\|:encryptable\\|\\.db_encryptable\\)$"
  "omit2"
  "backup or cache")

(deffiletype-face-regexp " \\.\\(.*$\\)" "omit3" "hidden")

(deffiletype-face "rich document" "DarkCyan" "document")

(deffiletype-face-regexp
  "^  .*\\.\\(pdf\\|chm\\|CHM\\|tex\\|doc\\|docx\\|xls\\|xlsx\\|ppt\\|pptx\\|odt\\|ott\\|rtf\\|sdw\\|ods\\|sxc\\|odp\\|otp\\|sdx\\|kdh\\|shx\\)$"
  "document"
  "rich document")

(deffiletype-face "plain text" "MediumPurple" "plain")

(deffiletype-face-regexp
  "^  .*\\.\\(TXT\\|txt\\|Txt\\|ini\\|INI\\|lrc\\|org\\|log\\|conf\\|CFG\\|cfg\\|properties\\|config\\|diff\\|patch\\|ebuild\\|inf\\|cnf\\|example\\|sample\\|default\\|m4\\)$"
  "plain"
  "plain text")

(deffiletype-face "common" "Peru")

(deffiletype-face-regexp
  "^  .*\\(configure\\|INSTALL\\|README\\|readme\\|COPYING\\|CHANGES\\|LICENSE\\|ChangeLog\\|Makefile.in\\|MANIFEST.MF\\|NOTICE.txt\\|build.xml\\|Manifest\\|metadata.xml\\|install-sh\\|NEWS\\|HACKING\\|AUTHORS\\|todo\\|Todo\\|TODO\\|makefile\\|TAGS\\|tag\\)$"
  "common")

(deffiletype-face "XML" "Chocolate")

(deffiletype-face-regexp
  "^  .*\\.\\(html?\\|HTML?\\|xml\\|XML\\|xsl\\|xsd\\|rng\\|dtd\\|mht\\|jsp\\|asp\\|js\\|xaml\\)$"
  "xml"
  "XML")

(deffiletype-face "compressed" "Orchid" "compress")

(deffiletype-face-regexp
  "^  .*\\.\\(tar\\|zip\\|ZIP\\|rar\\|RAR\\|tgz\\|gz\\|bzip2\\|bz2\\|7z\\|7Z\\|Z\\|z\\|xz\\|XZ\\|rpm\\|deb\\|lzma\\|cab\\|gzip\\|taz\\|wim\\|iso\\|tbz2\\|xar\\|XAR\\|jar\\|war\\|img\\)$"
  "compress"
  "compressed")

(deffiletype-face "source code" "SpringGreen" "source")

(deffiletype-face-regexp
  "^  .*\\.\\(c\\|cpp\\|java\\|JAVA\\|C\\|php\\|h\\|rb\\|pl\\|css\\|el\\|lua\\|sql\\|ahk\\|cs\\|erl\\|hrl\\|go\\)$"
  "source"
  "source code")

(deffiletype-face "executable" "green" "execute")

(deffiletype-face-regexp
  "^  .*\\.\\(exe\\|EXE\\|bat\\|BAT\\|msi\\|MSI\\|\\|sh\\|run\\|reg\\|REG\\|com\\|COM\\|\\|vbx\\|VBX\\|bin\\|xpi\\|bundle\\)$"
  "execute"
  "executable")

(deffiletype-face "music" "SteelBlue")

(deffiletype-face-regexp
  "^  .*\\.\\(mp3\\|MP3\\|wma\\|WMA\\|wav\\|WAV\\|mid\\|MID\\|ogg\\|OGG\\|aac\\|AAC\\|flac\\|FLAC\\|m4a\\|M4A\\)$"
  "music")

(deffiletype-face "video" "SandyBrown")

(deffiletype-face-regexp
  "^  .*\\.\\(flv\\|FLV\\|avi\\|AVI\\|mkv\\|rmvb\\|RMVB\\|mpeg\\|mpg\\|MPG\\|rm\\|RM\\|mp4\\|wmv\\|WMV\\|m4v\\|mov\\|ogm\\|ogv\\|3gp\\|f4v\\|swf\\|webm\\|divx\\|xvid\\|rm\\)$"
  "video")

(deffiletype-face "image" "MediumPurple")

(deffiletype-face-regexp
  "^  .*\\.\\(gif\\|GIF\\|jpg\\|JPG\\|bmp\\|BMP\\|jpeg?\\|JPEG?\\|png\\|PNG\\|xpm\\|svg\\|icns\\|odg\\|tiff?\\|epsf?\\|icon?\\|pict?\\|tga\\|pcx\\|xbm\\)$"
  "image")

(deffiletype-face
  "link"
  '((((class color) (background dark)) :foreground "yellow" :background "forest green") (t ()))
  "lnk")

(deffiletype-face-regexp
  "^  .*\\.\\(lnk\\|LNK\\|desktop\\|torrent\\|url\\|URL\\)$"
  "lnk" "link")

;;; Custom ends here.

(defmacro deffiletype-setup (type &optional type-for-docstring type-for-symbol type-for-face)
  "Declare a function to tell dired how to display TYPE files.
If not nil, use TYPE-FOR-DOCSTRING instead of TYPE for documentation.
If not nil, use TYPE-FOR-SYMBOL instead of TYPE to derive the function symbol.
If not nil, use TYPE-FOR-FACE instead of TYPE to derive the symbol for the associated face."
  (let
    (
      (funcsym
        (intern (format "dired-filetype-set-%s-face" (downcase (or type-for-symbol type))))
      )
    )
    `(progn
       (defun ,funcsym ()
         ,(format "Set dired-filetype-face for %s files." (or type-for-docstring type))
         (font-lock-add-keywords
           nil
           (list
             (cons
               ,(intern (format "dired-filetype-%s-regexp" (downcase type)))
               '((".+"
                  (dired-move-to-filename)
                  nil
                  (0
                    (quote
                      ,(intern
                        (concat
                          "dired-filetype-"
                          (downcase (or type-for-face type))))))))))))
       (add-hook 'dired-filetype-setup-hook #',funcsym))))

(deffiletype-setup "document" "rich document")

(deffiletype-setup "plain" "plain text")

(deffiletype-setup "common")

(deffiletype-setup "XML")

(deffiletype-setup "compress" "compressed")

(deffiletype-setup "source" "source code")

(deffiletype-setup "omit1" "unimportant" "omit" "omit")

(deffiletype-setup "omit2" "backup and cache" nil "omit")

(deffiletype-setup "omit3" "hidden" nil "omit")

(deffiletype-setup "execute" "executable" "exe")

(deffiletype-setup "music" "audio")

(deffiletype-setup "video")

(deffiletype-setup "image")

(deffiletype-setup "lnk" "link")

;;;###autoload
(defun dired-filetype-setup()
  (run-hooks 'dired-filetype-setup-hook))

;;;###autoload(add-hook 'dired-mode-hook 'dired-filetype-setup)
(add-hook 'dired-mode-hook 'dired-filetype-setup)
;;;###autoload(add-hook 'wdired-mode-hook 'dired-filetype-setup)
(add-hook 'wdired-mode-hook 'dired-filetype-setup)

(defadvice dired-toggle-read-only (after  dired-filetype-face activate)
  "set different faces for different file type."
  (dired-filetype-setup))

(defadvice wdired-exit (after dired-filetype-face activate)
  "set different faces for different file type."
  (dired-filetype-setup))

(defadvice wdired-finish-edit (after dired-filetype-face activate)
  "set different faces for different file type."
  (dired-filetype-setup))

(defadvice wdired-abort-changes (after dired-filetype-face activate)
  "set different faces for different file type."
  (dired-filetype-setup))

(provide 'dired-filetype-face)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; dired-file-type-face end here

(define-key dired-mode-map (kbd "C-s") 'dired-isearch-forward)
(define-key dired-mode-map (kbd "C-r") 'dired-isearch-backward)
(define-key dired-mode-map (kbd "M-C-s") 'dired-isearch-forward-regexp)
(define-key dired-mode-map (kbd "M-C-r") 'dired-isearch-backward-regexp)

(define-key dired-mode-map (kbd "s-r") 'dired-efap)

(eval-after-load 'dired '(progn (require 'dired-filetype-face)))
(setq dired-recursive-deletes 'top)

;; dired-single
(defun my-dired-init ()
  (define-key dired-mode-map [return] 'dired-single-buffer)
  (define-key dired-mode-map [mouse-1] 'dired-single-buffer-mouse)
  (define-key dired-mode-map "^"
    (function
     (lambda nil (interactive) (dired-single-buffer "..")))))

(if (boundp 'dired-mode-map)
    (my-dired-init)
  (add-hook 'dired-load-hook 'my-dired-init))

(global-set-key [(f5)] 'dired-single-magic-buffer)
(global-set-key [(control f5)] (function
                                (lambda nil (interactive)
                                  (dired-single-magic-buffer default-directory))))
(global-set-key [(shift f5)] (function
                              (lambda nil (interactive)
                                (message "Current directory is: %s" default-directory))))

;; dired-color

;; 定义几种文件扩展名
;;(defvar text-file-name-extensions
	;;(purecopy '("txt" "md" "org")))
;;(defvar doc-file-name-extensions
	;;(purecopy '("pdf" "doc" "docx" "xls" "xlsx" "ppt" "xml" "htm" "html")))
;;(defvar code-file-name-extensions
	;;(purecopy '("h" "c" "cxx" "cpp" "el" "pl" "py" "pm" "el")))
;;(defvar audio-file-name-extensions
	;;(purecopy '("mp3" "ogg" "wav" "wma" "flac" "aac" "ape" "aif")))
;;(defvar video-file-name-extensions
	;;(purecopy '("mp4" "mov" "mkv" "avi" "rmvb" "rm" "wmv" "3gp" "vob"
							;;"mpg" "mpeg" "divx" "ogm" "ogv" "asf" "flv" "webm")))
 ;;
;; 使用 dired-rainbow 定义 dired 的颜色
;;(dired-rainbow-define text "#78675D"
  										;;text-file-name-extensions)
;;(dired-rainbow-define doc "#4FBDF2"
  										;;doc-file-name-extensions)
;;(dired-rainbow-define code "#2AA19D"
  										;;code-file-name-extensions)
;;(dired-rainbow-define audio "#6638F0"
  										;;audio-file-name-extensions)
;;(dired-rainbow-define video "#F78AE0"
  ;;										video-file-name-extensions)

;; mpv player
(define-key dired-mode-map (kbd "P")
	(lambda () (interactive)
		(mpv-play (expand-file-name (dired-file-name-at-point)))))

;; image-dired
(define-key dired-mode-map (kbd "I")
  (lambda () (interactive)
    (image-dired (expand-file-name (dired-file-name-at-point)))))

(add-hook 'image-mode-hook
          (lambda ()
            (define-key image-mode-map (kbd "j")
              'cua-scroll-up)
            (define-key image-mode-map (kbd "k")
              'cua-scroll-down)
            (define-key image-mode-map (kbd "n")
              'image-dired-next-line)
            (define-key image-mode-map (kbd "p")
              'image-dired-previous-line)))

(add-hook 'image-mode-hook
          (lambda ()
            (define-key image-mode-map (kbd "q")
              (lambda () (interactive)
                (quit-window t)))))

(add-hook 'dired-mode-hook
          (lambda ()
						(setq dired-omit-files "^.DS_Store\\|^._")
            (dired-omit-mode 1)))

;; provide
(provide 'init-dired)
;;; init-dired.el ends here
