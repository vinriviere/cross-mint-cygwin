############################################################################
# This is the source file for the installer of the MiNT Cross Tools for Cygwin.
# Written by Vincent Rivi�re.
#
# This source is intended to be compiled with Nullsoft NSIS 2.46.
# You are free to use this file for any purpose. But if you rebuild the installer by yourself,
# please change COMPANY_NAME and COMPANY_EMAIL to your own information.
############################################################################

!include MUI2.nsh
!include LogicLib.nsh
!include nsDialogs.nsh

!define PRODUCT_NAME "MiNT Cross Tools for Cygwin"
!define COMPANY_NAME "Vincent Rivi�re"
!define COMPANY_EMAIL "vincent.riviere@freesbee.fr"
!define INSTALL_DIR /opt/cross-mint

# The following defines are generated by ./printversions.sh
# They must be manually copied/pasted into the NSIS source file.
!define THIS_YEAR 2010
!define PRODUCT_VERSION 20100517
!define PRODUCT_VERSION_DOTS 0.2010.5.17
!define BINUTILS_ARCHIVE binutils-2.20.1-mint-20100410-bin-cygwin-20100410.tar.bz2
!define BINUTILS_VERSION 2.20.1-mint-20100410
!define BINUTILS_SIZE 5515
!define GCC_ARCHIVE gcc-4.5.0-mint-20100511-bin-cygwin-20100512.tar.bz2
!define GCC_VERSION 4.5.0-mint-20100511
!define GCC_SIZE 57962
!define GDB_ARCHIVE gdb-5.1-mint-20081102-bin-cygwin-20100124.tar.bz2
!define GDB_VERSION 5.1-mint-20081102
!define GDB_SIZE 1709
!define GEMLIB_ARCHIVE gemlib-CVS-20100223-bin-cygwin-20100417.tar.bz2
!define GEMLIB_VERSION CVS-20100223
!define GEMLIB_SIZE 1201
!define MINTBIN_ARCHIVE mintbin-0.3-patch-20091031-bin-cygwin-20100123.tar.bz2
!define MINTBIN_VERSION 0.3-patch-20091031
!define MINTBIN_SIZE 155
!define MINTLIB_ARCHIVE mintlib-CVS-20100511-bin-cygwin-20100512.tar.bz2
!define MINTLIB_VERSION CVS-20100511
!define MINTLIB_SIZE 11111
!define NCURSES_ARCHIVE ncurses-5.7-mint-20090821-bin-cygwin-20100417.tar.bz2
!define NCURSES_VERSION 5.7-mint-20090821
!define NCURSES_SIZE 1516
!define PML_ARCHIVE pml-2.03-mint-20100123-bin-cygwin-20100417.tar.bz2
!define PML_VERSION 2.03-mint-20100123
!define PML_SIZE 74

# Run a Cygwin command with no output
!macro RunCygwinCommand retvar command args
  nsExec::Exec '"$cygwinHome\bin\${command}.exe" ${args}'
  Pop ${retvar}
!macroend

# Run a Cygwin command and send the output to the install log
!macro RunCygwinCommandToLog retvar command args
  nsExec::ExecToLog '"$cygwinHome\bin\${command}.exe" ${args}'
  Pop ${retvar}
!macroend

# Run a Cygwin command and send the output to a variable
!macro RunCygwinCommandToVariable retvar ouputvar command args
  nsExec::ExecToStack '"$cygwinHome\bin\${command}.exe" ${args}'
  Pop ${retvar}
  Pop ${ouputvar}
  
  # Remove the Line Feed character
  # BUG: This fails if the last character is not a Line Feed
  StrLen $R0 ${ouputvar}
  IntOp $R0 $R0 - 1
  StrCpy ${ouputvar} ${ouputvar} $R0
!macroend

# Run a function from bashlib.sh
!macro RunBashLibFunction retvar function
  !insertmacro RunCygwinCommand ${retvar} bash "bashlib.sh ${function}"
!macroend

# Install a Cygwin package
!macro InstallCygwinPackage package
  File packages\${${package}_ARCHIVE}

  !insertmacro RunCygwinCommandToLog $0 tar "-C / -jxvf ${${package}_ARCHIVE}"
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Error during installation of ${${package}_ARCHIVE}."
    Abort "Error during installation of ${${package}_ARCHIVE}."
  ${EndIf}

  # Delete the archive after installation to avoid wasting temporary space
  SetDetailsPrint none
  Delete ${${package}_ARCHIVE}
  SetDetailsPrint both
!macroend

# Internal machinery for inserting several labels in a page
Var labelY
!define PageCurrentLine $labelY
!define LABEL_HEIGHT 10
!define /math LABEL_HEIGHT_X2 ${LABEL_HEIGHT} * 2
!define /math LABEL_HEIGHT_X3 ${LABEL_HEIGHT} * 3
!define /math LABEL_HEIGHT_X4 ${LABEL_HEIGHT} * 4

# Reset the page label position
!macro PageResetLine
  StrCpy $labelY 0
!macroend

# Skip a line before the next label
!macro PageNewLine
  IntOp $labelY $labelY + ${LABEL_HEIGHT}
!macroend

# Append a label to the current page
!macro AppendLabel height text
  ${NSD_CreateLabel} 0u ${PageCurrentLine}u 100% ${height}u "${text}"
  Pop $0
  IntOp ${PageCurrentLine} ${PageCurrentLine} + ${height}
!macroend

# Append a named label
!macro AppendNamedLabel name value
  !insertmacro AppendLabel ${LABEL_HEIGHT} "${name}: ${value}"
!macroend

# Check if a Cygwin package is installed
!macro CheckInstalledCygwinPackage package
  ${If} ${FileExists} $cygwinHome\etc\setup\${package}.lst.gz
    StrCpy $0 "INSTALLED"
  ${Else}
    StrCpy $0 "NOT FOUND"
    StrCpy $cygwinDependencyMissing 1
  ${EndIf}

  !insertmacro AppendNamedLabel "Package ${package}" $0
!macroend

# Create a custom page, initially hidden
!macro CreateCustomPage
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
      Abort
  ${EndIf}
!macroend

############################################################################

# General settings
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile cross-mint-cygwin-${PRODUCT_VERSION}-setup.exe
SetCompressor zlib
RequestExecutionLevel admin

# Supported Install Types
# The order is important, it will be referenced by the sections
InstType Typical
InstType Full

############################################################################
# Welcome Page

!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of $(^NameDA).$\n$\nThese tools will allow you to build software for the Atari ST and compatible computers running MiNT/TOS operating systems.$\n$\nThis package is provided to you by ${COMPANY_NAME}.$\n${COMPANY_EMAIL}$\n$\n$_CLICK"
!insertmacro MUI_PAGE_WELCOME

############################################################################
# License Page

!insertmacro MUI_PAGE_LICENSE license.txt

############################################################################
# Cygwin Requirements Page

Var cygwinHome

Function CygwinRequirementsPageCreator
  !insertmacro MUI_HEADER_TEXT_PAGE "Cygwin Requirements" "Check current Cygwin installation and required packages."
  !insertmacro CreateCustomPage
  ShowWindow $0 ${SW_SHOW} # Display the window now to see the progression of the tests
  !insertmacro PageResetLine

  ReadRegStr $cygwinHome HKLM SOFTWARE\Cygwin\setup rootdir
  !insertmacro AppendNamedLabel "Cygwin home" $cygwinHome
/*
  !insertmacro RunCygwinCommandToVariable $0 $1 uname -r
  !insertmacro AppendNamedLabel "Cygwin version" $1
*/

  Var /GLOBAL cygwinDependencyMissing
  StrCpy $cygwinDependencyMissing 0

  !insertmacro PageNewLine
  #!insertmacro CheckInstalledCygwinPackage bzip2
  #!insertmacro CheckInstalledCygwinPackage tar
  #!insertmacro CheckInstalledCygwinPackage libmpfr1
  !insertmacro CheckInstalledCygwinPackage libmpc1
  !insertmacro CheckInstalledCygwinPackage libcloog0

  !insertmacro PageNewLine
  ${If} $cygwinDependencyMissing == 0
    StrCpy $0 "All the Cygwin requirements are met."
  ${Else}
    StrCpy $0 "Some required Cygwin packages are missing.$\nPlease install them using the standard Cygwin setup program, then restart this installation."
    EnableWindow $mui.Button.Next 0
  ${EndIf}
  !insertmacro AppendLabel 40 $0

  nsDialogs::Show
FunctionEnd

Page custom CygwinRequirementsPageCreator

############################################################################
# Installation Directory Page

Var winInstallDir

Function InstallDirPageCreator
  !insertmacro MUI_HEADER_TEXT_PAGE "Installation Directory" "Information about the installation directory."
  !insertmacro CreateCustomPage
  ShowWindow $0 ${SW_SHOW} # Display the window now to see the progression of the tests
  !insertmacro PageResetLine

  !insertmacro AppendLabel ${LABEL_HEIGHT_X2} "The cross-tools will be installed into ${INSTALL_DIR}."

  !insertmacro RunCygwinCommandToVariable $0 $winInstallDir cygpath "-w ${INSTALL_DIR}"
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Error during the location of ${INSTALL_DIR}."
    Quit
  ${EndIf}
  !insertmacro AppendLabel ${LABEL_HEIGHT_X2} "It corresponds to the Windows directory $winInstallDir."
  
  !insertmacro AppendLabel ${LABEL_HEIGHT_X3} "If you want to completely uninstall the cross-tools, you just have to remove manually the directory above. There is no uninstaller."
  
  ${If} ${FileExists} $winInstallDir
    !insertmacro AppendLabel ${LABEL_HEIGHT_X4} "Warning: The directory $winInstallDir currently exists.$\nIf you continue this installation process, it will be automatically deleted with the third-party libraries you may have installed into it."
  ${EndIf}
  
  nsDialogs::Show
FunctionEnd

Function InstallDirPageLeave
  ${If} ${FileExists} $winInstallDir
    MessageBox MB_ICONEXCLAMATION|MB_YESNO "The installation directory $winInstallDir currently exists.$\nDo you want to remove it automatically, and lose any additional library you may have installed into it ?" IDYES +2
    Abort
     
    !insertmacro AppendLabel ${LABEL_HEIGHT} "Cleaning $winInstallDir, please wait..."

    # Disable the Next button to prevent the user from clicking on it while RMDir is in progress
    EnableWindow $mui.Button.Next 0
    RMDir /r $winInstallDir
    ${If} ${Errors}
      MessageBox MB_ICONSTOP|MB_OK "Fatal error: Cannot remove the directory $winInstallDir."
      Quit
    ${EndIf}
  ${EndIf}
FunctionEnd

Page custom InstallDirPageCreator InstallDirPageLeave

############################################################################
# Components Page

!insertmacro MUI_PAGE_COMPONENTS

############################################################################
# Install Page

!insertmacro MUI_PAGE_INSTFILES

############################################################################
# Environment Variables Page

!macro CheckShellVariable variable function
  !insertmacro RunBashLibFunction $0 ${function}
  ${If} $0 = 0
    !insertmacro AppendLabel ${LABEL_HEIGHT} "${variable}: OK"
  ${Else}
    !insertmacro AppendLabel ${LABEL_HEIGHT} "${variable}: NOT FOUND"
    StrCpy $variablesFixingNeeded 1
  ${EndIf}
!macroend

Function VariablesPageCreator
  !insertmacro MUI_HEADER_TEXT_PAGE "Environment Variables" "Check required environment variables."
  !insertmacro CreateCustomPage
  ShowWindow $0 ${SW_SHOW} # Display the window now to see the progression of the tests
  !insertmacro PageResetLine
  
  !insertmacro AppendLabel ${LABEL_HEIGHT} "Checking environment variables..."
  !insertmacro PageNewLine

  Var /GLOBAL variablesFixingNeeded
  StrCpy $variablesFixingNeeded 0
  
  !insertmacro CheckShellVariable PATH isPathOk
  !insertmacro CheckShellVariable MANPATH isManpathOk

  !insertmacro PageNewLine
  ${If} $variablesFixingNeeded == 0
    StrCpy $0 "All the environment variables are already correct."
  ${Else}
    StrCpy $0 "Some environment variables are not correctly set. You will be proposed to automatically fix them when you click Next."
  ${EndIf}
  !insertmacro AppendLabel 40 $0

  nsDialogs::Show
FunctionEnd

Function VariablesPageLeave
  ${If} $variablesFixingNeeded == 0
    Return
  ${EndIf}
  
  MessageBox MB_ICONQUESTION|MB_YESNO "Would you like to automatically fix your ~/.bash_profile file with the missing environment variables ?" IDYES +2
  Return
      
  !insertmacro RunBashLibFunction $0 fixConfigFile
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONSTOP "Unable to fix the environment variables."
  ${EndIf}
FunctionEnd

Page custom VariablesPageCreator VariablesPageLeave

############################################################################
# Finish Page

!define MUI_FINISHPAGE_TEXT "$(^NameDA) has been installed on your computer.$\n$\nTo use this cross-compiler, open a Cygwin shell and use the m68k-atari-mint-gcc command like a standard gcc. It will produce MiNT/TOS executables ready to be run on your Atari computer or emulator.$\n$\nClick Finish to close this wizard."
!insertmacro MUI_PAGE_FINISH

############################################################################
# Sections

# Create a section for a package
!macro SectionPackage package displayname in
Section "${displayname} ${${package}_VERSION}" ${package}_SECTION_INDEX
  SectionIn ${in}
  !insertmacro InstallCygwinPackage ${package}
SectionEnd
!macroend

# Since this installer contains already compressed files, turn off the compression of the packages.
SetCompress off

!insertmacro SectionPackage BINUTILS binutils RO
!insertmacro SectionPackage MINTBIN MiNTBin RO
!insertmacro SectionPackage GCC GCC RO
!insertmacro SectionPackage MINTLIB MiNTLib RO
!insertmacro SectionPackage PML PML RO
!insertmacro SectionPackage GEMLIB GEMlib RO
!insertmacro SectionPackage GDB GDB 2
!insertmacro SectionPackage NCURSES Ncurses 2

SetCompress auto

# Set the description for a package
!macro DescribePackage package description
  !insertmacro MUI_DESCRIPTION_TEXT ${${package}_SECTION_INDEX} "${description}"
!macroend

# Description of the sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro DescribePackage BINUTILS "Basic GNU tools for building MiNT binaries, including assembler and linker."
  !insertmacro DescribePackage MINTBIN "Additional tools for manipulating MiNT binaries."
  !insertmacro DescribePackage GCC "The GNU C and C++ compilers."
  !insertmacro DescribePackage MINTLIB "The MiNT standard library."
  !insertmacro DescribePackage PML "A free math library."
  !insertmacro DescribePackage GEMLIB "The bindings for making GEM programs."
  !insertmacro DescribePackage GDB "The GNU cross-debugger. It requires the gdbserver tool running on the target MiNT machine, and a working TCP/IP connection."
  !insertmacro DescribePackage NCURSES "A library for making fullscreen textmode programs."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

############################################################################
# Global callbacks

# Set the unpacked size of a package
!macro SetPackageUnpackedSize package
  SectionSetSize ${${package}_SECTION_INDEX} ${${package}_SIZE}
!macroend

Function .onInit
  # Since we install already compressed packages, we need to inform about the uncompressed size
  !insertmacro SetPackageUnpackedSize BINUTILS
  !insertmacro SetPackageUnpackedSize MINTBIN
  !insertmacro SetPackageUnpackedSize GCC
  !insertmacro SetPackageUnpackedSize MINTLIB
  !insertmacro SetPackageUnpackedSize PML
  !insertmacro SetPackageUnpackedSize GEMLIB
  !insertmacro SetPackageUnpackedSize GDB
  !insertmacro SetPackageUnpackedSize NCURSES

  # Our current directory will remain $PLUGINSDIR during the installation
  InitPluginsDir
  SetOutPath $PLUGINSDIR
  File bashlib.sh
FunctionEnd

Function .onGUIEnd
  # Go out from $PLUGINSDIR to allow it to be automatically removed
  SetOutPath $EXEDIR
FunctionEnd

############################################################################
# Supported Languages

!insertmacro MUI_LANGUAGE "English"

############################################################################
# Version tab in the Windows File Properties dialog

VIProductVersion ${PRODUCT_VERSION_DOTS}
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${PRODUCT_NAME} ${PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright � ${THIS_YEAR} ${COMPANY_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${COMPANY_NAME}"
