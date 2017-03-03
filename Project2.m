clear all
%% Import data from text file.
% Initialize variables.
Directory = 'C:\Users\SAA\Desktop\DataIncubator\Geolife Trajectories 1.3\Geolife Trajectories 1.3\Data\';
ContntG=dir(Directory);
plotB = 0;
hold on

for indexFile = 3:size(ContntG,1)  
    directory = [Directory,ContntG(indexFile).name,'\Trajectory\'];
    Contnt=dir(directory);
    GX = [];
    GY = [];
    indexFile
    for ii=3:size(Contnt,1)
            delimiter = ',';
        startRow = 7;
        % Format string for each line of text:
        formatSpec = '%f%f%*s%f%f%s%s%*s%[^\n\r]';
        % Open the text file.
        fileID = fopen([directory,Contnt(ii).name],'r');

        % Read columns of data according to format string.
        dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
        % Close the text file.
        fclose(fileID);
        % Allocate imported array to column variable names
        x = dataArray{:, 1};
        y = dataArray{:, 2};
        z = dataArray{:, 3};
        t = dataArray{:, 4};
        day = dataArray{:, 5};
        time = dataArray{:, 6};

        % Clear temporary variables
        clearvars filename delimiter startRow formatSpec fileID dataArray ans;


        %% preprocessing
        % Removing the data outside Beijing
        rem = y>116.27 & y<116.5 & x>39.83 & x<39.99;
        if max(rem)==0
           continue
        end
        x=x(rem);
        y=y(rem);
        z=z(rem);
        t=t(rem);
        day=day(rem);
        time=time(rem);

        %% Processing the data points to assign each to a region based on location and time of the day
        Thresh = abs(min(max(x)-min(x),max(y)-min(y))/10); %Distance threshold for creating regions
        regionsI=zeros(length(x),1); % mapping points to regions based on their distance to bsae points and time of the day
        BaseIndex = sparse(length(x),1); % Knowing if the point is a base index

        iReg=1;
        regionsI(1)=iReg; 
        iBase =1; % Base index number (the index of point that is the center of a region)
        BaseIndex(1)=1; 

        for i=2:length(x)
            if sqrt((x(i)-x(iBase))^2+(y(i)-y(iBase))^2)<=Thresh
                regionsI(i) = iReg;
            else
                iReg=iReg+1;
                regionsI(i) = iReg;
                iBase = i;
                BaseIndex(i)=1;
            end
        end

        if plotB == 1
            text(y(1:100:end),x(1:100:end)+.001,num2str(regionsI(1:100:end)))
        end

        [Ibasei,Jbasei,Vbasei]=find(BaseIndex);
        maxNum_points_region = max(diff(Ibasei));
        regionsT = zeros(length(Ibasei),3); % Matrix containing the start time and end time of being in region and the total time being in region
        for i=1:length(Ibasei)-1
            regionsT(i,1)=min(t(Ibasei(i):Ibasei(i+1)-1));
            regionsT(i,2)=max(t(Ibasei(i):Ibasei(i+1)-1));
            regionsT(i,3)=regionsT(i,2)-regionsT(i,1);
        end
        regionsT(length(Ibasei),1)=min(t(Ibasei(end):end));
        regionsT(length(Ibasei),2)=max(t(Ibasei(end):end));
        regionsT(length(Ibasei),3)=regionsT(length(Ibasei),2)-regionsT(length(Ibasei),1);

        %% Plotting the points on the map (marker size shows the duration of time of being in each region)
        if plotB ==1
            hold on
            for i=1:length(x)
                plot(y(i),x(i),'.r','MarkerSize',100*sqrt(regionsT(regionsI(i),3)))
            end
            title('Location points with marker sizes representing the duration of presence in each region')
            plot_google_map
            hold off
        end

        %% Identifying the two regions with longer duration of staying
        [Vs,Is] = sort(regionsT(:,3));
        if length(Is)>1
            GX=[GX;x(Ibasei(Is(end:-1:end-1)))];
            GY=[GY;y(Ibasei(Is(end:-1:end-1)))];
        else
            GX=[GX;x(1)];
            GY=[GY;y(1)];
        end
        if plotB ==1
            figure
            hold on
            i=1;
            for is = Is(end:-1:end-1)'
                color = ['.r';'.b'];
                text = ['Home';'Office'];
                if is~=length(Is)
                    plot(y(Ibasei(is):Ibasei(is+1)-1),x(Ibasei(is):Ibasei(is+1)-1),color(i,:),'MarkerSize',100*regionsT(is,3))
                else
                    plot(y(Ibasei(is):end),x(Ibasei(is):end),color(i,:),'MarkerSize',100*regionsT(is,3))
                end
                text(y(Ibasei(is)),x(Ibasei(is))+.001,text(is,:))
                i=i+1;
            end
            title('Two regions with the longest staying duration')
            plot_google_map
            hold off
        end
    end

    
    for i=1:length(GX)
        plot(GY(i),GX(i),'MarkerSize',12)
    end

end
    title('Location points of highest duration of presence')
    plot_google_map