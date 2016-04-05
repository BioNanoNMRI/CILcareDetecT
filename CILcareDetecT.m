classdef CILcareDetecT < handle
	
	properties (Constant)
		appEditor             = 'BioNanoNMRI'
		appName               = 'CILcare Detec-T'
		appVersion            = '1.1.1'

		defaultStatsFileName  = 'ROI_Stats.txt'
		defaultRoiPosFileName = 'ROI_Positions.mat'
		defaultFigureFileName = 'ROI_Figure.jpg'
		
		defaultNumOfRoi       = 9                 % TODO: release = 9
		defaultRoiDiameter    = 10                % TODO: release = 10
		defaultRoiColor       = [1 0 0]           % Full Red
		
		uiFigureWidth         = 695
		uiFigureHeight        = 523
		uiImageViewWidth      = 512
		uiImageViewHeight     = 512
		
		uiBgColor             = [.8 .8 .8]
		uiAxesBgColor         = [.6 .6 .6]
		uiEditFieldsColor     = [1 1 1]           % Full White
	end % Constant Properties
	
	properties
		% Non GUI properties
		lastUsedDir           = getenv('HOME')
		dicomDir
		dicomFileNames
		dicomTeValues                             % EchoTime values, in ms
		dicomStack
		dicomStackLength
		
		numOfRoi
		roiDiameter
		roiGlobalMask
		roiColor
		roiColorLayer
		roiTransparency       = 0.35
		
		imageMinValues
		imageMaxValues
		imageMeanValues
		
		roiList
		roiMinValues
		roiMaxValues
		roiMeanValues
		roiMedianValues
		roiStdValues
		roiVarValues
		roiSemValues
		roiT2Values                               % T2 values measured in ROI, in ms
		
		% GUI properties
		uiMainFigure
		uiRoiManagerPanel
		uiImagePanel
		uiMainAxes
		uiMainImage
		uiImageScrollPanel
		uiMagBox
		
		uiLoadDicomButton
		uiRoiColorButton
		uiDrawRoiSetButton
		uiClearRoiSetButton	
		uiSaveRoiStatsButton
		uiLoadRoiSetButton
		uiSaveRoiSetButton
		uiSaveFigureButton
		
		uiNumOfRoiText
		uiNumOfRoiEdit
		uiRoiDiameterText
		uiRoiDiameterEdit
		uiRoiTransparencyText
		uiRoiTransparencySlider		
	end % Public Properties

	methods
		
		%-------------------------------------------------------------------------------------------------------------- CILcareDetecT
		function obj = CILcareDetecT
			obj.uiMainFigure = figure(...
				'NumberTitle','off',...
				'Toolbar','none',...
				'Menubar','none',...
				'Name',[obj.appEditor ' | ' obj.appName ' (' obj.appVersion ')'],...
				'Resize','off',...
				'Position',[0 0 obj.uiFigureWidth obj.uiFigureHeight],...
				'CloseRequestFcn',@obj.onCloseApp);
			
			movegui(obj.uiMainFigure,'center');

			obj.uiImagePanel = uipanel(...
				'Parent',obj.uiMainFigure,...
				'Units','pixels',...
				'Position',obj.uiRelativePosition(obj.uiMainFigure,160,5,obj.uiImageViewWidth+17,obj.uiImageViewHeight+4));
			
			obj.uiMainAxes = axes(...
				'Parent',obj.uiImagePanel,...
				'Color',obj.uiAxesBgColor,...
				'XTick',[],'YTick',[],...
				'Units','normalized',...
				'Position',[0 0 1 1]);
			
			obj.uiRoiManagerPanel = uipanel(...
				'Parent',obj.uiMainFigure,...
				'Title','ROI Manager',...
				'BackgroundColor',obj.uiBgColor,...
				'Units','pixels',...
				'Position',obj.uiRelativePosition(obj.uiMainFigure,5,45,147,400)');
			
			obj.uiLoadDicomButton = uicontrol(...
				'Parent',obj.uiMainFigure,...
				'Style','pushbutton',...
				'String','Load DICOM...',...
				'Position',obj.uiRelativePosition(obj.uiMainFigure,5,5,147,30),...
				'Callback',@obj.onLoadDicomButtonClicked);
			
			obj.uiNumOfRoiText = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','text',...
				'BackgroundColor',obj.uiBgColor,...
				'HorizontalAlignment','left',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,20,105,25),...
				'String','Number of ROI :');
			
			obj.uiNumOfRoiEdit = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','edit',...
				'BackgroundColor',obj.uiEditFieldsColor,...
				'HorizontalAlignment','right',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,110,16,30,25),...
				'String',num2str(obj.defaultNumOfRoi),...
				'Callback',@obj.onNumOfRoiChanged);
			
			obj.uiRoiDiameterText = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','text',...
				'BackgroundColor',obj.uiBgColor,...
				'HorizontalAlignment','left',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,47,105,25),...
				'String','ROI Diameter (px) :');
			
			obj.uiRoiDiameterEdit = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','edit',...
				'BackgroundColor',obj.uiEditFieldsColor,...
				'HorizontalAlignment','right',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,110,43,30,25),...
				'String',num2str(obj.defaultRoiDiameter),...
				'Callback',@obj.onRoiDiameterChanged);
			
			obj.uiRoiTransparencyText = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','text',...
				'BackgroundColor',obj.uiBgColor,...
				'HorizontalAlignment','left',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,75,135,25),...
				'String','ROI Transparency');
			
			obj.uiRoiTransparencySlider = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','slider',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,95,135,20),...
				'Value',obj.roiTransparency,...
				'SliderStep',[0.01 0.1],...
				'min',0,'max',1);
			
			addlistener(obj.uiRoiTransparencySlider,'ContinuousValueChange',@obj.onRoiTransparencySliderChanged);
			
			obj.uiRoiColorButton = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','pushbutton',...
				'String','ROI Color...',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,125,135,30),...
				'Callback',@obj.onRoiColorButtonClicked);
			
			obj.uiDrawRoiSetButton = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','pushbutton',...
				'String','Draw ROI Set',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,165,135,30),...
				'Callback',@obj.onDrawRoiSetButtonClicked);
			
			obj.uiClearRoiSetButton = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','pushbutton',...
				'String','Clear ROI Set',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,205,135,30),...
				'Callback',@obj.onClearRoiSetButtonClicked);
			
			obj.uiLoadRoiSetButton = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','pushbutton',...
				'String','Load ROI Set...',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,245,135,30),...
				'Callback',@obj.onLoadRoiSetButtonClicked);
			
			obj.uiSaveRoiSetButton = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','pushbutton',...
				'String','Save ROI Set...',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,285,135,30),...
				'Callback',@obj.onSaveRoiSetButtonClicked);
			
			obj.uiSaveRoiStatsButton = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','pushbutton',...
				'String','Save ROI Stats...',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,325,135,30),...
				'Callback',@obj.onSaveRoiStatsButtonClicked);
			
			obj.uiSaveFigureButton = uicontrol(...
				'Parent',obj.uiRoiManagerPanel,...
				'Style','pushbutton',...
				'String','Save Figure...',...
				'Position',obj.uiRelativePosition(obj.uiRoiManagerPanel,5,365,135,30),...
				'Callback',@obj.onSaveFigureButtonClicked);
			
			% Disable all UI controls contained in the ROI Manager panel, until some DICOM images are loaded
			set(findall(obj.uiRoiManagerPanel,'-property','Enable'),'Enable','off');
			
			% Initialize non GUI properties
			obj.numOfRoi = obj.defaultNumOfRoi;
			obj.roiDiameter = obj.defaultRoiDiameter;
			obj.roiColor = obj.defaultRoiColor;
		end
		
		%----------------------------------------------------------------------------------------------------------------- onCloseApp
		function onCloseApp(obj,~,~)
			delete(obj.uiMainFigure);
		end
		
		%--------------------------------------------------------------------------------------------------- onLoadDicomButtonClicked
		function onLoadDicomButtonClicked(obj,~,~)			
			% Let the user select a directory containing his DICOM files
			folderName = uigetdir(obj.lastUsedDir,'Select a directory containing your DICOM files');
			
			% Check if user has cancelled file loading
			if isequal(folderName,0)
				return;
			end
			
			% Save folder location for later usage
			obj.lastUsedDir = folderName;
			obj.dicomDir = folderName;
			
			% Open DICOM files from selected directory and store images in a stack
			obj.dicomFileNames = dir(strcat(obj.dicomDir,'/*.dcm'));
			
			% Check if DICOM files have been found in the selected directory
			if isempty(obj.dicomFileNames)
				errordlg('No DICOM files found in that directory !','Error','modal');
				return;
			end
			
			% Remove subdirectories
			subDirs = [obj.dicomFileNames.isdir];
			obj.dicomFileNames(subDirs) = [];
			obj.dicomFileNames = {obj.dicomFileNames.name};
			
			% Store the number of DICOM image in the stack for later usage
			obj.dicomStackLength = length(obj.dicomFileNames); % is a double format number
			
			% Read DICOM image size from the first DICOM file and preallocate 3D matrix
			cellFileName = fullfile(obj.dicomDir,obj.dicomFileNames(1));
			fullFileName = cellFileName{1};
			dicomInfo = dicominfo(fullFileName);
			
			% Preallocate memory for matrices (performance improvement)
			obj.dicomStack = zeros(dicomInfo.Height,dicomInfo.Width,obj.dicomStackLength);
			
			% Load data and info from DICOM files into the stack
			for imageIndex = 1:obj.dicomStackLength
				cellFileName = fullfile(obj.dicomDir,obj.dicomFileNames(imageIndex));
				fullFileName = cellFileName{1};
				dicomInfo = dicominfo(fullFileName);
				obj.dicomTeValues(imageIndex) = dicomInfo.EchoTime;
				obj.dicomStack(:,:,imageIndex) = dicomread(fullFileName);
				
				% Compute min, max and mean intensty on the whole current image for later usage
				obj.imageMinValues(imageIndex) = min(min(obj.dicomStack(:,:,imageIndex)));
				obj.imageMaxValues(imageIndex) = max(max(obj.dicomStack(:,:,imageIndex)));
				obj.imageMeanValues(imageIndex) = mean(mean(obj.dicomStack(:,:,imageIndex)));
			end			
			
			% Build a full color image of the size of the DICOM images, for later ROI color overlay
			obj.rebuildRoiColorLayer;
			
			% Display the first image of the stack, the user wil draw his ROI on obj image only
			obj.updateImage;
			
			% Build an image scroll panel for easier image navigation
			if isempty(obj.uiImageScrollPanel)
				obj.uiImageScrollPanel = imscrollpanel(obj.uiImagePanel,obj.uiMainImage);
			end
			
			% Enable all UI controls contained in the ROI Manager panel
			set(findall(obj.uiRoiManagerPanel,'-property','Enable'),'Enable','on');
			
			% Clear the ROI list, since the size of the DICOM file loaded migth not match the previous loaded one
			obj.roiList = [];
			
			% Disable ROI stats and ROI positions saving buttons since there are no ROI to work on at the moment
			set(obj.uiSaveRoiStatsButton,'Enable','off');
			set(obj.uiSaveRoiSetButton,'Enable','off');
		end
		
		%---------------------------------------------------------------------------------------------------------- onNumOfRoiChanged
		function onNumOfRoiChanged(obj,hEdit,~)
			% Update GUI edit field
			obj.numOfRoi = str2double(get(hEdit,'String')); % TODO: check if string value is a positive integer
			
			% Empty the ROI list because here if ROI diameter is changed next, rebuilding the ROI set will fail
			obj.clearRoiSet;
		end
		
		%------------------------------------------------------------------------------------------------------- onRoiDiameterChanged
		function onRoiDiameterChanged(obj,hEdit,~)
			% Update GUI edit field
			obj.roiDiameter = str2double(get(hEdit,'String')); % TODO: check if string value is a positive integer
			
			% If ROI list is empty, do not rebuild ROI set with new diameter
			if isempty(obj.roiList)
				return;
			end
			
			% Retrieve current ROI positions
			roiPositions = zeros(obj.numOfRoi,2);
			for roiIndex = 1:obj.numOfRoi
				roiPosition = obj.roiList(roiIndex).getPosition;
				roiPositions(roiIndex,1) = roiPosition(1);
				roiPositions(roiIndex,2) = roiPosition(2);
			end
			
			% Rebuild ROI set with new diameter
			obj.rebuildRoiSet(roiPositions);
		end
		
		%--------------------------------------------------------------------------------------------- onRoiTransparencySliderChanged
		function onRoiTransparencySliderChanged(obj,hSlider,~)
			obj.roiTransparency = get(hSlider,'Value');
			obj.colorRoiSet;
		end
		
		%---------------------------------------------------------------------------------------------------- onRoiColorButtonClicked
		function onRoiColorButtonClicked(obj,~,~)
			% Ask the user to choose a ROI color, if operation is cancelled previous color is brought back
			obj.roiColor = uisetcolor(obj.roiColor,'Select a ROI color');
			
			% Rebuild ROI color layer with new color, even if no ROI are currently drawn
			obj.rebuildRoiColorLayer;
			
			% If ROI list is empty, do not rebuild ROI set with new color
			if isempty(obj.roiList)
				return;
			end
			
			% Retrieve current ROI positions
			roiPositions = zeros(obj.numOfRoi,2);
			for roiIndex = 1:obj.numOfRoi
				roiPosition = obj.roiList(roiIndex).getPosition;
				roiPositions(roiIndex,1) = roiPosition(1);
				roiPositions(roiIndex,2) = roiPosition(2);
			end
			
			% Rebuild ROI set with new color
			obj.rebuildRoiSet(roiPositions);			
		end
		
		%-------------------------------------------------------------------------------------------------- onDrawRoiSetButtonClicked
		function onDrawRoiSetButtonClicked(obj,~,~)
			% Build ROI set from mouse position
			obj.rebuildRoiSet([]);
			
			% Enable ROI stats and ROI positions saving buttons since there are now ROI to work on
			set(obj.uiSaveRoiStatsButton,'Enable','on');
			set(obj.uiSaveRoiSetButton,'Enable','on');
		end
		
		%------------------------------------------------------------------------------------------------- onClearRoiSetButtonClicked
		function onClearRoiSetButtonClicked(obj,~,~)
			% Clear the list or ROI objects
			obj.clearRoiSet;
			
			% Disable ROI stats and ROI positions saving buttons since there are anymore ROI to work on at the moment
			set(obj.uiSaveRoiStatsButton,'Enable','off');
			set(obj.uiSaveRoiSetButton,'Enable','off');
		end
		
		%-------------------------------------------------------------------------------------------------- onLoadRoiSetButtonClicked
		function onLoadRoiSetButtonClicked(obj,~,~)
			% Let the user select a file containing the ROI position values
			[fileName,pathName] = uigetfile('*.mat','Load ROI positions',obj.lastUsedDir);
			
			% Check if user has cancelled file loading
			if isequal(fileName,0)
				return;
			end
			
			% Save last used directory location for later usage
			obj.lastUsedDir = pathName;
			
			% Load ROI positions from file
			roiPositions = [];
			load(fullfile(pathName,fileName),'roiPositions');
			
			% Clear all ROI before building new ones
			obj.clearRoiSet;
			
			% Build new ROI Set from file, they will be displayed at the current ROI diameter
			obj.rebuildRoiSet(roiPositions);
			
			% Enable ROI stats and ROI positions saving buttons since there are now ROI to work on
			set(obj.uiSaveRoiStatsButton,'Enable','on');
			set(obj.uiSaveRoiSetButton,'Enable','on');
		end
		
		%-------------------------------------------------------------------------------------------------- onSaveRoiSetButtonClicked
		function onSaveRoiSetButtonClicked(obj,~,~)
			% Let the user select a folder and a fileName to save the ROI position values
			[fileName,pathName] = uiputfile(fullfile(obj.lastUsedDir,obj.defaultRoiPosFileName),'Save ROI Positions');
			
			% Check if user has cancelled file loading
			if isequal(fileName,0)
				return;
			end
			
			% Save last used directory location for later usage
			obj.lastUsedDir = pathName;
			
			% Build a list of ROI positions contained in ROI objects
			roiPositions = zeros(obj.numOfRoi,2);
			for roiIndex = 1:obj.numOfRoi
				roiPosition = obj.roiList(roiIndex).getPosition;
				roiPositions(roiIndex,1) = roiPosition(1);
				roiPositions(roiIndex,2) = roiPosition(2);
			end
			
			% Save ROI positions to a .mat file
			save(fullfile(pathName,fileName),'roiPositions');
		end
		
		%------------------------------------------------------------------------------------------------ onSaveRoiStatsButtonClicked
		function onSaveRoiStatsButtonClicked(obj,~,~)
			% Let the user select a folder and a fileName to save the Stats text file
			[fileName,pathName] = uiputfile(fullfile(obj.lastUsedDir,obj.defaultStatsFileName),'Save ROI Stats');
			
			% Check if user has cancelled file loading
			if isequal(fileName,0)
				return;
			end
			
			% Save last used directory location for later usage
			obj.lastUsedDir = pathName;
			
			% Save ROI stats as TXT file
			fullFileName = fullfile(pathName,fileName);
			obj.saveRoiStatsToTxt(fullFileName);
			
			% Save ROI stats as CSV file (CSV delimiter = semi-colon)
			[pathstr,name] = fileparts(fullFileName);
			fullFileName = fullfile(pathstr,[name '.csv']);
			obj.saveRoiStatsToCsv(fullFileName);
		end
		
		%-------------------------------------------------------------------------------------------------- onSaveFigureButtonClicked
		function onSaveFigureButtonClicked(obj,~,~)
			% Let the user select a folder and a fileName for figure saving
			[fileName,pathName] = uiputfile(fullfile(obj.lastUsedDir,obj.defaultFigureFileName),'Save Figure');
			
			% Check if user has cancelled file loading
			if isequal(fileName,0)
				return;
			end
			
			% Save last used directory location for later usage
			obj.lastUsedDir = pathName;
			
			% Save main figure to JPG file
			% Note: solution found on the web @ http://stackoverflow.com/questions/19534169/matlab-saving-picture
			% MatLab's "saveas" and "print" functions are buggy/messy, especially regarding the image resolution...
			currentFrame = getframe(gcf);
			[currentImage,currentMap] = frame2im(currentFrame);
			if isempty(currentMap)
				imwrite(currentImage,fullfile(pathName,fileName));
			else
				imwrite(currentImage,currentMap,fullfile(pathName,fileName));
			end
		end
		
		%---------------------------------------------------------------------------------------------------------------- updateImage
		function updateImage(obj)
			% Display the first image of the DICOM stack, at optimized range
			obj.uiMainImage = imshow(obj.dicomStack(:,:,1),[],'Parent',obj.uiMainAxes);
		end
		
		%-------------------------------------------------------------------------------------------------------------- rebuildRoiSet
		function rebuildRoiSet(obj,roiPositions)
			% Determine the number of ROI to be built
			if ~isempty(roiPositions)
				% Number of ROi is equal to the number of rows in roiPositions matrix
				obj.numOfRoi = size(roiPositions,1);
				
				% Refresh the number of ROI edit field
				set(obj.uiNumOfRoiEdit,'String',num2str(obj.numOfRoi));
			end
			
			% Reset ROI that have been previously drawn
			obj.clearRoiSet;
			
			% Initialize ROI segmented image to match the size of DICOM images
			obj.roiGlobalMask = zeros(size(obj.dicomStack(:,:,1)));
			
			% Create a new ROI from a center position
			for roiIndex = 1:obj.numOfRoi
				% If roiPositions matrix is empty, ROi must be captured from mouse position
				if isempty(roiPositions)
					% Wait for a mouse double click and capture its coordinates
					[roiX,roiY] = ginput(1);
				else
					% Pick-up ROI position from roiPositions matrix
					roiX = roiPositions(roiIndex,1);
					roiY = roiPositions(roiIndex,2);
				end

				% Draw a circular ROI at the mouse cursor position				
				hRoi = imellipse(gca,[roiX-obj.roiDiameter/2, roiY-obj.roiDiameter/2,...
					               obj.roiDiameter, obj.roiDiameter]);
				
				% Build a B&W ROI mask for CRoi object creation and global mask building 
				roiBwMask = createMask(hRoi);
				newRoi = CRoi('',obj.defaultRoiColor,roiBwMask,[roiX roiY]);
							
				% Store data in a new CRoi object, add the object to the ROI list
				obj.roiList = [obj.roiList,newRoi];
				
				% Build a global ROI mask and a global ROI segmented image to be displayed further
				obj.roiGlobalMask = obj.roiGlobalMask + roiBwMask;
			end
			
			% Display ROI with color overlay
			obj.colorRoiSet;
			
			% Compute ROI stats
			obj.computeRoiStats;
		end
		
		%------------------------------------------------------------------------------------------------------- rebuildRoiColorLayer
		function rebuildRoiColorLayer(obj)
			% Build a full color image of the size of the DICOM images, for later ROI color overlay
			obj.roiColorLayer = cat(3,...
				obj.roiColor(1)*ones(size(obj.dicomStack(:,:,1))),... % Red component
				obj.roiColor(2)*ones(size(obj.dicomStack(:,:,1))),... % Green component
				obj.roiColor(3)*ones(size(obj.dicomStack(:,:,1))));   % Blue component
		end
		
		%---------------------------------------------------------------------------------------------------------------- colorRoiSet
		function colorRoiSet(obj)
			% Refresh figure in order to make the ROI contours disappear
			obj.updateImage;
			
			% Then apply color overlay to the ROI set
			if ~isempty(obj.roiGlobalMask) && ~isempty(obj.roiColorLayer)
				hold on 
				hRoiColorLayer = imshow(obj.roiColorLayer,'Parent',obj.uiMainAxes); 
				hold off
				set(hRoiColorLayer,'AlphaData',double(obj.roiGlobalMask).*double(obj.roiTransparency));
			end
		end
		
		%---------------------------------------------------------------------------------------------------------------- clearRoiSet
		function clearRoiSet(obj)
			% Empty the ROI list
			obj.roiList = [];
			
			% Refresh image displayed on figure
			obj.updateImage;
		end
		
		%------------------------------------------------------------------------------------------------------------ computeRoiStats
		function computeRoiStats(obj)
			for imageIndex = 1:obj.dicomStackLength				
				for roiIndex = 1:obj.numOfRoi
					% Compute stats from ROI and store values in arrays for later usage
					obj.roiMinValues(roiIndex,imageIndex)    = obj.roiList(roiIndex).getMin(obj.dicomStack(:,:,imageIndex));
					obj.roiMaxValues(roiIndex,imageIndex)    = obj.roiList(roiIndex).getMax(obj.dicomStack(:,:,imageIndex));
					obj.roiMeanValues(roiIndex,imageIndex)   = obj.roiList(roiIndex).getMean(obj.dicomStack(:,:,imageIndex));
					obj.roiMedianValues(roiIndex,imageIndex) = obj.roiList(roiIndex).getMedian(obj.dicomStack(:,:,imageIndex));
					obj.roiStdValues(roiIndex,imageIndex)    = obj.roiList(roiIndex).getStd(obj.dicomStack(:,:,imageIndex));
					obj.roiVarValues(roiIndex,imageIndex)    = obj.roiList(roiIndex).getVar(obj.dicomStack(:,:,imageIndex));
					obj.roiSemValues(roiIndex,imageIndex)    = obj.roiList(roiIndex).getSem(obj.dicomStack(:,:,imageIndex));
				end
			end
			
			for roiIndex = 1:obj.numOfRoi
				% Compute T2 values from images 1 & 2
				obj.roiT2Values(roiIndex) = (obj.dicomTeValues(2)-obj.dicomTeValues(1))/...
					                           log(obj.roiMeanValues(roiIndex,1)/obj.roiMeanValues(roiIndex,2));
			end
		end
		
		%---------------------------------------------------------------------------------------------------------- saveRoiStatsToTxt
		function saveRoiStatsToTxt(obj,fullFileName)
			% Prepare a text file where to store ROI stats
			fileId = fopen(fullFileName,'w');
			
			% Build a blank line and a line separator for later usage
			lineSeparator = sprintf('----------------------------------------------------------------------------\n');
			blankLine = sprintf('\n');
			
			% Write application info header
			appInfo = sprintf('%s : %s\n',...
				'Software Editor ',obj.appEditor,...
				'Application Name',obj.appName,...
				'Software Version',obj.appVersion);
			
			fprintf(fileId,appInfo);
			fprintf(fileId,blankLine);
			fprintf(fileId,blankLine);
			
			% Write ROI parameters entered by the user
			fprintf(fileId,'ROI User Parameters\n');
			fprintf(fileId,lineSeparator);
			fprintf(fileId,'Number of ROI     : %u\n',obj.numOfRoi);
			fprintf(fileId,'ROI diameter (px) : %u\n',obj.roiDiameter);
			fprintf(fileId,lineSeparator);
			fprintf(fileId,blankLine);
			fprintf(fileId,blankLine);
			
			% Prepare info format specs for later usage with fprintf function
			roiStatsFS = '%u\t%u\t%u\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\n';
			
			for imageIndex = 1:obj.dicomStackLength				
				% Create a new block of info which identifies each image and give some basic stats data
				cellFileName = obj.dicomFileNames(imageIndex);
				fprintf(fileId,'Image number   : %u\n',imageIndex);
				fprintf(fileId,'DICOM file     : %s\n',cellFileName{1});
				fprintf(fileId,'Min intensity  : %.0f\n',obj.imageMinValues(imageIndex));
				fprintf(fileId,'Max intensity  : %.0f\n',obj.imageMaxValues(imageIndex));
				fprintf(fileId,'Mean intensity : %.0f\n',obj.imageMeanValues(imageIndex));
				fprintf(fileId,lineSeparator);
				
				% Write ROIs stats columns header
				fprintf(fileId,'ROI#\tMin\tMax\tMean\tMedian\tStd\tVar\tSem\n');
				fprintf(fileId,lineSeparator);
				
				for roiIndex = 1:obj.numOfRoi
					% Store ROIs stats values in the Stats text file
					roiData = [...
						roiIndex obj.roiMinValues(roiIndex,imageIndex)...
						obj.roiMaxValues(roiIndex,imageIndex)...
						obj.roiMeanValues(roiIndex,imageIndex)...
						obj.roiMedianValues(roiIndex,imageIndex)...
						obj.roiStdValues(roiIndex,imageIndex)...
						obj.roiVarValues(roiIndex,imageIndex)...
						obj.roiSemValues(roiIndex,imageIndex)];
					fprintf(fileId,roiStatsFS,roiData);
				end
				
				% Add separator and blank lines for more clarity
				fprintf(fileId,lineSeparator);
				fprintf(fileId,blankLine);
				fprintf(fileId,blankLine);
			end
			
			% Prepare T2 values format specs for later usage with fprintf function
			roiT2ValuesFS = '%u\t%.2f\n';
			
			% Write T2 values header 
			fprintf(fileId,'T2 values computed in ROI from images 1 & 2\n');
			fprintf(fileId,'Image 1 : TE = %.2f (ms)\n',obj.dicomTeValues(1));
			fprintf(fileId,'Image 2 : TE = %.2f (ms)\n',obj.dicomTeValues(2));
			fprintf(fileId,lineSeparator);
			fprintf(fileId,'ROI#\tT2 (ms)\n');
			fprintf(fileId,lineSeparator);
			
			% Write T2 values computed in ROIs from mages 1 & 2
			for roiIndex = 1:obj.numOfRoi
				fprintf(fileId,roiT2ValuesFS,[roiIndex obj.roiT2Values(roiIndex)]);
			end
			
			% Add separator and blank lines for more clarity
			fprintf(fileId,lineSeparator);
			fprintf(fileId,blankLine);
			fprintf(fileId,blankLine);
			
			% Close the Stats text file
			fclose(fileId);
		end
		
		%---------------------------------------------------------------------------------------------------------- saveRoiStatsToCsv
		function saveRoiStatsToCsv(obj,fullFileName)
			% Prepare a CVS file where to store ROI stats
			fileId = fopen(fullFileName,'w');
			
			% Write application info header		
			fprintf(fileId,'Software Editor;%s\n',obj.appEditor);
			fprintf(fileId,'Application Name;%s\n',obj.appName);
			fprintf(fileId,'Software Version;%s\n',obj.appVersion);
			
			% Add a blank row
			fprintf(fileId,'\n');
			
			% Write ROI parameters entered by the user
			fprintf(fileId,'ROI User Parameters\n');
			fprintf(fileId,'Number of ROI;%u\n',obj.numOfRoi);
			fprintf(fileId,'ROI diameter (px);%u\n',obj.roiDiameter);
			
			% Add a blank row for more clarity
			fprintf(fileId,'\n');
			
			% Prepare info format specs for later usage with fprintf function
			roiStatsFS = '%u;%u;%u;%.0f;%.0f;%.0f;%.0f;%.0f\n';
			
			for imageIndex = 1:obj.dicomStackLength				
				% Create a new block of info which identifies each image and give some basic stats data
				cellFileName = obj.dicomFileNames(imageIndex);
				fprintf(fileId,'Image number;%u\n',imageIndex);
				fprintf(fileId,'DICOM file;%s\n',cellFileName{1});
				fprintf(fileId,'Min intensity;%.0f\n',obj.imageMinValues(imageIndex));
				fprintf(fileId,'Max intensity;%.0f\n',obj.imageMaxValues(imageIndex));
				fprintf(fileId,'Mean intensity;%.0f\n',obj.imageMeanValues(imageIndex));
				
				% Add a blank row for more clarity
				fprintf(fileId,'\n');
				
				% Write ROIs stats columns header
				fprintf(fileId,'ROI#;Min;Max;Mean;Median;Std;Var;Sem\n');
				
				for roiIndex = 1:obj.numOfRoi
					% Store ROIs stats values in the Stats text file
					roiData = [...
						roiIndex...
						obj.roiMinValues(roiIndex,imageIndex)...
						obj.roiMaxValues(roiIndex,imageIndex)...
						obj.roiMeanValues(roiIndex,imageIndex)...
						obj.roiMedianValues(roiIndex,imageIndex)...
						obj.roiStdValues(roiIndex,imageIndex)...
						obj.roiVarValues(roiIndex,imageIndex)...
						obj.roiSemValues(roiIndex,imageIndex)];
					fprintf(fileId,roiStatsFS,roiData);
				end
				
				% Add 2 blank rows for more clarity
				fprintf(fileId,'\n');
				fprintf(fileId,'\n');
			end
			
			% Prepare T2 values format specs for later usage with fprintf function
			roiT2ValuesFS = '%u;%.2f\n';
			
			% Write T2 values header 
			fprintf(fileId,'T2 values computed in ROI from images 1 & 2\n');
			fprintf(fileId,'Image 1 : TE (ms) = ;%.2f\n',obj.dicomTeValues(1));
			fprintf(fileId,'Image 2 : TE (ms) = ;%.2f\n',obj.dicomTeValues(2));
			fprintf(fileId,'\n');
			fprintf(fileId,'ROI#;T2 (ms)\n');
			
			% Write T2 values computed in ROIs from mages 1 & 2
			for roiIndex = 1:obj.numOfRoi
				fprintf(fileId,roiT2ValuesFS,[roiIndex obj.roiT2Values(roiIndex)]);
			end
			
			% Add a blank row
			fprintf(fileId,'\n');

			% Close the Stats CSV file
			fclose(fileId);
		end
		
	end % Public Methods

	methods (Static)
		
		%--------------------------------------------------------------------------------------------------------- uiRelativePosition
		function [ret] = uiRelativePosition(parent,x,y,w,h)
			parentPos = get(parent,'Position');
			ret = [x parentPos(4)-y-h w h];
		end
		
	end % Static Methods
	
end % Class Definition