/*
 * 
 * fpath-find.js */

/*jslint node:true, stupid:true, nomen:true */

var path = require('path'),
  fs = require('fs');

module.exports = {
  _getFileSystemRoot: function (tgt_path) {
    "use strict";
    tgt_path = this._normalize(tgt_path);
    return (/^[^\/]*\//).exec(tgt_path)[0];
  },

  _normalize: function (tgt_path) {
    "use strict";
    return path.normalize(tgt_path + '/');
  },

  _getHomeFolder: function () {
    "use strict";
    return this._normalize(process.env.HOME || process.env.HOMEPATH ||
          process.env.USERPROFILE);
  },

  _open: function (tgt_path, file) {
    "use strict";
    console.log(tgt_path, file);
    return fs.readFileSync(tgt_path + file, {
      encoding: "utf8",
      flag: "r"
    });
  },

  _search: function (tgt_path, file, fsRoot) {
    "use strict";
    try {
      return this._open(tgt_path, file);
    } catch (e) {
      if (tgt_path === fsRoot) {
        return this._open(this._getHomeFolder(), file);
      }
      tgt_path = tgt_path.replace(/\/[^\/]*\/$/, '/');
      return this._search(tgt_path, file, fsRoot);
    }
  },

  _find: function (tgt_path, file, _default) {
    "use strict";
    console.log(arguments);
    try {
      return this._search(this._normalize(tgt_path), file,
          this._getFileSystemRoot(tgt_path));
    } catch (e) {
      return _default;
    }
  },

  find: function () {
    "use strict";
    var args = Array.prototype.slice.call(arguments);

    return module.exports._find.apply(module.exports, args);
  }
};

