function [f] = randWhiteSGAcorrRSESpread01(ex)

f = zeros(size(ex.fstructs,2), 2);

for i=1:size(ex.fstructs,2)
    f(i,1) = ex.fstructs(i).spreadSGR01;
    f(i,2) = ex.fstructs(i).relspecent;
end
