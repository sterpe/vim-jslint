jslhint.vim
===========
jslint and jshint all in one




##Installation
1. First of all, you should install node.js and you can find instructions for installing node.js on the [node.js website](http://nodejs.org/).


2. Then,  copy the directory `ftplugin/` into your Vim `ftplugin` directory.
Usually this is `~/.vim/ftplugin/`. On Windows it is `~/vimfiles/ftplugin/`.

3. Finally, activate filetype plugins in your `.vimrc`, by adding the following line:

```vim
filetype plugin on
```


##Usage

- This plugin automatically checks the JavaScript source and highlights the
  lines with errors.

  All errors will be displayed in `quickfix` window in vim. So you should open
  the  `quickfix` window with the command `:copen`.

  It also will display more information about the error in the command line if
  the cursor is in the same line.

- You also can call it manually via `:JSUpdate`.

- You can toggle jslint and jshint with the command `:JSToggle`.

- You can toggle automatic checking on or off with the command `:JSToggleEnable`.
  You can modify your `~/.vimrc` file to bind this command to a key or to turn
  off error checking by default.

- (optional) Putting all jslint options into one file -- `.jslintrc` . The
  `.jslintrc` file should be placed under the root of project. It will be used as
  global options for all JavaScript files in the project. If `.jslintrc` file
  is not found in the project, the plugin will try to find `~/.jslintrc` file.
  You can putting jslint options into `.jslintrc` file like this:

```javascript
/*jslint browser: true, regexp: true */
/*global jQuery, $ */

```

- (optional) Putting all jshint options into one file -- `.jshintrc` . The
  `.jshintrc` file should be placed under the root of project. It will be used as
  global options for all JavaScript files in the project. If `.jshintrc` file
  is not found in the project, the plugin will try to find `~/.jshintrc` file.
  You can putting jshint options into `.jshintrc` file like this:

```json
{
  "undef": true,
  "unused": true,
  "globals": { "MY_GLOBAL": false }
}

```

##Next
* open quick-fix window automatically


