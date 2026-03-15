;;; test-buffer-guardian.el --- Tests for buffer-guardian.el -*- lexical-binding: t -*-

;; Copyright (C) 2026 James Cherti | https://www.jamescherti.com/contact/

;; Author: James Cherti
;; Version: 0.9.9
;; URL: https://github.com/jamescherti/buffer-guardian.el
;; Keywords: convenience
;; Package-Requires: ((emacs "24.3"))
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
(require 'cl-lib)
(require 'buffer-guardian)

;;; Helpers

(defmacro with-test-buffer (name &rest body)
  "Create a temporary file-visiting buffer and run BODY."
  (declare (indent 1) (debug t))
  (let ((buf-var (make-symbol "buf")))
    `(let ((,buf-var (generate-new-buffer ,name))
           (buffer-guardian-inhibit-saving-nonexistent-files nil)
           (buffer-guardian-inhibit-saving-remote-files nil))
       (with-current-buffer ,buf-var
         (cl-letf (((symbol-function 'file-writable-p) (lambda (&rest _) t))
                   ((symbol-function 'file-exists-p) (lambda (&rest _) t))
                   ((symbol-function 'verify-visited-file-modtime) (lambda (&rest _) t)))
           ;; We must mock these so the predicate passes
           (setq buffer-file-name (expand-file-name ,name))
           (set-buffer-modified-p t)
           ;; Mock the visited time so verify-visited-file-modtime returns t
           (set-visited-file-modtime)
           (unwind-protect
               (progn ,@body)
             (when (buffer-live-p ,buf-var)
               (kill-buffer ,buf-var))))))))

;;; Test Cases - Predicate Logic

(ert-deftest test-buffer-guardian-predicate-logic ()
  "Test that the internal predicate correctly identifies what to save."
  (with-test-buffer "test-save.txt"
                    ;; Should save modified file-visiting buffer
                    (should (buffer-guardian--predicate))

                    ;; Should NOT save if not modified
                    (set-buffer-modified-p nil)
                    (should-not (buffer-guardian--predicate))

                    ;; Should NOT save if excluded by regexp
                    (set-buffer-modified-p t)
                    (let ((buffer-guardian-exclude-regexps '("\\.txt$")))
                      (should-not (buffer-guardian--predicate)))))

(ert-deftest test-buffer-guardian-max-buffer-size ()
  "Test that buffers exceeding `buffer-guardian-max-buffer-size' are not saved."
  (with-test-buffer "large-file.txt"
                    (insert "1234567890")
                    (let ((buffer-guardian-max-buffer-size 5))
                      (should-not (buffer-guardian--predicate)))
                    (let ((buffer-guardian-max-buffer-size 15))
                      (should (buffer-guardian--predicate)))))

(ert-deftest test-buffer-guardian-custom-predicates ()
  "Test the behavior of `buffer-guardian-predicate-functions'."
  (with-test-buffer "pred.txt"
                    (let ((buffer-guardian-predicate-functions (list (lambda () t))))
                      (should (buffer-guardian--predicate)))

                    (let ((buffer-guardian-predicate-functions (list (lambda () nil))))
                      (should-not (buffer-guardian--predicate)))

                    ;; Test error handling in predicates (should catch error and return nil/fail gracefully)
                    (let ((buffer-guardian-predicate-functions (list (lambda () (error "Mock error")))))
                      (cl-letf (((symbol-function 'display-warning) (lambda (&rest _) nil)))
                        (should-not (buffer-guardian--predicate))))))

;; (ert-deftest test-buffer-guardian-remote-files ()
;;   "Test saving logic for remote files."
;;   (with-test-buffer "/ssh:mock@remote:/test.txt"
;;                     (cl-letf (((symbol-function 'file-remote-p) (lambda (_) t))
;;                               ((symbol-function 'file-exists-p) (lambda (_) t)))
;;                       (let ((buffer-guardian-inhibit-saving-remote-files t))
;;                         (should-not (buffer-guardian--predicate)))
;;                       (let ((buffer-guardian-inhibit-saving-remote-files nil))
;;                         (should (buffer-guardian--predicate))))))

(ert-deftest test-buffer-guardian-nonexistent-files ()
  "Test saving logic for nonexistent files."
  (with-test-buffer "does-not-exist.txt"
                    (cl-letf (((symbol-function 'file-exists-p) (lambda (_) nil)))
                      (let ((buffer-guardian-inhibit-saving-nonexistent-files t))
                        (should-not (buffer-guardian--predicate)))
                      (let ((buffer-guardian-inhibit-saving-nonexistent-files nil))
                        (should (buffer-guardian--predicate))))))

(ert-deftest test-buffer-guardian-special-buffers ()
  "Test predicate resolution for org-src and edit-indirect buffers."
  (with-test-buffer "special.txt"
                    ;; Clear file name to simulate non-file-visiting buffer
                    (setq buffer-file-name nil)

                    ;; Org-src
                    (cl-letf (((symbol-function 'org-src-edit-buffer-p) (lambda () t)))
                      (let ((buffer-guardian-handle-org-src t))
                        (should (eq (buffer-guardian--predicate t) 'org-src)))
                      (let ((buffer-guardian-handle-org-src nil))
                        (should-not (buffer-guardian--predicate t))))

                    ;; Edit-indirect
                    (set (make-local-variable 'edit-indirect--overlay) t)
                    (let ((buffer-guardian-handle-edit-indirect t))
                      (should (eq (buffer-guardian--predicate t) 'edit-indirect)))
                    (let ((buffer-guardian-handle-edit-indirect nil))
                      (should-not (buffer-guardian--predicate t)))))

;;; Test Cases - Hooks and Triggers

(ert-deftest test-buffer-guardian-defensive-mode-check ()
  "Ensure save-all does nothing if buffer-guardian-mode is disabled."
  (let ((save-called nil))
    (with-test-buffer "defensive.txt"
                      (cl-letf (((symbol-function 'buffer-guardian-save-buffer-maybe)
                                 (lambda (&rest _) (setq save-called t))))
                        (setq buffer-guardian-mode nil)
                        (buffer-guardian-save-all-buffers)
                        (should-not save-called)

                        (setq buffer-guardian-mode t)
                        (buffer-guardian-save-all-buffers)
                        (should save-called)))))

(ert-deftest test-buffer-guardian-mouse-leave-trigger ()
  "Test that mouse-leave-buffer-hook triggers save."
  (let ((save-called nil))
    (setq buffer-guardian-mode t)
    (with-test-buffer "mouse.txt"
                      (cl-letf (((symbol-function 'save-buffer) (lambda (&rest _) (setq save-called t))))
                        (buffer-guardian--mouse-leave-buffer-hook)
                        (should save-called)))))

(ert-deftest test-buffer-guardian-window-change-logic ()
  "Test that switching windows saves the previous buffer."
  (let ((saved-bufs nil))
    (setq buffer-guardian-mode t)
    (setq buffer-guardian-save-on-window-change t)
    (with-test-buffer "buf-old.txt"
                      (let ((old-buf (current-buffer)))
                        (with-test-buffer "buf-new.txt"
                                          (let ((new-buf (current-buffer)))
                                            (setq buffer-guardian--previous-buffer old-buf)
                                            (cl-letf (((symbol-function 'save-buffer)
                                                       (lambda (&rest _) (push (current-buffer) saved-bufs))))
                                              (save-window-excursion
                                                (set-window-buffer (selected-window) new-buf)
                                                (buffer-guardian--on-buffer-change (selected-window)))
                                              (should (memq old-buf saved-bufs))
                                              (should (eq buffer-guardian--previous-buffer new-buf)))))))))

(ert-deftest test-buffer-guardian-focus-loss ()
  "Test that losing focus triggers a save-all."
  (let ((save-all-called nil))
    (setq buffer-guardian-mode t)
    (let ((buffer-guardian-save-on-focus-loss t))
      (cl-letf (((symbol-function 'buffer-guardian-save-all-buffers)
                 (lambda () (setq save-all-called t)))
                ((symbol-function 'frame-focus-state)
                 (lambda () nil))) ;; Simulate unfocused frame
        (buffer-guardian--on-focus-change)
        (should save-all-called)))))

;; (ert-deftest test-buffer-guardian-minibuffer-setup ()
;;   "Test that opening the minibuffer triggers a save on the selected window."
;;   (let ((saved-buffer nil))
;;     (setq buffer-guardian-mode t)
;;     (let ((buffer-guardian-save-on-minibuffer t))
;;       (with-test-buffer "mini.txt"
;;                         (cl-letf (((symbol-function 'buffer-guardian-save-buffer-maybe)
;;                                    (lambda (buf) (setq saved-buffer buf)))
;;                                   ((symbol-function 'minibuffer-selected-window)
;;                                    (lambda () (selected-window))))
;;                           (buffer-guardian--minibuffer-setup-hook)
;;                           (should (eq saved-buffer (current-buffer))))))))

(defun buffer-guardian-mock-cmd () nil)

(ert-deftest test-buffer-guardian-advised-functions ()
  "Test that advising functions successfully triggers a save."
  (let ((save-called nil))
    (setq buffer-guardian-mode t)
    (with-test-buffer "advised.txt"
                      (cl-letf (((symbol-function 'buffer-guardian-save-buffer-maybe)
                                 (lambda (&rest _) (setq save-called t))))
                        ;; Apply advice
                        (let ((buffer-guardian--list-advised-functions nil))
                          (custom-set-variables
                           '(buffer-guardian-functions-auto-save-current-buffer '(buffer-guardian-mock-cmd)))

                          (buffer-guardian-mock-cmd)
                          (should save-called)

                          ;; Cleanup advice
                          (custom-set-variables
                           '(buffer-guardian-functions-auto-save-current-buffer nil)))))))

;;; Test Cases - Save Execution Logic

(ert-deftest test-buffer-guardian-save-externally-modified ()
  "Test that buffer-guardian refuses to save externally modified files."
  (let ((save-called nil))
    (setq buffer-guardian-mode t)
    (with-test-buffer "external.txt"
                      (cl-letf (((symbol-function 'save-buffer) (lambda (&rest _) (setq save-called t)))
                                ((symbol-function 'verify-visited-file-modtime) (lambda (&rest _) nil)))
                        (buffer-guardian-save-buffer-maybe)
                        (should-not save-called)))))

(ert-deftest test-buffer-guardian-save-special-buffers ()
  "Test execution of special buffer save functions."
  (let ((org-saved nil)
        (indirect-saved nil))
    (setq buffer-guardian-mode t)
    (cl-letf (((symbol-function 'org-edit-src-save) (lambda () (setq org-saved t)))
              ((symbol-function 'edit-indirect--commit) (lambda () (setq indirect-saved t))))

      ;; Test Org-src save execution
      (with-test-buffer "org-src"
                        (setq buffer-file-name nil)
                        (cl-letf (((symbol-function 'buffer-guardian--predicate) (lambda (_) 'org-src)))
                          (buffer-guardian-save-buffer-maybe)
                          (should org-saved)))

      ;; Test edit-indirect save execution
      (with-test-buffer "edit-indirect"
                        (setq buffer-file-name nil)
                        (cl-letf (((symbol-function 'buffer-guardian--predicate) (lambda (_) 'edit-indirect)))
                          (buffer-guardian-save-buffer-maybe)
                          (should indirect-saved))))))

(provide 'test-buffer-guardian)
;;; test-buffer-guardian.el ends here
