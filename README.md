# buffer-guardian.el
![Build Status](https://github.com/jamescherti/buffer-guardian.el/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/github/license/jamescherti/buffer-guardian.el)
![](https://jamescherti.com/misc/made-for-gnu-emacs.svg)

Save your work without thinking about it.

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

## Author and License

The *buffer-guardian* Emacs package has been written by [James Cherti](https://www.jamescherti.com/) and is distributed under terms of the GNU General Public License version 3, or, at your choice, any later version.

Copyright (C) 2026 James Cherti

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.

## Links

- [buffer-guardian.el @GitHub](https://github.com/jamescherti/buffer-guardian.el)
