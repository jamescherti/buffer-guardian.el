;;; buffer-guardian.el --- Save your work without thinking about it -*- lexical-binding: t -*-

;; Author: James Cherti
;; URL: https://github.com/jamescherti/jc-dev
;; Package-Requires: ((emacs "29.1"))
;; Keywords: maint
;; Version: 0.0.9
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; The `buffer-guardian' package provides a global mode that automatically saves
;; buffers without requiring manual intervention.
;;
;; By default, it saves a buffer when the user:
;; - Switches to another buffer or window
;; - Emacs loses focus
;; - The minibuffer is opened
;;
;; In addition to regular file buffers, `buffer-guardian' also handles
;; specialized editing buffers such as `org-src' and `edit-indirect'. These
;; buffers are temporary editing environments that are linked to another
;; underlying buffer.
;;
;; Other feature that are disabled by default:
;; - Excludes remote files, nonexistent files, and very large files by default
;; - Supports custom exclusion rules using regular expressions or predicate
;;   functions

;;; Code:

(require 'seq)

(defgroup buffer-guardian nil
  "Customization options for `buffer-guardian-mode'."
  :group 'buffer-guardian
  :prefix "buffer-guardian-")

(defcustom buffer-guardian-verbose nil
  "Enable verbose mode to log when a buffer is automatically saved."
  :type 'boolean
  :group 'buffer-guardian)

(defcustom buffer-guardian-save-on-focus-loss t
  "Save the current buffer when Emacs loses focus."
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if (and value (bound-and-true-p buffer-guardian-mode))
             (add-function :after after-focus-change-function
                           #'buffer-guardian--on-focus-change)
           (remove-function after-focus-change-function
                            #'buffer-guardian--on-focus-change)))
  :group 'buffer-guardian)

(defcustom buffer-guardian-save-on-minibuffer t
  "Save the current buffer when the minibuffer is opened."
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if (and value (bound-and-true-p buffer-guardian-mode))
             (add-hook 'minibuffer-setup-hook
                       #'buffer-guardian--minibuffer-setup-hook)
           (remove-hook 'minibuffer-setup-hook
                        #'buffer-guardian--minibuffer-setup-hook)))
  :group 'buffer-guardian)

(defcustom buffer-guardian-save-on-buffer-change t
  "Save the current buffer when `window-buffer-change-functions' runs."
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if (and value (bound-and-true-p buffer-guardian-mode))
             (add-hook 'window-buffer-change-functions
                       #'buffer-guardian--window-buffer-change-functions)
           (remove-hook 'window-buffer-change-functions
                        #'buffer-guardian--window-buffer-change-functions)))
  :group 'buffer-guardian)

(defcustom buffer-guardian-save-on-window-change t
  "Save the current buffer when `window-selection-change-functions' runs."
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if (and value (bound-and-true-p buffer-guardian-mode))
             (add-hook 'window-selection-change-functions
                       #'buffer-guardian--window-selection-change)
           (remove-hook 'window-selection-change-functions
                        #'buffer-guardian--window-selection-change)))
  :group 'buffer-guardian)

(defvar buffer-guardian--save-all-buffers-timer nil
  "Internal Timer object for saving all buffers.")

(defvar buffer-guardian--save-all-buffers-idle-timer nil
  "Internal timer object for saving all buffers when the user is idle.")

(defcustom buffer-guardian-save-all-buffers-interval nil
  "Interval in seconds for automatically saving all buffers.
This allows you to periodically save all file visiting buffers at once,
repeating the operation at the specified interval.

If set to nil, this feature is disabled."
  :type '(choice (integer :tag "Seconds")
                 (const :tag "Disabled" nil))
  :set (lambda (symbol value)
         (set-default symbol value)
         (when buffer-guardian--save-all-buffers-timer
           (cancel-timer buffer-guardian--save-all-buffers-timer)
           (setq buffer-guardian--save-all-buffers-timer nil))
         (when (and value (bound-and-true-p buffer-guardian-mode))
           (setq buffer-guardian--save-all-buffers-timer
                 (run-with-timer value value #'buffer-guardian-save-all-buffers))))
  :group 'buffer-guardian)

(defcustom buffer-guardian-save-all-buffers-idle nil
  "Seconds for automatically saving all buffers when the user is idle.
This allows you save all file visiting buffers at once, repeating the operation
at the specified interval.

If set to nil, this feature is disabled."
  :type '(choice (integer :tag "Seconds")
                 (const :tag "Disabled" nil))
  :set (lambda (symbol value)
         (set-default symbol value)
         (when buffer-guardian--save-all-buffers-idle-timer
           (cancel-timer buffer-guardian--save-all-buffers-idle-timer)
           (setq buffer-guardian--save-all-buffers-idle-timer nil))
         (when (and value (bound-and-true-p buffer-guardian-mode))
           (setq buffer-guardian--save-all-buffers-idle-timer
                 (run-with-idle-timer value value #'buffer-guardian-save-all-buffers))))
  :group 'buffer-guardian)

(defcustom buffer-guardian-inhibit-saving-remote-files t
  "If non-nil, `buffer-guardian' will not auto-save remote files.
When set to nil, remote files will be included in the auto-save process. This
setting is used by `buffer-guardian-predicate'."
  :type 'boolean
  :group 'buffer-guardian)

(defcustom buffer-guardian-inhibit-saving-nonexistent-files t
  "If non-nil, `buffer-guardian' will not save files that do not exist on disk.
When set to nil, buffers visiting nonexistent files can still be saved.
This setting is used by `buffer-guardian-predicate'."
  :type 'boolean
  :group 'buffer-guardian)

(defcustom buffer-guardian-exclude nil
  "A list of regexps for buffer file name excluded from buffer-guardian.
When a buffer file name matches any of the regexps it is ignored."
  :group 'buffer-guardian
  :type '(repeat regexp))

(defcustom buffer-guardian-max-buffer-size nil
  "Maximal size of buffer (in characters), for which buffer-guardian work.
Exists mostly because saving constantly huge buffers can be slow in some cases.
Set to 0 or nil to disable."
  :group 'buffer-guardian
  :type 'integer)

(defcustom buffer-guardian-predicates nil
  "Predicates, which return nil, when the buffer doesn't need to be saved.
Predicate functions don't take any arguments. If a predicate doesn't know
whether this buffer needs to be saved or not, then it must return t."
  :group 'buffer-guardian
  :type '(repeat function))

(defcustom buffer-guardian-hooks-auto-save-all-buffers
  '(mouse-leave-buffer-hook)
  "List of hook symbols that trigger saving of all modified buffers.

When any of these hooks run, all buffers are saved. For example, to ensure that
work is not lost when Emacs loses focus or the mouse leaves the current buffer."
  :group 'buffer-guardian
  :type '(repeat symbol)
  :set (lambda (symbol value)
         (let ((old-value (when (boundp symbol)
                            (default-value symbol))))
           (set-default symbol value)
           (when old-value
             (dolist (hook old-value)
               (remove-hook hook #'buffer-guardian-save-all-buffers)))
           (when (bound-and-true-p buffer-guardian-mode)
             (dolist (hook value)
               (add-hook hook #'buffer-guardian-save-all-buffers))))))

(defvar buffer-guardian--list-advised-functions nil
  "Internal list of advised functions.")

(defcustom buffer-guardian-functions-auto-save-current-buffer nil
  "List of function symbols to be advised by `buffer-guardian'.

A :before advice will be added to each function in this list so that save the
current buffer before the function executes.

This mechanism allows automatic buffer saving to be triggered by specific
commands or operations (e.g., window switching or navigation).

Set this variable to nil to disable advising altogether."
  :group 'buffer-guardian
  :type '(repeat function)
  :set (lambda (symbol value)
         (let ((old-value (when (boundp symbol)
                            (default-value symbol))))
           (set-default symbol value)
           (when old-value
             (dolist (func old-value)
               (when (fboundp func)
                 (advice-remove func #'buffer-guardian--before-advice-save-current-buffer))))
           (setq buffer-guardian--list-advised-functions (copy-sequence value))
           (when (bound-and-true-p buffer-guardian-mode)
             (dolist (func value)
               (when (fboundp func)
                 (advice-add func :before #'buffer-guardian--before-advice-save-current-buffer)))))))

(defun buffer-guardian-exclude-p (filename)
  "Return non-nil if FILENAME matches any of the `buffer-guardian-exclude'."
  (seq-some (lambda (regexp)
              (string-match-p regexp filename))
            buffer-guardian-exclude))

(defun buffer-guardian-predicate (&optional include-non-file-visiting)
  "Determine if the current buffer should be automatically saved.

If INCLUDE-NON-FILE-VISITING is non-nil, the predicate recognizes and returns
specialized symbols for \='org-src and \='edit-indirect buffers.

Returns: \='org-src, \='edit-indirect, t, or nil."
  (let* ((file-name (buffer-file-name)))
    (when (and (buffer-modified-p)
               ;; Global Exclusion check first
               (not (buffer-guardian-exclude-p file-name)))
      (cond
       ;; Max size check
       ((and buffer-guardian-max-buffer-size
             (> buffer-guardian-max-buffer-size 0)
             (> (buffer-size) buffer-guardian-max-buffer-size))
        nil)

       ;; Specialized buffers
       ((and include-non-file-visiting
             (fboundp 'org-src-edit-buffer-p)
             (funcall 'org-src-edit-buffer-p))
        'org-src)

       ((and include-non-file-visiting
             (bound-and-true-p edit-indirect--overlay))
        'edit-indirect)

       ;; Standard File-visiting logic
       (file-name
        (and
         (if (file-remote-p file-name)
             (not buffer-guardian-inhibit-saving-remote-files)
           (file-writable-p file-name))
         (if buffer-guardian-inhibit-saving-nonexistent-files
             (file-exists-p file-name)
           t)))

       ;; Custom predicates
       ((seq-some (lambda (pred)
                    (condition-case err
                        (funcall pred)
                      (error
                       (display-warning 'buffer-guardian
                                        (format "Predicate failed: %S" err)
                                        :warning)
                       nil)))
                  buffer-guardian-predicates)
        t)))))

(defun buffer-guardian-save-buffer-maybe (&optional buffer)
  "Save BUFFER if it is visiting a file that is existing on the disk.
By default, it only saves when the file exists on the disk."
  (unless buffer
    (setq buffer (current-buffer)))
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (let ((predicate-result (buffer-guardian-predicate
                               :include-all-buffers)))
        (when predicate-result
          (cond
           ((and (eq predicate-result 'org-src)
                 (fboundp 'org-edit-src-save))
            (funcall 'org-edit-src-save))

           ((and (eq predicate-result 'edit-indirect)
                 (fboundp 'edit-indirect--commit))
            (funcall 'edit-indirect--commit))

           (predicate-result
            (let ((inhibit-message (not buffer-guardian-verbose)))
              (if (verify-visited-file-modtime (current-buffer))
                  (save-buffer)
                (message
                 (concat "[buffer-guardian] Warning: Automatic save skipped "
                         "for '%s' because the file was modified externally.")
                 (buffer-file-name (buffer-base-buffer)))))))

          (when buffer-guardian-verbose
            (message
             "[buffer-guardian] '%s'" (buffer-file-name (buffer-base-buffer)))))))))

(defun buffer-guardian-save-all-buffers (&optional buffer-list)
  "Save some modified buffers that are visiting files that exist on the disk.
BUFFER-LIST is the list of buffers."
  (dolist (buffer (or buffer-list (buffer-list)))
    (buffer-guardian-save-buffer-maybe buffer)))

;; TODO: add optional option to auto revert the buffer or never revert
(defun buffer-guardian-save-buffer ()
  "Save the current buffer.

If the buffer is visiting a file and has a base buffer, save that base buffer.

Before saving, check if the visited file has been modified outside of Emacs. If
so, prompt the user for confirmation and revert the buffer if confirmed. Then
save the buffer without prompting or displaying messages."
  (interactive)
  (let ((buffer (or (buffer-base-buffer) (current-buffer)))
        (file-name (buffer-file-name (buffer-base-buffer)))
        (buffer-guardian-inhibit-saving-nonexistent-files nil))
    (when buffer
      (cond
       (file-name
        (with-current-buffer buffer
          ;; Was the file modified outside of Emacs? Revert buffer
          (unless (verify-visited-file-modtime (current-buffer))
            (when (yes-or-no-p (format "Discard edits and reread from '%s'?"
                                       file-name))
              (revert-buffer :ignore-auto :noconfirm)))

          ;; Save buffer
          (buffer-guardian-save-buffer-maybe)))

       (t
        (buffer-guardian-save-buffer-maybe))))))

(defun buffer-guardian--before-advice-save-current-buffer (&rest _)
  "Save current buffers."
  (buffer-guardian-save-buffer-maybe (current-buffer)))

(defun buffer-guardian--on-focus-change ()
  "Run `buffer-guardian-save-all-buffers' when Emacs loses focus."
  (when (and buffer-guardian-save-on-focus-loss
             (not (frame-focus-state)))
    (buffer-guardian-save-all-buffers)))

(defun buffer-guardian--minibuffer-setup-hook ()
  "Save the buffer whenever the minibuffer is open."
  (when buffer-guardian-save-on-minibuffer
    (let* ((window (minibuffer-selected-window))
           (buffer (when window
                     (window-buffer window))))
      (when (buffer-live-p buffer)
        (buffer-guardian-save-buffer-maybe buffer)))))

(defvar buffer-guardian--previous-buffer nil)

(defun buffer-guardian--on-buffer-change (&optional object)
  "Function called by `window-buffer-change-functions'.
OBJECT can be a frame or a window."
  (let* ((is-frame (frame-live-p object))
         (frame (if is-frame
                    object
                  (selected-frame)))
         (window (cond
                  ;; Frame
                  (is-frame
                   (with-selected-frame object
                     (selected-window)))
                  ;; Window
                  ((window-live-p object)
                   object)
                  ;; Current window
                  (t
                   (selected-window)))))
    (when (and frame window)
      (with-selected-frame frame
        (with-selected-window window
          (when-let* ((buffer (window-buffer)))
            (when (and
                   (buffer-live-p buffer)
                   (or (not buffer-guardian--previous-buffer)
                       (not (eq buffer buffer-guardian--previous-buffer))))
              ;; Save previous buffers
              (when buffer-guardian--previous-buffer
                ;; (message "[BUFFER-WINDOW DEBUG] SAVE: %S"
                ;;          buffer-guardian--previous-buffer)

                (when (buffer-live-p buffer-guardian--previous-buffer)
                  (buffer-guardian-save-buffer-maybe
                   buffer-guardian--previous-buffer))

                ;; Reset
                (setq buffer-guardian--previous-buffer nil))

              ;; Push the current buffer
              (setq buffer-guardian--previous-buffer buffer))))))))

(defvar buffer-guardian--previous-window nil)

(defun buffer-guardian--window-buffer-change-functions (object)
  "Run on window change in OBJECT (frame or window)."
  (when (and buffer-guardian-save-on-buffer-change
             (bound-and-true-p buffer-guardian-mode))
    (buffer-guardian--on-buffer-change object)))

(defun buffer-guardian--window-selection-change (object)
  "Run on window change in OBJECT (frame or window)."
  (when (and buffer-guardian-save-on-window-change
             (bound-and-true-p buffer-guardian-mode))
    (buffer-guardian--on-buffer-change object)))

;;;###autoload
(define-minor-mode buffer-guardian-mode
  "Toggle `buffer-guardian-mode'."
  :global t
  :lighter " SaveAngel"
  :group 'buffer-guardian
  (let ((settings '(buffer-guardian-save-on-focus-loss
                    buffer-guardian-save-on-minibuffer
                    buffer-guardian-save-on-buffer-change
                    buffer-guardian-save-on-window-change
                    buffer-guardian-save-all-buffers-interval
                    buffer-guardian-save-all-buffers-idle
                    buffer-guardian-hooks-auto-save-all-buffers
                    buffer-guardian-functions-auto-save-current-buffer)))
    (dolist (setting settings)
      (funcall (or (get setting 'custom-set) #'set-default)
               setting (symbol-value setting)))))

;;; Provide

(provide 'buffer-guardian)

;;; buffer-guardian.el ends here
