/*
 *
 * index.js */

var JSLINT = require('jslint').load('latest'),
  find = require('./lib/fpath-find.js').find,
  puts = require('util').puts,
  filepath = process.argv[2],
  regex = new RegExp("^#![^\\n]*");

process.stdin.setEncoding('utf8');

process.stdin.on('data', function (chunk) {
  "use strict";

  var options,
    errors,
    i;

  options = find(filepath, '.jslintrc', {});

  try {
    options = JSON.parse(options);
  } catch (e) {
    options = {};
  }

  chunk = chunk.replace(regex, "");

  for (i = 0, JSLINT(chunk, options),
          errors = JSLINT.errors || [];
              i < errors.length; i += 1) {
    if (errors[i]) {
      puts(errors[i].line + ':' + errors[i].character +
        ':' + errors[i].reason);
    }
  }
  puts(chunk);
});

