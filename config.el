;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-acario-dark)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This is mostly for emacs forge
(setq auth-sources '("~/.authinfo"))

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(defvar openai-api-key (getenv "OPENAI_KEY") 
  "Your OpenAI API key. Set this before using `openai-elixir-replace-region`.")

(defun ascii-only (s)
  "Strip all non-ASCII characters from S."
  (replace-regexp-in-string "[^\x00-\x7F]" "" s))

;; (defun write-clojure ()
;;   "Send the current line to OpenAI and replace it with generated Clojure code."
;;   (interactive)
;;   (ask-openai
;;    "Write me some Clojure code that does the following. \
;;         No yapping, markdown is forbidden, backticks are forbidden"))

(defun write-elisp ()
  "Send the current line to OpenAI and replace it with generated Elisp code."
  (interactive)
  (ask-openai
   "Write me some Elisp that does the following. \
        No yapping, markdown is forbidden, backticks are forbidden"))

(defun write-elixir ()
  "Send the current line to OpenAI and replace it with generated Elixir code."
  (interactive)
  (ask-openai
   "Write me some Elixir that does the following. \
        No yapping, markdown is forbidden, backticks are forbidden, \
        no module declaration—just an isolated function declaration: def name_of_function etc."))

(defun ask-with-context ()
  (interactive)
  (let ((highlighted-content (buffer-substring (region-beginning) (region-end))))
    (ask-openai highlighted-content)))

(defun ask-openai (&optional base-prompt)
  "Send the current line to OpenAI attached to the given base-prompt"
  (interactive)
  (let ((api-key (getenv "OPENAI_KEY")))
    (unless api-key
      (error "Environment variable OPENAI_KEY is not set"))

    (let* ((line-start (line-beginning-position))
           (line-end (line-end-position))
           (line-text (buffer-substring-no-properties line-start line-end))
           (prompt (ascii-only (format "%s : %s" (or base-prompt "") line-text)))
           (url "https://api.openai.com/v1/chat/completions")
           (url-request-method "POST")
           (url-request-extra-headers `(("Content-Type" . "application/json")
                                        ("Authorization" . ,(concat "Bearer " api-key))))
           (url-request-data
            (json-encode `(("model" . "gpt-3.5-turbo")
                           ("messages" . [(("role" . "user") ("content" . ,prompt))])
                           ("temperature" . 0.2))))
           (origin-buffer (current-buffer)))

      (url-retrieve
       url
       (lambda (status)
         (goto-char (point-min))
         (re-search-forward "^$" nil 'move) ;; Skip HTTP headers
         (let* ((json-object-type 'alist)
                (json-array-type 'list)
                (json-key-type 'symbol)
                (parsed (ignore-errors (json-read))))
           ;; (with-temp-file "boom.txt"
           ;; (prin1 parsed (current-buffer)))
           ;; (prin1 "THIS IS THE STATUS " status)
           (if (not parsed)
               (message "Failed to parse JSON response.")
             (let* ((choices (alist-get 'choices parsed))
                    (first (and (listp choices) (car choices)))
                    (msg (alist-get 'message first))
                    (content (alist-get 'content msg)))
               (if (not (stringp content))
                   (message "No usable content in OpenAI response: %S" parsed)
                 (with-current-buffer origin-buffer
                   (save-excursion
                     (goto-char line-start)
                     (delete-region line-start line-end)
                     (insert content)))))))
         (kill-buffer))
       nil t))))

(defun run-r-commands ()
  (interactive)
  (ess-eval-linewise "png(\"myplot.png\")")
  (ess-eval-linewise "plot(1:10)")
  (ess-eval-linewise "dev.off()")
  (image-dired "myplot.png"))



(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu) ; Set your favorite keybinding
  :config
  (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools

(defun my/claude-follow-open-file (&rest _)
  "After Claude opens a file via MCP, display it in the main editing window."
  (when-let* ((buf (current-buffer))
              (file (buffer-file-name buf)))
    (when-let ((main-window
                (cl-find-if (lambda (w)
                              (not (window-parameter w 'window-side)))
                            (window-list))))
      (set-window-buffer main-window buf))))

(advice-add 'claude-code-ide-mcp-handle-open-file
            :after #'my/claude-follow-open-file)

(defun guzzle-buffer ()
  "Copy current buffer to clipboard."
  (interactive)
  (kill-new (buffer-string))
  (message "Buffer contents copied to clipboard"))

(defun clear-buffer ()
  "Clear the current buffer"
  (interactive)
  (delete-region (point-min) (point-max)))

(map! :leader
      ;; Buffers
      (:prefix ("b" . "buffers")
       :desc "Guzzle buffer"     "g" #'guzzle-buffer
       :desc "Clear buffer"      "x" #'clear-buffer)

      (:prefix ("d" . "dired")
       :desc "New file" "n" #'dired-create-empty-file)
      
      (:prefix ("e", "lsp")
       :desc "Describe thing at point" "d" #'lsp-describe-thing-at-point)

      ;; LLM interop
      (:prefix ("l" . "llm")
       :desc "Ask with context"  "h" #'ask-with-context
       :desc "Write Elixir"      "x" #'write-elixir
       :desc "Write Elisp"       "e" #'write-elisp)

      ;; Windows
      (:prefix ("w" . "windows")
       :desc "Ace window"        "a" #'ace-window)

      ;; Shells & tools
      (:prefix ("s" . "shells")
       :desc "ANSI term"         "a" #'ansi-term
       :desc "CIDER jack-in"     "c" #'cider-jack-in
       :desc "Eshell"            "e" #'eshell
       :desc "VTerm"             "v" #'vterm))


