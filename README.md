# buffer-guardian.el - Save your work without thinking about it
![Build Status](https://github.com/jamescherti/buffer-guardian.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/buffer-guardian.el)
![](https://jamescherti.com/misc/made-for-gnu-emacs.svg)

The `buffer-guardian` package provides a global mode that automatically saves your buffers based on events, timers, and focus changes, ensuring you never lose your progress.

## Features

* Saves the current buffer when Emacs loses focus.
* Saves when opening the minibuffer.
* Saves upon window selection or buffer changes.
* Saves all buffers on a periodic interval or when Emacs is idle.
* Excludes remote files, nonexistent files, or huge files by default.
* Allows custom exclusion rules using regular expressions or predicate functions.
* Supports specialized buffers like `org-src` and `edit-indirect`.

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
             :repo "jamescherti/buffer-guardian.el"))
```

### Alternative installation: use-package and :vc (Built-in feature in Emacs version >= 30)

To install *buffer-guardian* with `use-package` and `:vc` (Emacs >= 30):

``` emacs-lisp
(use-package buffer-guardian
  :vc (:url "https://github.com/jamescherti/buffer-guardian.el"
       :rev :newest))
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
  ;; TODO: setq options
  ;; TODO: Load the mode here
  )
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
* `buffer-guardian-save-on-buffer-change` (Default: `t`): Save when `window-buffer-change-functions` runs.
* `buffer-guardian-save-on-window-change` (Default: `t`): Save when `window-selection-change-functions` runs.

### Timers

* `buffer-guardian-save-all-buffers-interval` (Default: `nil`): Save all buffers periodically every N seconds.
* `buffer-guardian-save-all-buffers-idle` (Default: `nil`): Save all buffers after N seconds of user idle time.

### Exclusions and Filters

* `buffer-guardian-inhibit-saving-remote-files` (Default: `t`): Prevent auto-saving remote files.
* `buffer-guardian-inhibit-saving-nonexistent-files` (Default: `t`): Prevent saving files that do not exist on disk.
* `buffer-guardian-exclude` (Default: `nil`): A list of regular expressions for file names to ignore.
* `buffer-guardian-max-buffer-size` (Default: `nil`): Maximum buffer size (in characters) to save. Set to 0 or nil to disable.
* `buffer-guardian-predicates` (Default: `nil`): A list of custom predicate functions. If any returns `nil`, the buffer is not saved.

### Advanced

* `buffer-guardian-hooks-auto-save-all-buffers`: A list of hooks that trigger saving all modified buffers. Defaults to `'(mouse-leave-buffer-hook)`.
* `buffer-guardian-functions-auto-save-current-buffer`: A list of functions to advise. A `:before` advice will save the current buffer before these functions execute.
* `buffer-guardian-verbose` (Default: `nil`): Enable logging messages when a buffer is saved.

## Commands

* `buffer-guardian-save-buffer`: Interactively save the current buffer. It checks if the file was modified outside of Emacs and prompts to revert if necessary.
* `buffer-guardian-save-all-buffers`: Interactively save all modified buffers that visit existing files.

## Author and License

The *buffer-guardian* Emacs package has been written by [James Cherti](https://www.jamescherti.com/) and is distributed under terms of the GNU General Public License version 3, or, at your choice, any later version.

Copyright (C) 2026 James Cherti

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- [buffer-guardian.el @GitHub](https://github.com/jamescherti/buffer-guardian.el)
