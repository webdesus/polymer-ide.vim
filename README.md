# Polymer IDE for Vim 

This is polymer_ide plugin for vim version 8.0 and above. This plugin unlocks all of the power of the [Polymer Analyzer](https://github.com/Polymer/polymer-analyzer) in vim. See [Polymer Editor Service](https://github.com/Polymer/polymer-editor-service) for more info, including links to other editor plugins.

Features:

 * typeahead completions for imported elements, with documentation [pic](#Completions_with_documentation)
 * typeahead completions for element attributes, with documentation [pic](#Completions_with_documentation)
 * inline errors (marks on lines) [pic](#Navigation_by_errors)
 * jump to definition support for custom elements and attributes [pic](#Go_to_definition)

## Requirements

 * Vim version 8.0 and above support;
 * node.js; 
 * UltiSnips(option) for supprots snippets;
 
## Installation

Use your favorite package manager
([vim-plug](https://github.com/junegunn/vim-plug),
[Vundle](https://github.com/VundleVim/Vundle.vim),
[pathogen.vim](https://github.com/tpope/vim-pathogen)),
or add this directory to your Vim runtime path.

For example, if you're using vim-plug, add the following line to `~/.vimrc`:

```
Plug 'webdesus/polymer-ide.vim'
```
Then go to plugin folder and execute 
```
npm install
```

For work using snippets needed install UltiSnips from this https://github.com/SirVer/ultisnips
  
## For more information, read documentation

```
:h polymer_ide
```
## Features in a gif

### Completions with documentation <a name="Completions_with_documentation"></a>
![preview](https://github.com/webdesus/polymer-ide.vim/raw/gh-pages/img/Completions.gif)

### Navigation by errors <a name="Navigation_by_errors"></a>
![preview](https://github.com/webdesus/polymer-ide.vim/raw/gh-pages/img/Errors.gif)

### Go to definition <a name="Go_to_definition"></a>
![preview](https://github.com/webdesus/polymer-ide.vim/raw/gh-pages/img/Go to definition.gif)

## Todo

 * Get references for element
 * Write tests
 * etc...
