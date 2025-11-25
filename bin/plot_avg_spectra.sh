#!/bin/bash
# set -e

# TODO: graphics output flag can only take one argument now
# if multiple are provided, then it will use the final one.
# This should be fixed in later versions (10/10/25 - dws)

EXEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)" ;
export EXEDIR;
Program=$(basename ${BASH_SOURCE[0]})
CompiledMATLABProgram=${Program%.sh}
MATLABRelease=R2024b
MATLABVersion=v242
MATLABVersNum=24.2

if [[ "$OSTYPE" == "darwin"* ]]; then
  Arch=maci64
  if [[ "$(uname -m)" == "arm64" ]]; then Arch=maca64; fi
  DefaultRuntimePath=/Applications/MATLAB/MATLAB_Runtime/${MATLABVersion}
  DefaultInstallPath=/Applications/MATLAB_${MATLABRelease}.app/
  TestFile=runtime/${Arch}/libmwmclmcrrt.${MATLABVersNum}.dylib
  Executable=${EXEDIR}/${CompiledMATLABProgram}.app/Contents/MacOS/${CompiledMATLABProgram}
else
  DefaultRuntimePath=/usr/local/MATLAB/MATLAB_Runtime/${MATLABVersion}
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
  echo "If you already have MCR ${MATLABRelease} (${MATLABVersNum}) [or Matlab ${MATLABRelease}ABRelease} with Matlab Compiler]"
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
    ${Program} -i spectral_file.mat -m maskfile.mat -o output_prefix -t figure_types)

where
  input_file.mat   input image .mat file, containing data, im_mask, and T1, T2, D
  output_file.mat  output spectral image file
  maskfile.mat     mask file
  figure_types     output figure types (png, epsc, etc)

Example:
  ${Program} -i DRCSI_inj_mouse_data_nnls_spect.mat -m mask.mat -o Result -t png epsc


note: all arguments are required!
 
EOF

# Parse inputs
if [ $# -lt 1 ]; then
  echo
  echo "$usage"
  echo
  exit
fi


spectfile=""
imgfile=""
output_prefix=""
output_types=""

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
        # output_types="$output_types $1"
        output_types="$1"
        shift
        arg=$1
        if (($#<1)); then break; fi
      done
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
    errs="${errs}\Input spectral file $spectfile does not exist!"
    ArgsOK=0
  fi
fi
if [ "x$maskfile" = "x" ]; then
  errs="${errs}\nNo mask file provided -- -m option is required!"
  ArgsOK=0
else
  if [ ! -f "$maskfile" ]; then
    errs="${errs}\Mask file $maskfile does not exist!"
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

#example:
#plotAvgSpectra('spect_imfile','Phantom1D/Phantom1D_data_ladmm_spect.mat', 'spatmaskfile', 'Phantom1D/Phantom_mask.mat', ...
    # 'outprefix','Phantom1D/Phantom1D_data_ladmm_avg_spectra','linewidth',3,'ax_scale',{'log'},'color','g','cbar',1, ...
    # 'ax_lim',"[10 200]", 'file_types', {'png','pdf'});
echo Running "${Executable}" spect_imfile "${spectfile}" spatmaskfile "${maskfile}" outprefix "${output_prefix}" file_types ${output_types}
"${Executable}" spect_imfile "${spectfile}" spatmaskfile "${maskfile}" outprefix "${output_prefix}" file_types ${output_types}

exit
