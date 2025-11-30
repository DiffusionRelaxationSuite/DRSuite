#!/bin/bash
# set -e

# TODO: graphics output flag can only take one argument now
# if multiple are provided, then it will use the final one.
# This should be fixed in later versions (10/10/25 - dws)

EXEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)" ;
export EXEDIR;
Program=$(basename ${BASH_SOURCE[0]})
CompiledMATLABProgram=${Program%.sh}
MATLABRelease=R2025b
MATLABVersNum=25.2

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

if [[ -z "$BrainSuiteMCR" ]]; then
  if [[ -e "${DefaultRuntimePath}" ]]; then
    BrainSuiteMCR="${DefaultRuntimePath}";
  elif [[ -e "${DefaultInstallPath}/runtime" ]]; then
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

if [[ ! -e "${BrainSuiteMCR}/${TestFile}" ]]; then
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
    ${Program} -i spect_imfile.mat -g imgfile.mat -m maskfile.mat -o output_prefix -t figure_types [optional arguments]

Required arguments:
  -i, --spect_imfile   input spectroscopic image .mat file
  -g, --imgfile        input MR image .mat file (for background image)
  -m, --spatmaskfile   spatial mask .mat file (must contain im_mask)
  -o, --outprefix      output prefix for saved figures
  -t, --file_types     output figure types (png, pdf, etc.; last one is used)

Optional arguments (passed as name-value pairs to plot_spect_im):
  -s, --ax_scale       axis scale for spectrum (e.g. 'linear' or 'log')
  -l, --ax_lims        axis limits, MATLAB-style string (e.g. "[10 200]")
  -c, --color          line color (1D) or colormap name (2D)
  -e, --enc_idx        encoding index (integer slice index)
  -w, --linewidth      line width for 1D spectrum (positive number)
  -r, --threshold      threshold for 2D overlay (e.g. 0.1)

Example:
  ${Program} -i DRCSI_spect.mat -g DRCSI_img.mat -m mask.mat -o Result \\
             -t png -s log -l "[10 200]" -c r -e 1 -w 2 -r 0.1


note: all required arguments must be provided!
 
EOF

# Parse inputs
if [[ $# -lt 1 ]]; then
  echo
  echo "$usage"
  echo
  exit
fi

spectfile=""
imgfile=""
maskfile=""
output_prefix=""
output_types=""

# Optional MATLAB name-value arguments
ax_scale=""
ax_lims=""
cmap=""
enc_idx=""
linewidth=""
threshold=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo
      echo "$usage"
      echo
      shift
      exit 0
      ;;
    -i|--spect_imfile)
      spectfile="$2"
      shift; shift;
      ;;
    -g|--imgfile)
      imgfile="$2"
      shift; shift;
      ;;
    -m|--spatmaskfile)
      maskfile="$2"
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
        # # Only the final type is used (see TODO at top)
        # output_types="$1"
        output_types="${output_types}${output_types:+" "}$1"
        shift
        arg=$1
        if (($#<1)); then break; fi
      done
      ;;
    # Optional parameters
    -s|--ax_scale)
      ax_scale="$2"
      shift; shift;
      ;;
    -l|--ax_lims)
      ax_lims="$2"
      shift; shift;
      ;;
    -c|--color)
      cmap="$2"
      shift; shift;
      ;;
    -e|--enc_idx)
      enc_idx="$2"
      shift; shift;
      ;;
    -w|--linewidth)
      linewidth="$2"
      shift; shift;
      ;;
    -r|--threshold)
      threshold="$2"
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

# Required argument checks (existence + file existence where applicable)
if [[ -z "$spectfile" ]]; then
  errs="${errs}\nNo input spectral file provided -- -i option is required!"
  ArgsOK=0
else
  if [[ ! -f "$spectfile" ]]; then
    errs="${errs}\nInput spectral file $spectfile does not exist!"
    ArgsOK=0
  fi
fi

if [[ -z "$imgfile" ]]; then
  errs="${errs}\nNo input MR image file provided -- -g option is required!"
  ArgsOK=0
else
  if [[ ! -f "$imgfile" ]]; then
    errs="${errs}\nInput MR image file $imgfile does not exist!"
    ArgsOK=0
  fi
fi

if [[ -z "$maskfile" ]]; then
  errs="${errs}\nNo mask file provided -- -m option is required!"
  ArgsOK=0
else
  if [[ ! -f "$maskfile" ]]; then
    errs="${errs}\nMask file $maskfile does not exist!"
    ArgsOK=0
  fi
fi

if [[ -z "$output_prefix" ]]; then
  errs="${errs}\nNo output prefix provided -- -o option is required!"
  ArgsOK=0
fi

if [[ -z "$output_types" ]]; then
  errs="${errs}\nNo output image types provided -- -t option is required!"
  ArgsOK=0
fi

# Light validation for numeric optional arguments;
# detailed semantic checks still happen inside MATLAB.

if [[ -n "$enc_idx" ]]; then
  if ! [[ "$enc_idx" =~ ^[0-9]+$ ]]; then
    errs="${errs}\nInvalid enc_idx '$enc_idx'. Must be a positive integer."
    ArgsOK=0
  else
    if (( enc_idx < 1 )); then
      errs="${errs}\nInvalid enc_idx '$enc_idx'. Must be >= 1."
      ArgsOK=0
    fi
  fi
fi

if [[ -n "$linewidth" ]]; then
  # positive float / integer
  if ! [[ "$linewidth" =~ ^([1-9][0-9]*|[0-9]*\.[0-9]+)$ ]]; then
    errs="${errs}\nInvalid linewidth '$linewidth'. Must be a positive number."
    ArgsOK=0
  fi
fi

if [[ -n "$threshold" ]]; then
  # allow 0 or positive float / integer
  if ! [[ "$threshold" =~ ^(0|[1-9][0-9]*|[0-9]*\.[0-9]+)$ ]]; then
    errs="${errs}\nInvalid threshold '$threshold'. Must be a non-negative number."
    ArgsOK=0
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

# Build argument list as an array so things like "[10 200]" stay a single argument.
ARGS=( spect_imfile "${spectfile}" imgfile "${imgfile}" spatmaskfile "${maskfile}" outprefix "${output_prefix}" file_types "${output_types}" )

if [[ -n "$ax_scale" ]]; then
  ARGS+=( ax_scale "$ax_scale" )
fi
if [[ -n "$ax_lims" ]]; then
  ARGS+=( ax_lims "$ax_lims" )
fi
if [[ -n "$cmap" ]]; then
  ARGS+=( color "$cmap" )
fi
if [[ -n "$enc_idx" ]]; then
  ARGS+=( enc_idx "$enc_idx" )
fi
if [[ -n "$linewidth" ]]; then
  ARGS+=( linewidth "$linewidth" )
fi
if [[ -n "$threshold" ]]; then
  ARGS+=( threshold "$threshold" )
fi

echo Running "${Executable}" "${ARGS[@]}"
"${Executable}" "${ARGS[@]}"

exit
