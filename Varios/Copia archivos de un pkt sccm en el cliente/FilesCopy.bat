if not exist "%~1" md "%~1"
copy /y "%~dp0Files2Copy\*.*" "%~1"