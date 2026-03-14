;;; buffer-guardian.el --- Save your work without thinking about it -*- lexical-binding: t; -*-

;; Copyright (C) 2026 James Cherti | https://www.jamescherti.com/contact/

;; Author: James Cherti
;; Version: 0.9.9
;; URL: https://github.com/jamescherti/buffer-guardian.el
;; Keywords: convenience
;; Package-Requires: ((emacs "24.1"))
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
;; Save your work without thinking about it.

;;; Code:

(defgroup buffer-guardian nil
  "Save your work without thinking about it"
  :group 'buffer-guardian
  :prefix "buffer-guardian-"
  :link '(url-link
          :tag "Github"
          "https://github.com/jamescherti/buffer-guardian.el"))

(defcustom buffer-guardian-verbose nil
  "Enable displaying verbose messages."
  :type 'boolean
  :group 'buffer-guardian)

(defun buffer-guardian--message (&rest args)
  "Display a message with the same ARGS arguments as `message'."
  (apply #'message (concat "[buffer-guardian] " (car args)) (cdr args)))

(defmacro buffer-guardian--verbose-message (&rest args)
  "Display a verbose message with the same ARGS arguments as `message'."
  (declare (indent 0) (debug t))
  `(progn
     (when buffer-guardian-verbose
       (buffer-guardian--message
        (concat ,(car args)) ,@(cdr args)))))

;;;###autoload
(define-minor-mode buffer-guardian-mode
  "Toggle `buffer-guardian-mode'."
  :global t
  :lighter " buffer-guardian"
  :group 'buffer-guardian
  (if buffer-guardian-mode
      t
    t))

(provide 'buffer-guardian)
;;; buffer-guardian.el ends here
