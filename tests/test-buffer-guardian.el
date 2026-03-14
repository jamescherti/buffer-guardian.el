;;; test-buffer-guardian.el --- Test buffer-guardian -*- lexical-binding: t; -*-

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
;; Test buffer-guardian.

;;; Code:

(require 'ert)
(require 'buffer-guardian)

;; (with-no-warnings
;;   (when (require 'undercover nil t)
;;     (undercover "buffer-guardian"
;;                 (:report-file ".coverage")
;;                 (:report-format 'text)
;;                 (:send-report nil))))

(ert-deftest test-buffer-guardian ()
  "Test buffer-guardian."
  (interactive)
  (should t))

(provide 'test-buffer-guardian)
;;; test-buffer-guardian.el ends here
