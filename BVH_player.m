function BVH_player(varargin)
% v 1.0
% 2016/09/24
% Author: Phat Luu. tpluu2207@gmail.com
% Brain Machine Interface Lab
% University of Houston, TX, USA.
% ===================================================================
% Add Paths and external libs
uhlib = '..\uhlib';
addpath(genpath(uhlib));
% Import Java
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.lang.*;
% DEFINES
handles.filekeyword = 'MODULE';
global gvar;
gvar=def_gvar;
%====STEP 1: FRAME====
handles.iconlist=getmatlabicons;
% Create a new figure
[handles.figure, handles.jstatusbarhdl,handles.jwaitbarhdl]=uh_uiframe('figname',mfilename,...
    'units','norm','position',[0.1 0.1 0.8 0.8],...
    'toolbar','figure',...
    'statusbar',1, 'icon',handles.iconlist.uh,'logo','none',...
    'logopos',[0.89,0.79,0.2,0.2]);
% Frame-Title
% handles.text_title = uicontrol('Style','text', 'Units','norm', 'Position',[.2,.8,.6,.17],...
%     'FontSize',20, 'Background','w', 'Foreground','r',...
%     'String','BVH PLAYER');
%==============================UI CONTROL=================================
% Set Look and Feel
uisetlookandfeel('window');
% Warning off
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
warning('off','MATLAB:uigridcontainer:MigratingFunction');
warning('off','MATLAB:uitree:MigratingFunction');
warning('off','MATLAB:uitreenode:DeprecatedFunction');
% combobox and List files
uistring={{''},icontext(handles.iconlist.action.updir,''),...
    '','',...
    };
w=0.4; h=0.35;
[container_filelist,handles.combobox_currdir, handles.pushbutton_updir,...
    handles.jlistbox_filenameinput,~,...
    ]=uigridcomp({'combobox','pushbutton',...
    'list','label',...
    },...
    'uistring',uistring,...
    'position',[gvar.margin.l 0.625 w h],...
    'gridsize',[2 2],'gridmargin',5,'hweight',[8.5 1.5],'vweight',[1.5 7.5]);
% Player
handles.player = axes;
handles.signalax = axes;
% Player control button
uistring={icontext(handles.iconlist.action.play,'Start'),...
    '',...
    '',...
    };
[container_controller,...
    handles.pushbutton_play,handles.slider_frame,...
    handles.edit_frame]=uigridcomp({'pushbutton','slider','edit'},...
    'uistring',uistring,...
    'gridsize',[1 3],'gridmargin',10,...
    'hweight',[1 6.5 1.5],'vweight',1);
% Gait event information
uistring={icontext(handles.iconlist.walk,'GC Event:'),...
    '','','','','',...    
    {'LW1','LW2','LW3','LW4','LW5','LW6','RD','RA','SA','SD'},...
    icontext(handles.iconlist.action.import,'Insert'),...
    icontext(handles.iconlist.action.update,'Update')};
[container_gcevent,...
    ~,handles.edit_gcevent1,handles.edit_gcevent2,handles.edit_gcevent3,...    
    handles.edit_gcevent4,handles.edit_gcevent5,...
    handles.combobox_gclabel,...
    handles.pushbutton_insert,handles.pushbutton_update]=uigridcomp({'label',...
    'edit','edit','edit','edit','edit',...
    'combobox',...
    'pushbutton','pushbutton'},...
    'uistring',uistring,...
    'gridsize',[1 9],'gridmargin',8,...
    'hweight',[1 1 1 1 1 1 1 1.5 1.5],'vweight',1);

% List box to display current GC data;
uistring={'',...
    };
[container_matdata,handles.jlistbox_matdata,...    
    ]=uigridcomp({'list',...
    },...
    'uistring',uistring,...    
    'gridsize',[1 1],'gridmargin',5);
% Save matdata
uistring={icontext(handles.iconlist.action.delete,'Del'),'',...
    icontext(handles.iconlist.action.save,'Save'),...
    };
[container_save,handles.pushbutton_del,~,handles.pushbutton_save,...    
    ]=uigridcomp({'pushbutton','label',...
    'pushbutton'},...
    'uistring',uistring,...    
    'gridsize',[1 3],'gridmargin',5,'hweight',[2 6 2]);
% Option to select the landed leg before transition (LW-SA, SA-LW, LW-SD, SD-LW)
for i = 1 : 4
    handles.radio_transleg(i) = uh_uiradiobutton('title','LW-SA',...
        'string',{icontext(handles.iconlist.leftfoot,'LEFT'),icontext(handles.iconlist.rightfoot,'RIGHT')},...
        'fontsize',8);
    groupobj(i) = handles.radio_transleg(i).group;
end
uipanel_radio = uipanellist('title','Transition Foot',...
                'objects',groupobj,...
                'itemwidth',0.2,'itemheight',0.9,'align','horizontal',...
                'marginleft',gvar.margin.gap*4,...
                'gap',[gvar.margin.gap*4 0]); 
% TIMER OBJECT
handles.mytimer = timer('ExecutionMode','fixedSpacing',...
    'Period',0.001,...
    'BusyMode','queue',...
    'TimerFcn',{@timerFcn_Callback,handles},...
    'StopFcn',{@timerStopFcn_Callback,handles});
% Alignment
uialign(handles.player,container_filelist,'align','east','scale',[1.3 1.25],'gap',[0.06 -0.17]);
uialign(handles.signalax,container_filelist,'align','east','scale',[1.3 0.4],'gap',[0.06 0.0]);
uialign(container_controller,handles.player,'align','southwest','scale',[1 0.12],'gap',[0 -0.01]);
uialign(container_gcevent,container_controller,'align','southwest','scale',[1 1],'gap',[0 -0.01]);
uialign(container_matdata,container_filelist,'align','southwest','scale',[0.85 1.4],'gap',[0 -0.01]);
uialign(container_save,container_matdata,'align','southwest','scale',[1 0.1],'gap',[0 -0.01]);
uialign(uipanel_radio,container_gcevent,'align','southwest','scale',[1 3],'gap',[0 -0.01]);
% Initialize
uisetjcombolist(handles.combobox_currdir,{cd});
uijlist_setfiles(handles.jlistbox_filenameinput,cd);
handles.currframe = 1 ; % to store current frame of timer object
set(handles.combobox_gclabel,'SelectedIndex',0,'MaximumRowCount',10);
set(handles.slider_frame,'min',0,'max',10000);
handles.keyholder = '';
% Setappdata
setappdata(handles.figure,'handles',handles);
% set(handles.combobox_gclabel,'background',javax.swing.plaf.ColorUIResource([256 0 0]))
%====STEP 4: DEFINE CALLBACK====
% Combobox
set(handles.combobox_currdir,'ActionPerformedCallback',{@combobox_currdir_Callback,handles});
% Keyboard control
set(handles.figure,'WindowKeyPressFcn',{@KeyboardThread_Callback,handles});
set(handles.jlistbox_filenameinput,'KeyPressedCallback',{@KeyboardThread_Callback,handles});
set(handles.jlistbox_matdata,'KeyPressedCallback',{@KeyboardThread_Callback,handles});
% Mouse control
set(handles.jlistbox_filenameinput,'MousePressedCallback',{@jlistbox_filenameinput_Mouse_Callback,handles});
% listbox
set(handles.jlistbox_matdata,'MousePressedCallback',{@jlistbox_matdata_Callback,handles});
% Pushbutton
set(handles.pushbutton_updir,'Callback',{@pushbutton_updir_Callback,handles});
set(handles.pushbutton_play,'Callback',{@pushbutton_play_Callback,handles});
set(handles.pushbutton_save,'Callback',{@pushbutton_save_Callback,handles});
set(handles.pushbutton_del,'Callback',{@pushbutton_del_Callback,handles});
set(handles.pushbutton_insert,'Callback',{@pushbutton_insert_Callback,handles});
set(handles.pushbutton_update,'Callback',{@pushbutton_update_Callback,handles});
% Slider and edit text
set(handles.edit_frame,'Callback',{@edit_frame_Callback,handles});
set(handles.slider_frame,'Callback',{@slider_frame_Callback,handles});

% CALLBACK
function jlistbox_filenameinput_Mouse_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
eventinf=get(eventdata);
if eventinf.Button==1 && eventinf.ClickCount==2 %double left click
    handles = jlistbox_filenameinput_load(hObject,handles);
elseif eventinf.Button==3       %Right Click
    handles.jmenu.show(hObject,eventinf.X,eventinf.Y);
    handles.itempos.x=eventinf.X;
    handles.itempos.y=eventinf.Y;
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function handles = jlistbox_filenameinput_load(hObject,handles);
handles=getappdata(handles.figure,'handles');
[stacktrace, ~]=dbstack;
thisFuncName=stacktrace(1).name;
%=====
val=get(hObject,'SelectedValue');
mark1=strfind(val,'>');mark1=mark1(end-1);
mark2=strfind(val,'<');mark2=mark2(end);
filename=val(mark1+1:mark2-1);
[~,selname,ext]=fileparts(filename);
currdir=get(handles.combobox_currdir,'selecteditem');
if isempty(ext)     %folder selection
    if strcmpi(currdir(end),'\')
        newdir=strcat(currdir,selname);
    else
        newdir=strcat(currdir,'\',selname);
    end
    uijlist_setfiles(handles.jlistbox_filenameinput,newdir,'type',{'.all'});
    handles.combobox_currdir.insertItemAt(newdir,0);
    set(handles.combobox_currdir,'selectedindex',0);
elseif strcmpi(ext,'.m')
    edit(fullfile(currdir,filename));
elseif strcmpi(ext,'.mat')
    fprintf('Load: %s.\n',filename);
    myfile = class_FileIO('filename',filename,'filedir',currdir);
    myfile.loadtows;
    handles.kinfile = myfile;
    kin = evalin('base','kin');            
    uisetjlistbox(handles.jlistbox_matdata,gcinfo2list(kin.gc.index,kin.gc.label));
    for i = 1 : length(kin.gc.transleg)
        if strcmpi(kin.gc.transleg(i),'l'), idx = 1;
        else idx = 2; end
        set(handles.radio_transleg(i).group,'selectedobject',handles.radio_transleg(i).items{idx});
    end
    set(handles.jlistbox_matdata,'SelectedIndex',0);
    jlistbox_matdata_Callback(handles.jlistbox_matdata,[],handles);
elseif strcmpi(ext,'.bvh')
    [handles.skeleton,handles.time] = loadbvh(fullfile(currdir,filename));
    set(handles.slider_frame,'min',0,'max',length(handles.time),...
        'sliderstep',[1 10]./length(handles.time));
    showframe(1,handles);
    fprintf('bvh file is loaded.\n');
else
end
fprintf('DONE...%s.\n',thisFuncName);
% Setappdata
setappdata(handles.figure,'handles',handles);

function slider_frame_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
sl_val = round(get(hObject,'value'));
set(handles.edit_frame,'string',num2str(sl_val));
gcinfo = gclist2info(uigetjlistbox(handles.jlistbox_matdata,'select','all'));
gcid = find(gcinfo.index(:,1) <= sl_val,1,'last');
if isempty(gcid) setval = 0;
elseif gcid >= size(gcinfo.index,1), setval = size(gcinfo.index,1)-1;
else, setval = gcid-1; 
end
set(handles.jlistbox_matdata,'SelectedIndex',setval);
isfield(handles,'skeleton')
if isfield(handles,'skeleton')    
    showframe(sl_val,handles);
end
if uh_isvarexist('kin')
    axes(handles.signalax);
    cla; hold on;
    if sl_val < 50,  tsignal = 1 : 50;    
    else tsignal = sl_val-50 : sl_val+50; % Get 100 frames around current frame
    end    
    kin = evalin('base','kin');
    AccLeftFoot = kin.Data.sensorAcceleration.LeftFoot(:,3);
    AccRightFoot = kin.Data.sensorAcceleration.RightFoot(:,3);
    OriLeftFoot = kin.Data.sensorOrientationEuler.LeftFoot(:,2);
    OriRightFoot = kin.Data.sensorOrientationEuler.RightFoot(:,2);
    tsignal(find(tsignal >= length(AccLeftFoot))) = [];
            
    plot(tsignal,3*AccRightFoot(tsignal),'r');
    plot(tsignal,3*AccLeftFoot(tsignal),'k');
    plot(tsignal,OriLeftFoot(tsignal),'r.');
    plot(tsignal,OriRightFoot(tsignal),'k.');
    line('xdata',sl_val.*[1 1],'ydata',get(gca,'ylim'),'color','r');
    set(gca,'xlim',[tsignal(1) tsignal(end)],'ylim',[-100 50]);    
    % Anno
    class_text('location','north','string','Current Frame','show',1);
    limx = get(gca,'xlim');limy = get(gca,'ylim');
    hdl = class_line('xdata',[limx(1) limx(1)+3],'ydata',(limy(1)-40).*[1 1],'linecolor','r');
    set(hdl.textobj,'position',hdl.endpoint.position,'string','Acc-RightFoot',...
        'verticalalignment','middle','horizontalalignment','left','fontsize',8);
    hdl.drawshape;
    hdl = class_line('xdata',[limx(1) limx(1)+3],'ydata',(limy(1)-70).*[1 1],'linecolor','k');
    set(hdl.textobj,'position',hdl.endpoint.position,'string','Acc-LeftFoot',...
        'verticalalignment','middle','horizontalalignment','left','fontsize',8);
    hdl.drawshape;
    hdl = class_line('xdata',[limx(1)+20 limx(1)+23],'ydata',(limy(1)-40).*[1 1],'linecolor','r','linestyle',':');
    set(hdl.textobj,'position',hdl.endpoint.position,'string','Orient-RightFoot',...
        'verticalalignment','middle','horizontalalignment','left','fontsize',8);
    hdl.drawshape;
    hdl = class_line('xdata',[limx(1)+20 limx(1)+23],'ydata',(limy(1)-70).*[1 1],'linecolor','k','linestyle',':');
    set(hdl.textobj,'position',hdl.endpoint.position,'string','Orient-LeftFoot',...
        'verticalalignment','middle','horizontalalignment','left','fontsize',8);
    hdl.drawshape;
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function edit_frame_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
ed_str = get(hObject,'string');
set(handles.slider_frame,'value',str2num(ed_str));
slider_frame_Callback(handles.slider_frame,[],handles)
% Setappdata
setappdata(handles.figure,'handles',handles);

function jlistbox_matdata_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
thisstr = uigetjlistbox(hObject);
gcinfo = gclist2info(thisstr);
updateuigcevent(gcinfo,handles);
set(handles.edit_frame,'string',num2str(gcinfo.index(1)));
set(handles.slider_frame,'value',gcinfo.index(1));
slider_frame_Callback(handles.slider_frame,[],handles);
setappdata(handles.figure,'handles',handles);

function updateuigcevent(gcinfo,handles)
handles=getappdata(handles.figure,'handles');
if strcmpi(gcinfo.label,'LW1'), idx = 0;
elseif strcmpi(gcinfo.label,'LW2'), idx = 1;
elseif strcmpi(gcinfo.label,'LW3'), idx = 2;
elseif strcmpi(gcinfo.label,'LW4'), idx = 3;
elseif strcmpi(gcinfo.label,'LW5'), idx = 4;
elseif strcmpi(gcinfo.label,'LW6'), idx = 5;
elseif strcmpi(gcinfo.label,'RD'), idx = 6;
elseif strcmpi(gcinfo.label,'RA'), idx = 7;
elseif strcmpi(gcinfo.label,'SA'), idx = 8;
elseif strcmpi(gcinfo.label,'SD'), idx = 9;
else idx = 0;
end
set(handles.edit_gcevent1,'string',num2str(gcinfo.index(1)));
set(handles.edit_gcevent2,'string',num2str(gcinfo.index(2)));
set(handles.edit_gcevent3,'string',num2str(gcinfo.index(3)));
set(handles.edit_gcevent4,'string',num2str(gcinfo.index(4)));
set(handles.edit_gcevent5,'string',num2str(gcinfo.index(5)));
set(handles.combobox_gclabel,'selectedindex',idx);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_play_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
thisstr = get(hObject,'string');
if strcmpi(thisstr,icontext(handles.iconlist.action.play,'start'))
    set(hObject,'string',icontext(handles.iconlist.status.stop,'stop'));
    handles.currframe = get(handles.slider_frame,'value');
    start(handles.mytimer);
else    
    stop(handles.mytimer); % Perform a list of task to quit the program
    set(hObject,'string',icontext(handles.iconlist.action.play,'start'));
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_insert_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
gclabel = get(handles.combobox_gclabel,'selecteditem');
gcindex = get(handles.jlistbox_matdata,'SelectedIndex') + 1;

currlist = uigetjlistbox(handles.jlistbox_matdata,'select','all');
gcinfo = gclist2info(currlist);
currgcdata = gcinfo.index;
currgclabel = gcinfo.label;
insertval = [str2num(get(handles.edit_gcevent1,'string')),...
    str2num(get(handles.edit_gcevent2,'string')),...
    str2num(get(handles.edit_gcevent3,'string')),...
    str2num(get(handles.edit_gcevent4,'string')),...
    str2num(get(handles.edit_gcevent5,'string'))];
newgcdata = [currgcdata(1:gcindex,:); insertval; currgcdata(gcindex+1:end,:)];
newgclabel = transpose({currgclabel{1:gcindex}, gclabel, currgclabel{gcindex+1:end}});
% Update GUI;
uisetjlistbox(handles.jlistbox_matdata,gcinfo2list(newgcdata,newgclabel));
set(handles.jlistbox_matdata,'selectedIndex',gcindex);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_update_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
gclabel = get(handles.combobox_gclabel,'selecteditem');
gcindex = get(handles.jlistbox_matdata,'SelectedIndex') + 1;
currgclist = uigetjlistbox(handles.jlistbox_matdata,'select','all');
gcinfo = gclist2info(currgclist);
event = [str2num(get(handles.edit_gcevent1,'string')),...
    str2num(get(handles.edit_gcevent2,'string')),...
    str2num(get(handles.edit_gcevent3,'string')),...
    str2num(get(handles.edit_gcevent4,'string')),...
    str2num(get(handles.edit_gcevent5,'string'))];
newgcdata = gcinfo.index; newgcdata(gcindex,:) = event;
newgclabel = gcinfo.label; newgclabel{gcindex} = gclabel;
% Update GUI;
uisetjlistbox(handles.jlistbox_matdata,gcinfo2list(newgcdata,newgclabel));
set(handles.jlistbox_matdata,'selectedIndex',gcindex-1);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_del_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
gcindex = get(handles.jlistbox_matdata,'SelectedIndex') + 1;
currgclist = uigetjlistbox(handles.jlistbox_matdata,'select','all');
gcinfo = gclist2info(currgclist);
gcinfo.index(gcindex,:) = [];
gcinfo.label(gcindex) = [];
uisetjlistbox(handles.jlistbox_matdata,gcinfo2list(gcinfo.index,gcinfo.label));
set(handles.jlistbox_matdata,'selectedIndex',gcindex-1);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_save_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
[stacktrace, ~]=dbstack;
thisFuncName=stacktrace(1).name;
for i = 1 : length(handles.radio_transleg)
if get(handles.radio_transleg(i).group,'selectedobject')==handles.radio_transleg(i).items{1}
    transleg(i)=cellstr('L'); else transleg(i)=cellstr('R'); end;
end
% Convert back to mat data from list data;
kin = evalin('base','kin');
kin.gc.transleg = transleg;
gcinfo = gclist2info(uigetjlistbox(handles.jlistbox_matdata,'select','all'));
kin.gc.index = gcinfo.index;
kin.gc.label = gcinfo.label;
kin.gc.time = (gcinfo.index-1)./30;
% kin.gc.index = kin.gc.event.index; % To modify kin format.
% kin.gc.time = kin.gc.event.time;
% kin.gc = rmfield(kin.gc,'event');
% kin.gc.transleg = transleg;
fprintf('Saving...%s\n',handles.kinfile.filename);
handles.kinfile.savevars(kin);
fprintf('DONE...%s\n',thisFuncName);
% Setappdata
setappdata(handles.figure,'handles',handles);

function showframe(ff,handles)
axes(handles.player); 
cla;hold on;
skeleton = handles.skeleton;
for nn = 1:length(skeleton)
    plot3(-skeleton(nn).Dxyz(1,ff),-skeleton(nn).Dxyz(3,ff),skeleton(nn).Dxyz(2,ff),'.','markersize',20)
    parent = skeleton(nn).parent;
    if parent > 0
        plot3([-skeleton(parent).Dxyz(1,ff) -skeleton(nn).Dxyz(1,ff)],...
            [-skeleton(parent).Dxyz(3,ff) -skeleton(nn).Dxyz(3,ff)],...
            [skeleton(parent).Dxyz(2,ff) skeleton(nn).Dxyz(2,ff)])
    end    
end
view(-45, -30)
axis equal off
% ylabel('y axis');
drawnow

function liststr = gcinfo2list(matdata,label)
for i = 1 : size(matdata,1)
    strcmd = 'temp = sprintf(''';
    for j = 1 : size(matdata,2)        
        if j == size(matdata,2)
            strcmd = [strcmd '%04d    -    '','];
        else
            strcmd = [strcmd '%04d    '];
        end
    end 
    for j = 1 : size(matdata,2)
        if j == size(matdata,2)
            strcmd = [strcmd 'matdata(i,' num2str(j) '));'];
        else
            strcmd = [strcmd 'matdata(i,' num2str(j) '),'];
        end
    end
    eval(strcmd);
    matlist{i,:} = [sprintf('GC:%02d    -    ',i) temp];
end
liststr = strcat(matlist,label);

function gcinfo = gclist2info(celldata)
for i = 1 : length(celldata)
    thisline = celldata{i};
    dashpos = strfind(thisline,'-');
    temp = thisline(dashpos(end)+1:end);
    gclabel{i,:} = temp(~isspace(temp));
    gcstr(i,:) = thisline(dashpos(1)+1 : dashpos(2)-1);
end
gcidx = str2num(gcstr);
gcinfo.label = gclabel;
gcinfo.index = gcidx;

function pushbutton_updir_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
% dirlist=get(handles.popupmenu_currdir,'string');
% currdir=dirlist{get(handles.popupmenu_currdir,'value')};
currdir=get(handles.combobox_currdir,'selecteditem');
if strfind(currdir,'.\')
    slash=strfind(currdir,'\');
    updir=currdir(1:slash(end));
    if strcmpi(currdir,'.\')
        [updir,~,~]=fileparts(cd);
    end
else
    [updir,~,~]=fileparts(currdir);
end
handles.combobox_currdir.insertItemAt(updir,0);
set(handles.combobox_currdir,'selectedindex',0);
% uijlist_setfiles(handles.jlistbox_filenameinput,updir,'type',{'.all'});
setappdata(handles.figure,'handles',handles);

function combobox_currdir_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
newdir=get(hObject,'selecteditem');
if strcmpi(newdir,'.\');
    newdir=cd;
end
if ~strcmpi(newdir,hObject.getItemAt(0))
    hObject.insertItemAt(newdir,0);
end
uijlist_setfiles(handles.jlistbox_filenameinput,newdir,'type',{'.all'});
setappdata(handles.figure,'handles',handles);

function timerFcn_Callback(hObject,event,handles)
handles=getappdata(handles.figure,'handles');
ff = handles.currframe;
set(handles.slider_frame,'value',ff);
set(handles.edit_frame,'string',num2str(ff));
showframe(ff,handles);
handles.currframe = handles.currframe + 2;
if handles.currframe > length(handles.time)
    handles.currframe = length(handles.time);
end
slider_frame_Callback(handles.slider_frame,[],handles);
% Setappdata
setappdata(handles.figure,'handles',handles);

function timerStopFcn_Callback(hObject,event,handles)
handles=getappdata(handles.figure,'handles');
% Setappdata
setappdata(handles.figure,'handles',handles);

function handles = initialize_gcfile(handles)
handles=getappdata(handles.figure,'handles');
kin = evalin('base','kin');
label = kin.gc.label;
celllist = gcinfo2list(kin.gc.event.index,label);
uisetjlistbox(handles.jlistbox_matdata,celllist);
% Interact with GUI
set(handles.jlistbox_matdata,'SelectedIndex',0);
gcinfo = gclist2info(uigetjlistbox(handles.jlistbox_matdata));
updateuigcevent(gcinfo,handles);
% Setappdata
setappdata(handles.figure,'handles',handles);

function handles=KeyboardThread_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
% -----------
if isprop(eventdata,'Key')
    key = lower(eventdata.Key); % Matlab component; Ctrl: 'control'
else
    key = lower(char(eventdata.getKeyText(eventdata.getKeyCode)));    % Java component;
end
if any([strcmpi(key,'g'),strcmpi(key,'ctrl'),strcmpi(key,'control'),...
        strcmpi(key,'shift'),strcmpi(key,'alt')])
    handles.keyholder = key;
    setappdata(handles.figure,'handles',handles);
    return;
end
% Go to component;
if strcmpi(handles.keyholder,'g')
    if strcmpi(key,'l') % Set focus on function list
        handles.jlistbox_matdata.requestFocus; 
        fprintf('jlistbox_funclist is selected.\n');
    elseif strcmpi(key,'f') % Set focus on mfile list
        handles.jlistbox_filenameinput.requestFocus;
        fprintf('jlistbox_filenameinput is selected.\n');
    elseif strcmpi(key,'c') % Set focus on popupmenu_currdir
        handles.combobox_currdir.requestFocus;
        fprintf('combobox_currdir is selected.\n');    
    end
elseif strcmpi(handles.keyholder,'shift')
    if strcmpi(key,'return') || strcmpi(key,'enter')
        pushbutton_update_Callback(handles.pushbutton_update,[],handles);        
    end
elseif strcmpi(handles.keyholder,'ctrl') || strcmpi(handles.keyholder,'control') && strcmpi(key,'s')
    pushbutton_save_Callback(handles.pushbutton_save,[],handles);
else
    if strcmpi(key,'return') || strcmpi(key,'enter') && hObject == handles.jlistbox_matdata
        pushbutton_insert_Callback(handles.pushbutton_insert,[],handles);        
    elseif strcmpi(key,'return') || strcmpi(key,'enter') && hObject == handles.jlistbox_filenameinput
        handles = jlistbox_filenameinput_load(hObject,handles);
    elseif strcmpi(key,'up') || strcmpi(key,'down') && hObject == handles.jlistbox_matdata
        jlistbox_matdata_Callback(handles.jlistbox_matdata,[],handles);
    elseif strcmpi(key,'left') && hObject == handles.jlistbox_matdata
        set(handles.slider_frame,'value',get(handles.slider_frame,'value')-1);
        slider_frame_Callback(handles.slider_frame,[],handles);
    elseif strcmpi(key,'right') && hObject == handles.jlistbox_matdata
        set(handles.slider_frame,'value',get(handles.slider_frame,'value')+1);
        slider_frame_Callback(handles.slider_frame,[],handles);
    elseif strcmpi(key,'space') && hObject == handles.jlistbox_matdata
        set(handles.slider_frame,'value',get(handles.slider_frame,'value')+4);
        slider_frame_Callback(handles.slider_frame,[],handles);
    elseif strcmpi(key,'a') && hObject == handles.jlistbox_matdata           
        set(handles.edit_gcevent1,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 1
    elseif strcmpi(key,'s') && hObject == handles.jlistbox_matdata
        set(handles.edit_gcevent2,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 2
    elseif strcmpi(key,'d') && hObject == handles.jlistbox_matdata
        set(handles.edit_gcevent3,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 3
    elseif strcmpi(key,'f') && hObject == handles.jlistbox_matdata
        set(handles.edit_gcevent4,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 4
    elseif strcmpi(key,'r') && hObject == handles.jlistbox_matdata
        set(handles.edit_gcevent5,'string',get(handles.edit_frame,'string'));   % Add current frame to gait event 5
    elseif strcmpi(key,'e') && hObject == handles.jlistbox_matdata
        idx = get(handles.combobox_gclabel,'selectedindex');
        if idx == get(handles.combobox_gclabel,'ItemCount')-1, idx = 0;
        else idx = idx + 1; end
        set(handles.combobox_gclabel,'SelectedIndex',idx);
    elseif strcmpi(key,'x') || strcmpi(key,'delete') && hObject == handles.jlistbox_matdata
        pushbutton_del_Callback(handles.pushbutton_del,[],handles);
    elseif strcmpi(key,'f1')
        winopen('.\hotkey.txt');
    end
end
handles.keyholder = ''; % reset keyholder;
setappdata(handles.figure,'handles',handles);
