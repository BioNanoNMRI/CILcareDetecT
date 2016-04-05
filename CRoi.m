classdef CRoi < handle
	
	properties
		name
		color
		bwMask
		position    % [x y]
	end
	
	methods
		
		%----------------------------------------------------------------------------------------------------------------------- CRoi
		function obj = CRoi(name,color,bwMask,position)
			obj.name = name;
			obj.color = color;
			obj.bwMask = bwMask;
			obj.position = position;
		end
		
		%--------------------------------------------------------------------------------------------------------------------- delete
		function delete(obj)
			
		end
		
		%--------------------------------------------------------------------------------------------------------------- segmentImage
		function ret = segmentImage(obj,dataImage)
			if ~isempty(dataImage)
				ret = dataImage .* double(obj.bwMask);
			else
				ret = [];
			end
		end
		
		%-------------------------------------------------------------------------------------------------------------------- getName
		function ret = getName(obj)
			ret = obj.name;
		end
		
		%------------------------------------------------------------------------------------------------------------------- getColor
		function ret = getColor(obj)
			ret = obj.color;
		end
		
		%-------------------------------------------------------------------------------------------------------------------- getArea
		function ret = getArea(obj)
			ret = bwarea(obj.bwMask);
		end
		
		%---------------------------------------------------------------------------------------------------------------- getPosition
		function [ret] = getPosition(obj)
			ret = obj.position;
		end
		
		%-------------------------------------------------------------------------------------------------------------------- getMask
		function ret = getMask(obj)
			ret = obj.bwMask;
		end
		
		%--------------------------------------------------------------------------------------------------------------------- getMin
		function ret = getMin(obj,dataImage)
			if ~isempty(dataImage)
				ret = min(dataImage(obj.bwMask));
			else
				ret = NaN;	
			end
		end
		
		%--------------------------------------------------------------------------------------------------------------------- getMax
		function ret = getMax(obj,dataImage)
			if ~isempty(dataImage)
				ret = max(dataImage(obj.bwMask));
			else
				ret = NaN;	
			end
		end
		
		%-------------------------------------------------------------------------------------------------------------------- getMean
		function ret = getMean(obj,dataImage)
			if ~isempty(dataImage)
				ret = mean(dataImage(obj.bwMask));
			else
				ret = NaN;	
			end
		end
		
		%------------------------------------------------------------------------------------------------------------------ getMedian
		function ret = getMedian(obj,dataImage)
			if ~isempty(dataImage)
				ret = median(double(dataImage(obj.bwMask)));
			else
				ret = NaN;	
			end
		end
		
		%-------------------------------------------------------------------------------------------------------------------- getMode
		function ret = getMode(obj,dataImage)
			if ~isempty(dataImage)
				ret = mode(dataImage(obj.bwMask));
			else
				ret = NaN;	
			end
		end
		
		%--------------------------------------------------------------------------------------------------------------------- getStd
		function ret = getStd(obj,dataImage)
			if ~isempty(dataImage)
				ret = std(double(dataImage(obj.bwMask)));
			else
				ret = NaN;	
			end
		end
		
		%--------------------------------------------------------------------------------------------------------------------- getVar
		function ret = getVar(obj,dataImage)
			if ~isempty(dataImage)
				ret = var(double(dataImage(obj.bwMask)));
			else
				ret = NaN;	
			end
		end
		
		%--------------------------------------------------------------------------------------------------------------------- getSem
		function ret = getSem(obj,dataImage)
			if ~isempty(dataImage)
				ret = obj.getStd(dataImage)/sqrt(bwarea(obj.bwMask));
			else
				ret = NaN;	
			end
		end

	end % Public Methods
	
end % Class Definition