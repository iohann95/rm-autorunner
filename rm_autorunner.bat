@echo off
::Desenvolvido por Iohann Tachy.
::iohann.tachy@gmail.com

::Caminhos dos instaladores (nao use espacos nem caracteres especiais)
SET BIBLIOTECARM=\\fileserver\Publico\Totvs\BIBLIOTECARM-12.1.28.MSI
SET PATCHRM1=\\fileserver\Publico\Totvs\PATCH-12.1.28.227.exe
SET VCREDIST=\\fileserver\Publico\Totvs\vc_redist.x86.exe
SET NATIVECLIENTRM=\\fileserver\Publico\Totvs\sqlncli.msi
SET VERSAORM=12.1.28.227
::Se a variavel estiver ativa, os instaladores serao copiados ao TEMP antes da instalacao
::SET "COPIAR= "

::==========================================
:get_admin
set _Args=%*
if "%~1" NEQ "" (
  set _Args=%_Args:"=%
)
::"
fltmc 1>nul 2>nul || (
  cd /d "%~dp0"
  cmd /u /c echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~dpnx0"" ""%_Args%""", "", "runas", 1 > "%temp%\GetAdmin.vbs"
  "%temp%\GetAdmin.vbs"
  del /f /q "%temp%\GetAdmin.vbs" 1>nul 2>nul
  exit
)

:menu_inicial
color 07
cls
title INSTALADOR TOTVS RM %VERSAORM%
echo ========================================
echo INSTALADOR TOTVS RM %VERSAORM%
echo rm_autorunner desenvolvido por Iohann Tachy
echo ========================================
echo:

:file_check
IF NOT EXIST %BIBLIOTECARM% (
COLOR 04
ECHO %BIBLIOTECARM% NAO ENCONTRADO!
PAUSE
EXIT)
IF NOT EXIST %PATCHRM1% (
COLOR 04
ECHO %PATCHRM1% NAO ENCONTRADO!
PAUSE
EXIT)
IF NOT EXIST %VCREDIST% (
ECHO %VCREDIST% NAO ENCONTRADO!
EXIT)
IF NOT EXIST %NATIVECLIENTRM% (
COLOR 04
ECHO %NATIVECLIENTRM% NAO ENCONTRADO!
PAUSE
EXIT)

:file_copy
IF DEFINED COPIAR (
for %%A in ("%BIBLIOTECARM%") do (
echo Copiando %%~nA ...
copy /Y %BIBLIOTECARM% %TEMP%
SET BIBLIOTECARM=%TEMP%\%%~nxA)
for %%A in ("%PATCHRM1%") do (
echo Copiando %%~nA ...
copy /Y %PATCHRM1% %TEMP%
SET PATCHRM1=%TEMP%\%%~nxA)
for %%A in ("VCREDIST%") do (
echo Copiando %%~nA ...
copy /Y %VCREDIST% %TEMP%
SET VCREDIST=%TEMP%\%%~nxA)
for %%A in ("%NATIVECLIENTRM%") do (
echo Copiando %%~nA ...
copy /Y %NATIVECLIENTRM% %TEMP%
SET NATIVECLIENTRM=%TEMP%\%%~nxA)
)

:taskkill
echo Parando TOTVS RM...
taskkill /F /IM RM.exe>nul
net stop RM.Host.Service>nul

::Preterido em novas builds do Windows 10
:windows_defender
setlocal
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "10.0" (
echo Adicionando exclusao ao Windows Defender...
powershell -inputformat none -outputformat none -NonInteractive -Command Add-MpPreference -ExclusionPath $ENV:SystemDrive\Totvs)
endlocal

call :d_uac

:unistall_rm
if exist "%SystemDrive%\totvs\CorporeRM" (
echo Desinstalando versao anterior do RM...
msiexec.exe /x %BIBLIOTECARM% /quiet delall=Yes
if %ERRORLEVEL% NEQ 0 (
color 04
echo Erro ao desinstalar versao atual do RM. Tente desinstalar manualmente e rode novamente este instalador. Cod Erro %ERRORLEVEL%
PAUSE
call :e_uac
EXIT)
timeout /t 5 /nobreak>nul
if exist "%SystemDrive%\totvs\CorporeRM" (
echo Limpando diretorio...
rd "%SystemDrive%\totvs\CorporeRM" /s /q))

:install_vcredist
::ERRORLEVEL nao implementado
for %%A in ("%VCREDIST%") do (echo Instalando %%~nA ...)
%VCREDIST% /install /passive /norestart

:install_rm
for %%A in ("%BIBLIOTECARM%") do (echo Instalando %%~nA ...)
msiexec.exe /i %BIBLIOTECARM% /quiet layer=local db=SQL dbserver=RMServer dbname=CorporeRM lang=pt-BR QTDhost=1 insthostcleanner=false
if %ERRORLEVEL% NEQ 0 (
color 04
echo Falha ao instalar a Biblioteca RM! Tente realizar a instalacao manual. Cod Erro %ERRORLEVEL%
PAUSE
call :e_uac
EXIT)
call :e_uac

:install_patch1
for %%A in ("%PATCHRM1%") do (echo Instalando %%~nA ...)
%PATCHRM1% /verysilent /suppressmsgboxes
if %ERRORLEVEL% NEQ 0 (
color 04
echo Erro ao instalar o PATCH de atualizacao. Tente realizar a instalacao manual. Cod Erro %ERRORLEVEL%
PAUSE
EXIT)

:install_nativeclient
::ERRORLEVEL nao implementado
echo Instalando MS SQL Server 2012 Native Client...
msiexec.exe /i %NATIVECLIENTRM% IACCEPTSQLNCLILICENSETERMS=YES /quiet

:cleanup
IF DEFINED COPIAR (
echo Excluindo arquivos de instalacao...
del /Q %BIBLIOTECARM%
del /Q %PATCHRM1%
del /Q %VCREDIST%
del /Q %NATIVECLIENTRM%
)

:fim
color 02
powershell [console]::Beep(500,1000)
echo:
echo ========================================
echo FIM DA INSTALACAO DO RM %VERSAORM%
echo ========================================
PAUSE
EXIT

:d_uac
echo Desabilitando UAC...
reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f
if %ERRORLEVEL% NEQ 0 (
color 04
echo Erro ao desabilitar UAC! Voce tem permissoes de administrador? Cod Erro %ERRORLEVEL%
PAUSE
EXIT)
goto :eof

:e_uac
echo Habilitando UAC...
reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f
if %ERRORLEVEL% NEQ 0 (
color 04
echo Erro ao habilitar o UAC! Voce tem permissoes de administrador? Erro Cod %ERRORLEVEL%
PAUSE
EXIT)
goto :eof
