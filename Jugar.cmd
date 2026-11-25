@echo off
setlocal
rem GODOT_EXE permite elegir un motor instalado sin modificar este archivo.
if defined GODOT_EXE if exist "%GODOT_EXE%" goto run
set "GODOT_EXE="

for %%G in (godot.exe godot4.exe) do (
    for /f "delims=" %%P in ('where %%G 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%P"
)
if defined GODOT_EXE goto run

if exist "%~dp0Godot.exe" set "GODOT_EXE=%~dp0Godot.exe"
if defined GODOT_EXE goto run

rem Cache local opcional; no forma parte del repositorio.
if exist "%~dp0.godot\runtime\Godot.exe" set "GODOT_EXE=%~dp0.godot\runtime\Godot.exe"
if defined GODOT_EXE goto run

echo No se encontro Godot 4.7.
echo Define GODOT_EXE, agrega Godot al PATH o coloca Godot.exe junto al proyecto.
pause
exit /b 1

:run
start "DSJRetro" "%GODOT_EXE%" --path "%~dp0."
