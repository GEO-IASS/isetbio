function displayInfo(obj)
% Print various infos about the cone mosaic
%
% NPC, ISETBIO TEAM, 2015

    fprintf('\nMosaic info:\n');
    fprintf('%53s %2.1f (w) x %2.1f (h)\n', 'Size (microns):', obj.width*1e6, obj.height*1e6);
    fprintf('%53s %2.2f (w) x %2.2f (h) \n', 'FOV (deg):', obj.fov(1), obj.fov(2));
    fprintf('%53s %0.0f\n', 'Grid resampling factor:', obj.resamplingFactor);
    fprintf('%53s %2.2f (w) x %2.2f (h)\n', 'Cone geometric aperture (microns):', obj.pigment.width*1e6, obj.pigment.height*1e6);
    fprintf('%53s %2.2f (w) x %2.2f (h)\n', 'Cone light colleting aperture (microns):', obj.pigment.pdWidth*1e6, obj.pigment.pdHeight*1e6);
    fprintf('%53s %2.3f \n', 'Cone geometric area (microns^2):', obj.pigment.area*1e12);
    fprintf('%53s %2.3f\n', 'Cone light colleting area (microns^2):', obj.pigment.pdArea*1e12);
    fprintf('%53s %2.0f cols x %2.0f rows\n', 'Rectangular grid:', size(obj.patternOriginatingRectGrid,2), size(obj.patternOriginatingRectGrid,1));
    fprintf('%53s %2.0f cols x %2.0f rows\n', 'Resampled grid:', obj.cols, obj.rows);
    fprintf('%53s %d\n', 'Total cones:', numel(obj.pattern));
    fprintf('%53s %d\n', 'Active cones:' , numel(find(obj.pattern > 1)));
    fprintf('%53s %2.1f cones/mm^2\n', 'Cone density (all cones):', numel(obj.pattern)/(obj.width*obj.height*1e6));
    fprintf('%53s %2.1f cones/mm^2\n\n', 'Cone density (active cones):', numel(find(obj.pattern > 1))/(obj.width*obj.height*1e6));
end
