function lines=change_runtime_version(srcfile) %, dstfile, version)
release = matlabRelease.Release;
versnum=version;
versnum=versnum(1:4);
lines = readlines(srcfile);
for i=1:length(lines)
    z=strtrim(lines(i));
    [token,remain] = strtok(strtrim(lines(i)), '=');
    token=strtrim(token);
    if (token=="MATLABRelease")
        fprintf(1,"-%s\n",lines(i));
        lines(i)=sprintf("MATLABRelease=%s",release);
        fprintf(1,"+%s\n",lines(i));
    elseif (token=="MATLABVersNum")
        fprintf(1,"-%s\n",lines(i));
        lines(i)=sprintf("MATLABVersNum=%s",versnum);
        fprintf(1,"+%s\n",lines(i));
    end
% elseif (token=="MATLABVersion")
%     fprintf(2,"-%s\n",lines(i));
%     lines(i)=sprintf("MATLABVersion=%s",vers);
%     fprintf(1,"+%s\n",lines(i));
end
