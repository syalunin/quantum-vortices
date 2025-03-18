% Interpolates colormaps in LCH color space (perceptually uniform).
% The output containts the number of entries and RGB triplets.

clear
close

% save colormap "parula"
cmap = parula;
num = size(cmap,1);
f = fopen('parula.txt','w');
fprintf(f,'%d\n',num);
cmap = round(cmap,5);
for j=1:num
   fprintf(f,"%.5f  %.5f  %.5f\n",cmap(j,1),cmap(j,2),cmap(j,3));
end
fclose(f);

% save colormap "hsv" as "hsv_matlab"
cmap = hsv;
num = size(cmap,1);
f = fopen('hsv_matlab.txt','w');
fprintf(f,'%d\n',num);
cmap = round(cmap,5);
for j=1:num
   fprintf(f,"%.5f  %.5f  %.5f\n",cmap(j,1),cmap(j,2),cmap(j,3));
end
fclose(f);

% interpolate colormaps from *.txt and save them

data = dir('*.txt');
namelist = {data.name};
num = 1024;
count = 1;
WP = whitepoint('d65');
for j=1:numel(namelist)
   items = split(namelist{j},'.');
   name = items{1};
   f = fopen(namelist{j},'r');
   cmap = fscanf(f,"%f");
   fclose(f);
   if cmap(1)==256||cmap(1)==64
      cmap = reshape(cmap(2:end),3,[])';
      fprintf(sprintf('Interpolating %s\n',namelist{j}));
      cmap = applycform(cmap,makecform('srgb2lab','AdaptedWhitePoint',WP));
      cmap = applycform(cmap,makecform('lab2lch'));
      cmap(:,3) = 180/pi*unwrap(cmap(:,3)*pi/180);
      cmap = interp1(linspace(0,1,size(cmap,1)),cmap,linspace(0,1,num),'makima');
      cmap = applycform(cmap,makecform('lch2lab'));
      cmap = applycform(cmap,makecform('lab2srgb','AdaptedWhitePoint',WP));
      filename = sprintf("%s%d.txt",name,num);
      f = fopen(filename,'w');
      fprintf(f,"%d\n",num);
      cmap = round(cmap,5);
      for k=1:num
         fprintf(f,"%.5f  %.5f  %.5f\n",cmap(k,1),cmap(k,2),cmap(k,3));
      end
      fclose(f);
      %figure(count);
      %plot(cmap);
      %title(namelist{j});
      count = count+1;
   end
end
