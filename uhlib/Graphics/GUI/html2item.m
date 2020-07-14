function item=html2item(htmlitem)
mark1=strfind(htmlitem,'>');mark1=mark1(end-1)+1;
mark2=strfind(htmlitem,'<');mark2=mark2(end)-1;
item=htmlitem(mark1:mark2);