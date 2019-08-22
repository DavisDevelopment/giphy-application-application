REM @echo off

call coffee -c -o .\build\js\ .\src 
call coffee -c -o .\build\js\worker.js -b .\src\worker.coffee
call browserify .\build\js\stuller.js >build\js\stuller.packed.js
call browserify .\build\js\worker.js >build\js\worker.packed.js