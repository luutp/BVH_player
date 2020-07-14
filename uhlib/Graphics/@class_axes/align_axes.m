function align_axes(this,varargin)
% This function align an axes class object to a reference object
align = get_varargin(varargin,'align','southright');
scale = get_varargin(varargin,'scale',[1, 1]);
gap = get_varargin(varargin,'gap',[0, 0]);
refobj = get_varargin(varargin,'reference',gca);
refpos = refobj.position;
marginleft_ref=refpos(1);
marginright_ref = refpos(1)+refpos(3);
marginbottom_ref = refpos(2);
margintop_ref = refpos(2)+refpos(4);
marginleft=-1;marginright=-1;
margintop=-1;marginbottom=-1;

switch align
    case 'southleft'
        margintop = marginbottom_ref; % Go to south;
        marginleft = marginleft_ref; % Go to left;
    case 'southright'
        margintop = marginbottom_ref; % go to south
        marginleft = marginright_ref; % go to right;
    case 'eastdown'
        marginleft = marginright_ref; % go to east
        marginbottom = marginbottom_ref;
    case 'eastup'
        marginleft = marginright_ref;
        margintop = margintop_ref;        
    otherwise
end
width=refpos(3)*scale(1);height=refpos(4)*scale(2);
if marginright~=-1; marginleft=1-marginright-width;end;
if margintop~=-1; marginbottom=margintop-height;end;
marginleft=marginleft+gap(1);marginbottom=marginbottom+gap(2);
this.position = [marginleft marginbottom width height];
layout_axes(this);

