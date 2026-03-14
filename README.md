# buffer-guardian.el - Automatically Save Emacs Buffers Without Manual Intervention (When Buffers Lose Focus, Regularly, or After Emacs is Idle)
![Build Status](https://github.com/jamescherti/buffer-guardian.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/buffer-guardian.el)
![](https://jamescherti.com/misc/made-for-gnu-emacs.svg)

The **buffer-guardian** package provides `buffer-guardian-mode`, a global mode that automatically saves buffers without requiring manual intervention.

**By default, `buffer-guardian-mode` saves a buffer when:**
- Switching to another buffer.
- Switching to another window or frame.
- The mouse pointer leaves the current window.
- The minibuffer is opened.
- Emacs loses focus.

In addition to regular file-visiting buffers, `buffer-guardian-mode` also handles specialized editing buffers used for inline code blocks, such as `org-src` (for Org mode) and `edit-indirect` (commonly used for Markdown source code blocks). These temporary buffers are linked to an underlying parent buffer. Automatically saving them ensures that modifications made within these isolated code environments are correctly propagated back to the original Org or Markdown file.

## Features

Features enabled by default:
* Save the current buffer when switching to another buffer. (Variable: `buffer-guardian-save-on-buffer-switch`)
* Save the current buffer when switching to another window or frame. (Variable: `buffer-guardian-save-on-window-change`)
* Save the current buffer when the mouse pointer leaves its window. (Variable: `buffer-guardian-save-on-mouse-leave`)
* Save the current buffer when the minibuffer is opened. (Variable: `buffer-guardian-save-on-minibuffer`)
* Save all modified buffers when Emacs loses focus. (Variable: `buffer-guardian-save-on-focus-loss`)

Features disabled by default:
* Save all file-visiting buffers periodically at a specific interval. (Variable: `buffer-guardian-save-all-buffers-interval`)
* Save all file-visiting buffers after a period of user inactivity. (Variable: `buffer-guardian-save-all-buffers-idle`)
* Prevent auto-saving remote files. (Variable: `buffer-guardian-inhibit-saving-remote-files`)
* Prevent saving files that do not exist on disk. (Variable: `buffer-guardian-inhibit-saving-nonexistent-files`)
* Set a maximum buffer size limit for auto-saving. (Variable: `buffer-guardian-max-buffer-size`)
* Ignore buffers whose names match specific regular expressions. (Variable: `buffer-guardian-exclude-regexps`)
* Use custom predicate functions to determine if a buffer should be saved. (Variable: `buffer-guardian-predicate-functions`)

## Installation

### Emacs: use-package and straight (Emacs version < 30)

To install *buffer-guardian* with `straight.el`:

1. It if hasn't already been done, [add the straight.el bootstrap code](https://github.com/radian-software/straight.el?tab=readme-ov-file#getting-started) to your init file.
2. Add the following code to the Emacs init file:
```emacs-lisp
(use-package buffer-guardian
  :straight (buffer-guardian
             :type git
             :host github
             :repo "jamescherti/buffer-guardian.el")

  :custom
  ;; When non-nil, include remote files in the auto-save process
  (buffer-guardian-inhibit-saving-remote-files t)
  ;; When set to nil, buffers visiting nonexistent files can still be saved.
  (buffer-guardian-inhibit-saving-nonexistent-files t)

  :hook
  (after-init . buffer-guardian-mode))
```

### Alternative installation: use-package and :vc (Built-in feature in Emacs version >= 30)

To install *buffer-guardian* with `use-package` and `:vc` (Emacs >= 30):

``` emacs-lisp
(use-package buffer-guardian
  :vc (:url "https://github.com/jamescherti/buffer-guardian.el"
       :rev :newest)

  :custom
  ;; When non-nil, include remote files in the auto-save process
  (buffer-guardian-inhibit-saving-remote-files t)
  ;; When set to nil, buffers visiting nonexistent files can still be saved.
  (buffer-guardian-inhibit-saving-nonexistent-files t)

  :hook
  (after-init . buffer-guardian-mode))
```

### Alternative installation: Doom Emacs

Here is how to install *buffer-guardian* on Doom Emacs:

1. Add to the `~/.doom.d/packages.el` file:
```elisp
(package! buffer-guardian
  :recipe
  (:host github :repo "jamescherti/buffer-guardian.el"))
```

2. Add to `~/.doom.d/config.el`:
```elisp
(after! buffer-guardian
  ;; When non-nil, include remote files in the auto-save process
  (setq buffer-guardian-inhibit-saving-remote-files t)
  ;; When set to nil, buffers visiting nonexistent files can still be saved.
  (setq buffer-guardian-inhibit-saving-nonexistent-files t)

  (buffer-guardian-mode))
```

3. Run the `doom sync` command:
```
doom sync
```

## Configuration

You can customize `buffer-guardian` to fit your workflow. Below are the main customization variables:

### Triggers

* `buffer-guardian-save-on-focus-loss` (Default: `t`): Save when Emacs loses focus.
* `buffer-guardian-save-on-minibuffer` (Default: `t`): Save when the minibuffer opens.
* `buffer-guardian-save-on-buffer-switch` (Default: `t`): Save when `window-buffer-change-functions` runs.
* `buffer-guardian-save-on-window-change` (Default: `t`): Save when `window-selection-change-functions` runs.
* `buffer-guardian-save-on-mouse-leave` (Default: `t`): Save the current buffer when the mouse pointer leaves its window.

### Timers

* `buffer-guardian-save-all-buffers-interval` (Default: `nil`): Save all buffers periodically every N seconds.
* `buffer-guardian-save-all-buffers-idle` (Default: `nil`): Save all buffers after N seconds of user idle time.

### Exclusions and Filters

* `buffer-guardian-inhibit-saving-remote-files` (Default: `t`): Prevent auto-saving remote files.
* `buffer-guardian-inhibit-saving-nonexistent-files` (Default: `t`): Prevent saving files that do not exist on disk.
* `buffer-guardian-exclude-regexps` (Default: `nil`): A list of regular expressions for file names to ignore.
* `buffer-guardian-max-buffer-size` (Default: `nil`): Maximum buffer size (in characters) to save. Set to 0 or nil to disable.
* `buffer-guardian-predicate-functions` (Default: `nil`): List of predicate functions to determine if a buffer should be saved.

### Specialized Buffers (Inline Code Blocks)

* `buffer-guardian-handle-org-src` (Default: `t`): Enable automatic saving for `org-src` buffers.
* `buffer-guardian-handle-edit-indirect` (Default: `t`): Enable automatic saving for `edit-indirect` buffers.

### Advanced

* `buffer-guardian-save-all-trigger-hooks`: A list of hooks that trigger saving all modified buffers. Defaults to `'(mouse-leave-buffer-hook)`.
* `buffer-guardian-functions-auto-save-current-buffer`: A list of functions to advise. A `:before` advice will save the current buffer before these functions execute.
* `buffer-guardian-verbose` (Default: `nil`): Enable logging messages when a buffer is saved.

## Author and License

The *buffer-guardian* Emacs package has been written by [James Cherti](https://www.jamescherti.com/) and is distributed under terms of the GNU General Public License version 3, or, at your choice, any later version.

Copyright (C) 2026 James Cherti

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- [buffer-guardian.el @GitHub](https://github.com/jamescherti/buffer-guardian.el)
