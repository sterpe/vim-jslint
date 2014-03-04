/*
 * 
 * index.js */

/*jslint  node:true */

function open_jslintrc(path) {
    "use strict";

    var fs = require('fs'),
        exports;

    function getUserHome() {
        return process.env.HOME || process.env.HOMEPATH ||
                process.env.USERPROFILE;
    }

    try {
        /*jslint stupid:true */
        exports = JSON.parse(fs.readFileSync(path + '.jslintrc', {
            encoding: "utf8",
            flag: "r"
        }));
        /*jslint stupid:false */
    } catch (e) {
        if (path === '/') {
            try {
                /*jslint stupid:true */
                exports = JSON.parse(fs.readFileSync(getUserHome() +
                    '/.jslintrc', {
                        encoding: "utf8",
                        flag: "r"
                    }));
                /*jslint stupid:false */
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

