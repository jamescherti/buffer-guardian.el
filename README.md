# buffer-guardian.el - Automatically Save Emacs Buffers Without Manual Intervention (When Buffers Lose Focus, Regularly, or After Emacs is Idle)
![Build Status](https://github.com/jamescherti/buffer-guardian.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/buffer-guardian.el)
![](https://jamescherti.com/misc/made-for-gnu-emacs.svg)

The **buffer-guardian** package provides `buffer-guardian-mode`, a global mode that automatically saves buffers without requiring manual intervention.

**By default, `buffer-guardian-mode` saves file-visiting buffers when:**
- Switching to another buffer.
- Switching to another window or frame.
- The window configuration changes (e.g., window splits).
- The minibuffer is opened.
- Emacs loses focus.

(Skip to: [Installation](#Installation))

In addition to regular file-visiting buffers, `buffer-guardian-mode` also handles specialized editing buffers used for inline code blocks, such as `org-src` (for Org mode) and `edit-indirect` (commonly used for Markdown source code blocks). These temporary buffers are linked to an underlying parent buffer. Automatically saving them ensures that modifications made within these isolated code environments are correctly propagated back to the original Org or Markdown file.

If this package enhances your workflow, please show your support by **⭐ starring buffer-guardian on GitHub** to help more users discover its benefits.

Other features that are **disabled** by default:
- Save the buffer even if a window change results in the same buffer being selected. (Variable: `buffer-guardian-save-on-same-buffer-window-change`)
- Save all file-visiting buffers periodically at a specific interval. (Variable: `buffer-guardian-save-all-buffers-interval`)
- Save all file-visiting buffers after a period of user inactivity. (Variable: `buffer-guardian-save-all-buffers-idle`)
- Prevent auto-saving remote files. (Variable: `buffer-guardian-inhibit-saving-remote-files`)
- Prevent saving files that do not exist on disk. (Variable: `buffer-guardian-inhibit-saving-nonexistent-files`)
- Set a maximum buffer size limit for auto-saving. (Variable: `buffer-guardian-max-buffer-size`)
- Ignore buffers whose names match specific regular expressions. (Variable: `buffer-guardian-exclude-regexps`)
- Use custom predicate functions to determine if a buffer should be saved. (Variable: `buffer-guardian-predicate-functions`)

(Buffer Guardian runs in the background without interrupting the workflow. For example, the package safely aborts the auto-save process if the file is read-only, if the file's parent directory does not exist, or if the file was modified externally. Additionally, it gracefully catches and logs errors if a third-party hook attempts to request user input, ensuring that the editor never freezes during an automatic background save.)

## Installation

### Installation from MELPA

To install **buffer-guardian** from MELPA:

1. If you haven't already done so, [add MELPA repository to your Emacs configuration](https://melpa.org/#/getting-started).

2. Add the following code to your Emacs init file to install **buffer-guardian** from MELPA:

```emacs-lisp
(use-package buffer-guardian
  :custom
  ;; When non-nil, include remote files in the auto-save process
  (buffer-guardian-inhibit-saving-remote-files t)

  ;; When non-nil, buffers visiting nonexistent files are not saved
  (buffer-guardian-inhibit-saving-nonexistent-files nil)

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
  ;; When non-nil, buffers visiting nonexistent files are not saved
  (setq buffer-guardian-inhibit-saving-nonexistent-files nil)

  (buffer-guardian-mode))
```

3. Run the `doom sync` command:
```
doom sync
```

## Configuration

You can customize `buffer-guardian` to fit your workflow. Below are the main customization variables:

### Triggers

* `buffer-guardian-save-on-focus-loss` (Default: `t`): Save when the Emacs frame loses focus.
* `buffer-guardian-save-on-minibuffer-setup` (Default: `t`): Save when the minibuffer opens.
* `buffer-guardian-save-on-buffer-change` (Default: `t`): Save when `window-buffer-change-functions` runs.
* `buffer-guardian-save-on-window-selection-change` (Default: `t`): Save when `window-selection-change-functions` runs.
* `buffer-guardian-save-on-window-configuration-change` (Default: `t`): Save when `window-configuration-change-hook` runs.
* `buffer-guardian-save-on-same-buffer-window-change` (Default: `nil`): Save the buffer even if the window change results in the same buffer.

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

* `buffer-guardian-save-all-trigger-hooks`: A list of hooks that trigger saving all modified buffers. Defaults to nil.
* `buffer-guardian-functions-auto-save-current-buffer`: A list of functions to advise. A `:before` advice will save the current buffer before these functions execute.
* `buffer-guardian-verbose` (Default: `nil`): Enable logging messages when a buffer is saved.

## Author and License

The *buffer-guardian* Emacs package has been written by [James Cherti](https://www.jamescherti.com/) and is distributed under terms of the GNU General Public License version 3, or, at your choice, any later version.

Copyright (C) 2026 James Cherti

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- [buffer-guardian.el @GitHub](https://github.com/jamescherti/buffer-guardian.el)

Other Emacs packages by the same author:
- [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d): This repository hosts a minimal Emacs configuration designed to serve as a foundation for your vanilla Emacs setup and provide a solid base for an enhanced Emacs experience.
- [compile-angel.el](https://github.com/jamescherti/compile-angel.el): **Speed up Emacs!** This package guarantees that all .el files are both byte-compiled and native-compiled, which significantly speeds up Emacs.
- [outline-indent.el](https://github.com/jamescherti/outline-indent.el): An Emacs package that provides a minor mode that enables code folding and outlining based on indentation levels for various indentation-based text files, such as YAML, Python, and other indented text files.
- [easysession.el](https://github.com/jamescherti/easysession.el): Easysession is lightweight Emacs session manager that can persist and restore file editing buffers, indirect buffers/clones, Dired buffers, the tab-bar, and the Emacs frames (with or without the Emacs frames size, width, and height).
- [vim-tab-bar.el](https://github.com/jamescherti/vim-tab-bar.el): Make the Emacs tab-bar Look Like Vim’s Tab Bar.
- [elispcomp](https://github.com/jamescherti/elispcomp): A command line tool that allows compiling Elisp code directly from the terminal or from a shell script. It facilitates the generation of optimized .elc (byte-compiled) and .eln (native-compiled) files.
- [tomorrow-night-deepblue-theme.el](https://github.com/jamescherti/tomorrow-night-deepblue-theme.el): The Tomorrow Night Deepblue Emacs theme is a beautiful deep blue variant of the Tomorrow Night theme, which is renowned for its elegant color palette that is pleasing to the eyes. It features a deep blue background color that creates a calming atmosphere. The theme is also a great choice for those who miss the blue themes that were trendy a few years ago.
- [Ultyas](https://github.com/jamescherti/ultyas/): A command-line tool designed to simplify the process of converting code snippets from UltiSnips to YASnippet format.
- [dir-config.el](https://github.com/jamescherti/dir-config.el): Automatically find and evaluate .dir-config.el Elisp files to configure directory-specific settings.
- [flymake-bashate.el](https://github.com/jamescherti/flymake-bashate.el): A package that provides a Flymake backend for the bashate Bash script style checker.
- [flymake-ansible-lint.el](https://github.com/jamescherti/flymake-ansible-lint.el): An Emacs package that offers a Flymake backend for ansible-lint.
- [inhibit-mouse.el](https://github.com/jamescherti/inhibit-mouse.el): A package that disables mouse input in Emacs, offering a simpler and faster alternative to the disable-mouse package.
- [quick-sdcv.el](https://github.com/jamescherti/quick-sdcv.el): This package enables Emacs to function as an offline dictionary by using the sdcv command-line tool directly within Emacs.
- [enhanced-evil-paredit.el](https://github.com/jamescherti/enhanced-evil-paredit.el): An Emacs package that prevents parenthesis imbalance when using *evil-mode* with *paredit*. It intercepts *evil-mode* commands such as delete, change, and paste, blocking their execution if they would break the parenthetical structure.
- [stripspace.el](https://github.com/jamescherti/stripspace.el): Ensure Emacs Automatically removes trailing whitespace before saving a buffer, with an option to preserve the cursor column.
- [persist-text-scale.el](https://github.com/jamescherti/persist-text-scale.el): Ensure that all adjustments made with text-scale-increase and text-scale-decrease are persisted and restored across sessions.
- [pathaction.el](https://github.com/jamescherti/pathaction.el): Execute the pathaction command-line tool from Emacs. The pathaction command-line tool enables the execution of specific commands on targeted files or directories. Its key advantage lies in its flexibility, allowing users to handle various types of files simply by passing the file or directory as an argument to the pathaction tool. The tool uses a .pathaction.yaml rule-set file to determine which command to execute. Additionally, Jinja2 templating can be employed in the rule-set file to further customize the commands.
- [kirigami.el](https://github.com/jamescherti/kirigami.el): The *kirigami* Emacs package offers a unified interface for opening and closing folds across a diverse set of major and minor modes in Emacs, including `outline-mode`, `outline-minor-mode`, `outline-indent-minor-mode`, `org-mode`, `markdown-mode`, `vdiff-mode`, `vdiff-3way-mode`, `hs-minor-mode`, `hide-ifdef-mode`, `origami-mode`, `yafolding-mode`, `folding-mode`, and `treesit-fold-mode`. With Kirigami, folding key bindings only need to be configured **once**. After that, the same keys work consistently across all supported major and minor modes, providing a unified and predictable folding experience.
