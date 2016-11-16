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
    'statusbar',1, 'icon',handles.iconlist.uh,'logo',handles.iconlist.logo,...
    'logopos',[0.89,0.79,0.2,0.2]);
% Frame-Title
handles.text_title = uicontrol('Style','text', 'Units','norm', 'Position',[.2,.8,.6,.17],...
    'FontSize',20, 'Background','w', 'Foreground','r',...
    'String','BVH PLAYER');
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
    handles.jlistbox_filelist,~,...
    ]=uigridcomp({'combobox','pushbutton',...
    'list','label',...
    },...
    'uistring',uistring,...
    'position',[gvar.margin.l 0.5 w h],...
    'gridsize',[2 2],'gridmargin',5,'hweight',[8.5 1.5],'vweight',[1.5 7.5]);
%
% Player
handles.player= axes;
% Player control button
uistring={icontext(handles.iconlist.action.play,'Start'),...
    '',...
    '',...
    icontext(handles.iconlist.action.import,'Add')};
[container_controller,...
    handles.pushbutton_play,handles.slider_frame,...
    handles.edit_frame, handles.pushbutton_insert]=uigridcomp({'pushbutton','slider','edit','pushbutton'},...
    'uistring',uistring,...
    'gridsize',[1 4],'gridmargin',10,...
    'hweight',[1 6 1.5 1.5],'vweight',1);

% List box to display current GC data;
uistring={'',...
    };
[container_matdata,handles.listbox_matdata,...    
    ]=uigridcomp({'mlist',...
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
% TIMER OBJECT
handles.mytimer = timer('ExecutionMode','fixedSpacing',...
    'Period',0.001,...
    'BusyMode','queue',...
    'TimerFcn',{@timerFcn_Callback,handles},...
    'StopFcn',{@timerStopFcn_Callback,handles});
% Alignment
uialign(handles.player,container_filelist,'align','east','scale',[1.3 1.5],'gap',[0.06 0]);
uialign(container_controller,handles.player,'align','southwest','scale',[1 0.1],'gap',[0 -0.05]);
uialign(container_matdata,container_filelist,'align','southwest','scale',[0.85 1],'gap',[0 -0.02]);
uialign(container_save,container_matdata,'align','southwest','scale',[1 0.2],'gap',[0 -0.01]);
% Initialize
uisetjcombolist(handles.combobox_currdir,{cd});
uijlist_setfiles(handles.jlistbox_filelist,cd);
handles.currframe = 1 ; % to store current frame of timer object

% Setappdata
setappdata(handles.figure,'handles',handles);
%====STEP 4: DEFINE CALLBACK====
% Combobox
set(handles.combobox_currdir,'ActionPerformedCallback',{@combobox_currdir_Callback,handles});
% J listbox
set(handles.jlistbox_filelist,'KeyPressedCallback',{@KeyboardThread_Callback,handles});
set(handles.jlistbox_filelist,'MousePressedCallback',{@jlistbox_filenameinput_Mouse_Callback,handles});
% Pushbutton
set(handles.pushbutton_updir,'Callback',{@pushbutton_updir_Callback,handles});
set(handles.pushbutton_play,'Callback',{@pushbutton_play_Callback,handles});
set(handles.pushbutton_save,'Callback',{@pushbutton_save_Callback,handles});
set(handles.pushbutton_del,'Callback',{@pushbutton_del_Callback,handles});
set(handles.pushbutton_insert,'Callback',{@pushbutton_insert_Callback,handles});
% Slider and edit text
set(handles.edit_frame,'Callback',{@edit_frame_Callback,handles});
set(handles.slider_frame,'Callback',{@slider_frame_Callback,handles});

% CALLBACK
function jlistbox_filenameinput_Mouse_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
eventinf=get(eventdata);
if eventinf.Button==1 && eventinf.ClickCount==2 %double left click
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
        uijlist_setfiles(handles.jlistbox_filelist,newdir,'type',{'.all'});
        handles.combobox_currdir.insertItemAt(newdir,0);
        set(handles.combobox_currdir,'selectedindex',0);
    elseif strcmpi(ext,'.m')
        edit(fullfile(currdir,filename));
    elseif strcmpi(ext,'.mat')
        fprintf('Load: %s.\n',filename);
        myfile = class_FileIO('filename',filename,'filedir',currdir);
        myfile.loadtows;
        kin = evalin('base','kin');        
        celllist = mat2list(kin.gc.event.index);
        set(handles.listbox_matdata,'string',celllist);
        handles.matdata = kin.gc.event.index;
        handles.matfile = myfile;
    elseif strcmpi(ext,'.bvh')
        [handles.skeleton,handles.time] = loadbvh(fullfile(currdir,filename));        
        set(handles.slider_frame,'min',0,'max',length(handles.time),...
            'sliderstep',[1 100]./length(handles.time));
        showframe(1,handles);
    else        
    end
elseif eventinf.Button==3       %Right Click
    handles.jmenu.show(hObject,eventinf.X,eventinf.Y);
    handles.itempos.x=eventinf.X;
    handles.itempos.y=eventinf.Y;
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function slider_frame_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
sl_val = get(hObject,'value');
set(handles.edit_frame,'string',num2str(sl_val));
set(handles.listbox_matdata,'value',round(sl_val));
gcid = find(handles.matdata(:,1) > sl_val,1,'first');
if gcid > 1
    set(handles.listbox_matdata,'value',gcid-1);
else
    set(handles.listbox_matdata,'value',1);
end
showframe(sl_val,handles);
% Setappdata
setappdata(handles.figure,'handles',handles);

function edit_frame_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
ed_str = get(hObject,'string');
set(handles.slider_frame,'value',str2num(ed_str));
gcid = find(handles.matdata(:,1) > str2num(ed_str),1,'first');
if gcid > 1
    set(handles.listbox_matdata,'value',gcid-1);
else
    set(handles.listbox_matdata,'value',1);
end
set(handles.listbox_matdata,'value',gcid-1);
showframe(str2num(ed_str),handles);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_play_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
thisstr = get(hObject,'string');
if strcmpi(thisstr,icontext(handles.iconlist.action.play,'start'))
    set(hObject,'string',icontext(handles.iconlist.status.stop,'stop'));
    start(handles.mytimer);
else    
    stop(handles.mytimer); % Perform a list of task to quit the program
    set(hObject,'string',icontext(handles.iconlist.action.play,'start'));
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_insert_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
gcid = get(handles.listbox_matdata,'value');
newmatdata = handles.matdata;
thisframe = str2num(get(handles.edit_frame,'string'));
insertval = [thisframe, thisframe+5, thisframe+10, thisframe+15, thisframe+20];
newmatdata = [newmatdata(1:gcid,:); insertval; newmatdata(gcid+1:end,:)];
celllist = mat2list(newmatdata);
set(handles.listbox_matdata,'string',celllist);
handles.matdata = newmatdata;
set(handles.listbox_matdata,'value',get(handles.listbox_matdata,'value')+1);
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_del_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
gcid = get(handles.listbox_matdata,'value');
newmatdata = handles.matdata;
newmatdata(gcid,:) = [];
celllist = mat2list(newmatdata);
set(handles.listbox_matdata,'string',celllist);
handles.matdata = newmatdata;
% Setappdata
setappdata(handles.figure,'handles',handles);

function pushbutton_save_Callback(hObject,eventdata,handles)
handles=getappdata(handles.figure,'handles');
% Convert back to mat data from list data;
kin = evalin('base','kin');
kin.gc.event.index = handles.matdata;
handles.matfile.savevars('kin');
% Setappdata
setappdata(handles.figure,'handles',handles);

function showframe(ff,handles)
axes(handles.player); 
cla;hold on;
skeleton = handles.skeleton;
for nn = 1:length(skeleton)
    plot3(skeleton(nn).Dxyz(1,ff),skeleton(nn).Dxyz(3,ff),skeleton(nn).Dxyz(2,ff),'.','markersize',20)
    parent = skeleton(nn).parent;
    if parent > 0
        plot3([skeleton(parent).Dxyz(1,ff) skeleton(nn).Dxyz(1,ff)],...
            [skeleton(parent).Dxyz(3,ff) skeleton(nn).Dxyz(3,ff)],...
            [skeleton(parent).Dxyz(2,ff) skeleton(nn).Dxyz(2,ff)])
    end    
end
view(-30,30)
axis equal off
drawnow

function liststr = mat2list(matdata)
for i = 1 : size(matdata,1)
    strcmd = 'temp = sprintf(''';
    for j = 1 : size(matdata,2)        
        if j == size(matdata,2)
            strcmd = [strcmd '%04d    '','];
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
    liststr{i} = [sprintf('GC:%02d    ',i) temp];
end

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
% uijlist_setfiles(handles.jlistbox_filelist,updir,'type',{'.all'});
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
uijlist_setfiles(handles.jlistbox_filelist,newdir,'type',{'.all'});
setappdata(handles.figure,'handles',handles);


function timerFcn_Callback(hObject,event,handles)
handles=getappdata(handles.figure,'handles');
ff = handles.currframe;
set(handles.slider_frame,'value',ff);
set(handles.edit_frame,'string',num2str(ff));
showframe(ff,handles);
handles.currframe = handles.currframe + 30;
if handles.currframe > length(handles.time)
    handles.currframe = length(handles.time);
end
% Setappdata
setappdata(handles.figure,'handles',handles);

function timerStopFcn_Callback(hObject,event,handles)
handles=getappdata(handles.figure,'handles');
% Setappdata
setappdata(handles.figure,'handles',handles);
