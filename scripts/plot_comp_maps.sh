#!/bin/bash

# TODO: graphics output flag can only take one argument now
# if multiple are provided, then it will use the final one.
# This should be fixed in later versions (10/10/25 - dws)

EXEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)" ;
export EXEDIR;
Program=$(basename ${BASH_SOURCE[0]})
CompiledMATLABProgram=${Program%.sh}
MATLABRelease=R2024b
MATLABVersNum=24.2

if [[ "$OSTYPE" == "darwin"* ]]; then
  Arch=maci64
  if [[ "$(uname -m)" == "arm64" ]]; then Arch=maca64; fi
  DefaultRuntimePath=/Applications/MATLAB/MATLAB_Runtime/${MATLABRelease}
  DefaultInstallPath=/Applications/MATLAB_${MATLABRelease}.app/
  TestFile=runtime/${Arch}/libmwmclmcrrt.${MATLABVersNum}.dylib
  Executable=${EXEDIR}/${CompiledMATLABProgram}.app/Contents/MacOS/${CompiledMATLABProgram}
else
  DefaultRuntimePath=/usr/local/MATLAB/MATLAB_Runtime/${MATLABRelease}
  DefaultInstallPath=/usr/local/MATLAB/${MATLABRelease}
  TestFile=runtime/glnxa64/libmwmclmcrrt.so.${MATLABVersNum}
  Executable=${EXEDIR}/${CompiledMATLABProgram}
fi

# If the Matlab Runtime is installed in a non-default location, define the correct path 
# on the next line and uncomment it (remove the leading "#") or define it as a system
# environment variable
#BrainSuiteMCR="/path/to/your/MCR";

if [ -z "$BrainSuiteMCR" ]; then
  if [ -e ${DefaultRuntimePath} ]; then
    BrainSuiteMCR="${DefaultRuntimePath}";
  elif [ -e ${DefaultInstallPath}/runtime ]; then
    BrainSuiteMCR="${DefaultInstallPath}";
    echo
    echo "Located Matlab installation with runtime directory ${BrainSuiteMCR}."
    echo
  else
    echo
    echo "Could not locate an installation of MATLAB Runtime ${MATLABRelease} (${MATLABVersNum}) on this system."
    echo 
    echo "Please install the MATLAB Runtime ${MATLABRelease} (${MATLABVersNum}) from MathWorks website at:"
    echo
    echo "https://www.mathworks.com/products/compiler/matlab-runtime.html"
    echo 
    echo "If you already have MATLAB Runtime ${MATLABRelease} (${MATLABVersNum}) or MATLAB ${MATLABRelease}"
    echo "installed, please edit ${Program} by uncommenting and editing"
    echo "the following line near the top of the file:"
    echo
    echo "#BrainSuiteMCR=\"/path/to/your/MCR\";"
    echo
    echo "(replace /path/to/your/MCR with the path to your MCR [or Matlab] installation)"
    echo
    exit 78
  fi
fi

if [ ! -e ${BrainSuiteMCR}/${TestFile} ]; then
  echo
  echo "Could not find a valid installation of MCR ${MATLABRelease} (${MATLABVersNum}) [or Matlab ${MATLABRelease} with Matlab Compiler] at following location:"
  echo ${BrainSuiteMCR}
  echo
  echo "Could not find following file, which must be present for a valid installation:"
  echo ${BrainSuiteMCR}/${TestFile}
  echo
  echo "Please install the Matlab MCR ${MATLABRelease} (${MATLABVersNum}) from MathWorks at:"
  echo "     https://www.mathworks.com/products/compiler/matlab-runtime.html"
  echo 
  echo "If you already have MCR ${MATLABRelease} (${MATLABVersNum}) [or Matlab ${MATLABRelease} with Matlab Compiler]"
  echo "installed, please edit ${Program} by uncommenting and editing"
  echo "the following line near the top of the file:"
  echo
  echo "#BrainSuiteMCR=\"/path/to/your/MCR\";"
  echo
  echo "(replace /path/to/your/MCR with the path to your MCR [or Matlab] installation)"
  echo
  echo "NOTE: THE EXACT VERSION NUMBER IS IMPORTANT. NEWER VERSIONS WILL NOT WORK."
  exit 78
fi

read -d '' usage <<EOF
${CompiledMATLABProgram}

Usage:

  ${Program} -i spectfile.mat -m spectmask_file.mat -c colorfile.mat -o output_prefix -t figure_type [options]

Required arguments:
  -i, --spect_imfile      spectral image file produced by solver
  -m, --spectmaskfile     spectral mask file
  -c, --color             color definition .mat file (must contain 'color')
  -o, --outprefix         prefix to be used for output composite figures
  -t, --file_types        output figure type (png|eps|epsc|pdf, etc.)

Optional arguments (passed as name-value pairs to plot_comp_maps):
  -w, --weights           component weights (e.g. "[1 0.5 0.3]" as MATLAB-style string)
  -b, --cbar              1 to show colorbar, 0 to hide (default = 0)

Example:

  ${Program} -i DRCSI_inj_mouse_data_nnls_spect.mat -m data/spectrum_mask_inj_mouse.mat -c three_color.mat \\
             -o DRCSI_inj_mouse_data_nnls_comp -t png

note: all required arguments must be provided!

EOF

# Parse inputs
if [ $# -lt 1 ]; then
  echo
  echo "$usage"
  echo
  exit
fi

spectfile=""
spectmask_file=""
colorfile=""
output_prefix=""
output_types=""

weights=""   # NEW optional
cbar=""      # NEW optional

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo
      echo "$usage"
      echo
      shift # past argument
      exit 0
      ;;
    -i|--spect_imfile)
      spectfile="$2"
      shift; shift;
      ;;
    -m|--spectmaskfile)
      spectmask_file="$2"
      shift; shift;
      ;;
    -c|--color)
      colorfile="$2"
      shift; shift;
      ;;
    -o|--outprefix)
      output_prefix="$2"
      shift; shift;
      ;;
    -t|--file_types)
      shift
      arg=$1
      while [[ ! ${arg:0:1} == "-" ]]; do
        # As in other wrappers: only the final type is used currently
        output_types="$1"
        shift
        arg=$1
        if (($#<1)); then break; fi
      done
      ;;
    -w|--weights)          # NEW
      weights="$2"
      shift; shift;
      ;;
    -b|--cbar)             # NEW
      cbar="$2"
      shift; shift;
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      echo "Unrecognized parameter $1"
      exit 1
      ;;
  esac
done

ArgsOK=1
errs=""

if [ "x$spectfile" = "x" ]; then
  errs="${errs}\nNo input spectral file provided -- -i option is required!"
  ArgsOK=0
else
  if [ ! -f "$spectfile" ]; then
    errs="${errs}\nInput spectral file $spectfile does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$spectmask_file" = "x" ]; then
  errs="${errs}\nNo spectral mask file provided -- -m option is required!"
  ArgsOK=0
else
  if [ ! -f "$spectmask_file" ]; then
    errs="${errs}\nSpectral mask file $spectmask_file does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$colorfile" = "x" ]; then
  errs="${errs}\nNo color file provided -- -c option is required!"
  ArgsOK=0
else
  if [ ! -f "$colorfile" ]; then
    errs="${errs}\nColor file $colorfile does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$output_prefix" = "x" ]; then
  errs="${errs}\nNo output prefix provided -- -o option is required!"
  ArgsOK=0
fi
if [ "x$output_types" = "x" ]; then
  errs="${errs}\nNo output image types provided -- -t option is required!"
  ArgsOK=0
fi

# (Optional) tiny validation for cbar (0/1)
if [ -n "$cbar" ]; then
  if ! [[ "$cbar" =~ ^[0-9]+$ ]]; then
    errs="${errs}\nInvalid cbar '$cbar'. Must be 0 or 1."
    ArgsOK=0
  else
    if (( cbar != 0 && cbar != 1 )); then
      errs="${errs}\nInvalid cbar '$cbar'. Must be 0 or 1."
      ArgsOK=0
    fi
  fi
fi

if (($ArgsOK==0)); then
  echo
  echo "$usage"
  echo
  printf "Error:$errs\n\n"
  exit 1
fi

# Set up path for MCR applications.
if [[ "$OSTYPE" == "darwin"* ]]; then
  DYLD_LIBRARY_PATH=.:${BrainSuiteMCR}/runtime/${Arch} ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${BrainSuiteMCR}/bin/${Arch} ;
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${BrainSuiteMCR}/sys/os/${Arch};
  export DYLD_LIBRARY_PATH;
else
  LD_LIBRARY_PATH=.:${BrainSuiteMCR}/runtime/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${BrainSuiteMCR}/bin/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${BrainSuiteMCR}/sys/os/glnxa64;
  MCRJRE=${BrainSuiteMCR}/sys/java/jre/glnxa64/jre/lib/amd64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ; 
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;  
  XAPPLRESDIR=${BrainSuiteMCR}/X11/app-defaults ;
  export LD_LIBRARY_PATH;
  export XAPPLRESDIR;
fi

# Build argument list so we can conditionally append optional params
ARGS=( spect_imfile "${spectfile}" spectmaskfile "${spectmask_file}" color "${colorfile}" outprefix "${output_prefix}" file_types ${output_types} )

if [ -n "$weights" ]; then
  ARGS+=( weights "$weights" )
fi
if [ -n "$cbar" ]; then
  ARGS+=( cbar "$cbar" )
fi

echo Running "${Executable}" "${ARGS[@]}"
"${Executable}" "${ARGS[@]}"

exit
