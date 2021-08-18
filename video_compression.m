%Change a,b to -4,4
a = -8
b = 8
fin = fopen("frame0.raw","r");
frame0 = fread(fin,[176,144])';
fclose(fin);
fin = fopen("frame1.raw","r");
frame1 = fread(fin,[176,144])';
fclose(fin);
%FRAME0 RECONSTRUCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c = reshape(frame0,4,4,[]);
QP = 27;
for i=1:length(c)
    X = dct2(c(:,:,i));
    W = integer_transform(X);
    Z = quantization(W,QP);
    quant(:,:,i) = Z;
    Wi = inv_quantization(Z,QP);
    Y = inv_integer_transform(Wi);
    Yr = round(Y/64);
    Xi = idct2(Yr);
    c(:,:,i) = Xi;  
endfor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


colormap(gray);
e=entropy(uint8(abs(quant)));
x2 = reshape(c,144,176,[]);
y2 = uint8(x2);
disp("Entropy of quants:"), disp(e);
disp("PSNR for frame0:"), disp(psnr(y2,uint8(frame0)))



















%CREATE MACROBLOCKS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_x = 1;
start_y = 1;
end_x = 16;
end_y = 16;
ip =0;
jp = 0;
for v=1:99
  if(end_y>176)
    start_x = start_x + 16;
    end_x = end_x + 16;
    start_y = 1;
    end_y = 16;  
  endif
  for row=start_x:end_x
      ip = ip + 1;
      for col=start_y:end_y
          jp = jp + 1;
          mac(ip,jp) = frame1(row,col);
      endfor
      jp = 0;
   endfor
   ip = 0;
   macros(:,:,v) = mac;
   end_y = end_y + 16;
   start_y = start_y + 16;
endfor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%MOTION ESTIMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = false;
ip =0;
jp = 0;
result = 9999999999999999999;
start_x = 1;
start_y = 1;
end_x = 16;
end_y = 16;

dianysma = [0,0];
for m=1:length(macros)
    macro = macros(:,:,m);
    blk = macro;
    if(end_y>176)
      start_x = start_x + 16;
      end_x = end_x + 16;
      start_y = 1;
      end_y = 16;  
     endif
     %disp(m)
     %disp(start_y)
     %disp(end_y)
     for i=a:b
        for j=a:b
            for row=start_x:end_x
                if(row+i>=1 && row+i<=144)
                    %disp(ip)
                    ip = ip + 1;
                    for col=start_y:end_y
                       if(col+j>=1 && col+j<=176)
                           %disp(jp)
                           jp = jp + 1;
                           blk(ip,jp) = x2(row+i,col+j);
                           
                       %endif
                       else
                           s = true;
                       endif
                   endfor
                   jp = 0;
                %endif
                else
                    s = true;
                endif
            endfor
            ip = 0;
            %tf = isempty(blk);
           if(s == false)
            %length(macro)
            %length(blk)
            difference = macro - blk;
            absolute = abs(difference);
            result_new = sum(absolute(:));
            [i,j];
            if(result_new<result)
              result = result_new;
              dianysma = [i,j];
            endif
           endif
           s = false;
        endfor
     endfor
     vector(:,:,m) = dianysma;
     result = 9999999999999999999;
     dianysma = [0,0];
     end_y = end_y + 16;
     start_y = start_y + 16;
endfor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%MOTION PREDICTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_x = 1;
start_y = 1;
end_x = 16;
end_y = 16;
ip =0;
jp = 0;
for v=1:length(vector)
  pos1 = vector(1,1,v);
  pos2 = vector(1,2,v);
  if(end_y>176)
    start_x = start_x + 16;
    end_x = end_x + 16;
    start_y = 1;
    end_y = 16;  
  endif
  for row=start_x:end_x
      ip = ip + 1;
      for col=start_y:end_y
          jp = jp + 1;
          mac2(ip,jp) = x2(row+pos1,col+pos2);
      endfor
      jp = 0;
   endfor
   ip = 0;
   mac2;
   macros2(:,:,v) = mac2;
   end_y = end_y + 16;
   start_y = start_y + 16;
endfor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%RESHAPE PREDICTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_x = 1;
start_y = 1;
end_x = 16;
end_y = 16;
ip =0;
jp = 0;
for v=1:99
  if(end_y>176)
    start_x = start_x + 16;
    end_x = end_x + 16;
    start_y = 1;
    end_y = 16;  
  endif
  for row=start_x:end_x
      ip = ip + 1;
      for col=start_y:end_y
          jp = jp + 1;
          guess(row,col) = macros2(ip,jp,v);
      endfor
      jp = 0;
   endfor
   ip = 0;
   end_y = end_y + 16;
   start_y = start_y + 16;
endfor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
frame1_estimated = guess(:,:,1);


estimation_error = frame1-frame1_estimated;

c2 = reshape(estimation_error,4,4,[]);
QP = 27;
for i=1:length(c2)
    X2 = dct2(c2(:,:,i));
    W2 = integer_transform(X2);
    Z2 = quantization(W2,QP);
    quant2(:,:,i) = Z2;
    Wi2 = inv_quantization(Z2,QP);
    Y3 = inv_integer_transform(Wi2);
    Yr3 = round(Y3/64);
    Xi3 = idct2(Yr3);
    c2(:,:,i) = Xi3;  
endfor
e2=entropy(uint8(abs(quant2)));

new_error = reshape(c2,144,176,[]);
new_frame1 = new_error+frame1_estimated;
y3 = uint8(new_frame1);
disp("Entropy of quants2:"), disp(e2);
disp("PSNR for frame1:"), disp(psnr(y3,uint8(frame1)))


%imagesc(y3)
montage([y2,y3]);
title("New Frame0 - New Frame1");