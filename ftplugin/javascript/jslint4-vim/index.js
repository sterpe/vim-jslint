/*
 * 
 * index.js */

/*jslint  node:true */

function open_jslintrc(path) {
    "use strict";

    var exports;

    function getUserHome() {
        return process.env.HOME || process.env.HOMEPATH ||
                process.env.USERPROFILE;
    }
    /*jslint stupid:true */
    function openAndParseJSON(path) {
        var fs = require('fs');

        return JSON.parse(fs.readFileSync(path + '.jslintrc', {
            encoding: "utf8",
            flag: "r"
        }));
    }
    /*jslint stupid:false */
    try {
        exports = openAndParseJSON(path);
    } catch (e) {
        if (path === '/') {
            try {
                exports = openAndParseJSON(getUserHome() + '/');
            } catch (E) {
                exports = {};
            }
        } else {
            path = path.split('/');
            path.pop();
            path.pop();
            path = path.join('/') + '/';
            exports = open_jslintrc(path);
        }
    }

    return exports;
}

process.stdin.setEncoding('utf8');
process.stdin.on('data', function (chunk) {
    "use strict";

    var JSLINT = require('jslint').load('latest'),
        path = process.argv[2],
        puts = require('util').puts,
        errors,
        i;

    for (i = 0, JSLINT(chunk, open_jslintrc(path)),
            errors = JSLINT.errors || [];
                i < errors.length; i += 1) {
        if (errors[i]) {
            puts(errors[i].line + ':' + errors[i].character +
                ':' + errors[i].reason);
        }
    }
});

