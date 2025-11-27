#!/bin/bash
EXEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)" ;
export EXEDIR;
Program=$(basename ${BASH_SOURCE[0]})
CompiledMATLABProgram=${Program%.sh}
MATLABRelease=R2024b
MATLABRelease=v242
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
  ${Program} -i input_file.mat -o output_file.mat -c config.ini -m mask_file.mat -d dict_file.mat

where
  input_file.mat   input image .mat file, containing data, im_mask, and T1, T2, D
  output_file.mat  output spectral image file
  config.ini       configuration file in .ini format

Example:
  spectEstimation.sh -i data/DRCSI_data_format_v1.mat -m data/DRCSI_whole_spatmask.mat -d data/DRCSI_dict.mat -c demos/DRCSI_ladmm.ini -o Result/DRCSI_inj_mouse_data_ladmm_spect.mat'

note: all arguments are required!

EOF
#  ${Program} -i data/DRCSI_inj_mouse_data.mat -o DRCSI_inj_mouse_data_nnls_spect.mat -c demos/demo2_nnls.ini

# Parse inputs
if [ $# -lt 1 ]; then
  echo
  echo "$usage"
  echo
  exit
fi

config_file=""
input_file=""
output_file=""
mask_file=""
dict_file=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo
      echo "$usage"
      echo
      shift # past argument
      exit 0
      ;;
    -i|--imgfile)
      input_file="$2"
      shift; shift;
      ;;
    -o|--outprefix)
      output_file="$2"
      shift; shift;
      ;;
    -m|--spatmaskfile)
      mask_file="$2"
      shift; shift;
      ;;
    -d|-s|--spect_infofile)
      dict_file="$2"
      shift; shift;
      ;;
    -c|--configfile)
      config_file="$2"
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

if [ "x$input_file" = "x" ]; then
  errs="${errs}\nNo input file provided -- -i option is required!"
  ArgsOK=0
fi
if [ "x$output_file" = "x" ]; then
  errs="${errs}\nNo output file provided -- -o option is required!"
  ArgsOK=0
fi
if [ "x$mask_file" = "x" ]; then
  errs="${errs}\nNo mask file provided -- -m option is required!"
  ArgsOK=0
fi
if [ "x$dict_file" = "x" ]; then
  errs="${errs}\nNo output file provided -- -o option is required!"
  ArgsOK=0
fi
if [ "x$config_file" = "x" ]; then
  errs="${errs}\nNo config file provided -- -c option is required!"
  ArgsOK=0
else
  if [ ! -f "$config_file" ]; then
    errs="${errs}\nConfig file $config_file does not exist!"
    ArgsOK=0
  fi
fi

if [ ! -f "$input_file" ]; then
  errs="${errs}\nInput file $input_file does not exist!"
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

"${Executable}" imgfile $input_file spatmaskfile $mask_file configfile $config_file spect_infofile $dict_file outprefix $output_file

exit
