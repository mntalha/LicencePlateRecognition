clc;
clear variables;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%Muhammed Nur Talha Kılıç
%2020 Haziran İşaret ve Görüntü İşleme Dersi Projesi
%Trafik Plakasının Tespiti
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Aşağıdaki fonksiyonlar test yapılırken kullnılan tüm resimlerin alınması
%icin end kısmı for un en alt satırda
%imagefiles=dir('../VeriSeti//*.jpg');
%for sayii=1:length(imagefiles) 
%image = imread(imagefiles(sayii).folder+"/"+imagefiles(sayii).name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%resim okuma ,resmin adresi girilir.
image=imread("../VeriSeti/image1.jpg");
%imshow(image);
%resmi gri formata cevirme
imagegray=rgb2gray(image);
%imshow(imagegray);

%resmin boyutlarını 1200 1600 şeklinde degistirme
imresized=imresize(imagegray,[1200 NaN]); % Resizing the image keeping aspect ratio same.
%imshow(imresized);

%gürültü icin medyan filitresi 
imagefiltered=medfilt2(imresized);  %buna gerek olmayabilir sobel in içinde zaten var
%imshow(imagefiltered);

%kontrast attrımı
%imhist(imagefiltered);
imageadjusted=imadjust(imagefiltered);  
%imshow(imageadjusted);

%parlaklığı artıyor ve histogram esitlemesi
imagehisteq=histeq(imageadjusted); 
%imshow(imageadjusted);
%imhist(imagehisteq);

%0 ile 1 arasına aldı.
im2doubled=(im2double(imagehisteq)); %1 lük formata cevirdi
%imshow(im2doubled);
% Gelistirilmis Sobel dikey maskesi 
ImprovedSobelMasking   =  [-3  0 3; 
                           -10 0 10;
                            -3 0 3]/32; 
               
%flitreleme ,replicate de kenarlara uygulanırken yansıması yapılması icin               
sobeledimage    = imfilter(im2doubled,ImprovedSobelMasking,'replicate'); 
%imshow(sobeledimage);
%eksi sonucların artıya cevrilmesi ve kontrast attırımı
sobeledimage    = (sobeledimage.^2);  
%imshow(sobeledimage);
%yüksek olan degerlerin tekrardan 0 ile 1 arasına alımı
sobeledimage=mat2gray(sobeledimage);
%imshow(sobeledimage);

%treshold cıkarma otsu metodu ile
level = graythresh(sobeledimage);

%threshold uygulama
sobeledimage    = imbinarize(sobeledimage,level);
imshow(sobeledimage);

%Morfolojik Yöntemlere gecme ve kapama işlemi
structureelement= strel('square',2);
newimage = imclose(sobeledimage,structureelement);
%imshow(newimage);

%boslukları doldurma
%newimage = imdilate(newimage,structureelement);
newimage = imfill(newimage,'holes');
%figure,imshow(i4);title('close line');
%imshow(newimage);

%fazlalıkları silme 
newimage = bwareaopen(newimage, 50);
newimage=imclearborder(newimage, 4);
imshow(newimage);
% Histogramını çıkarma
SumofImage  = sum(newimage,2);                      
% figure()
% subplot(1,2,1);imshow(newimage)
% subplot(1,2,2);plot(1:size(SumofImage,1),SumofImage)
% axis([1 size(newimage,1) 0 max(SumofImage)]);
% view(90,90); 

%en yogunluklu pixelleri alma
T1    = 0.25;         
Candidaterows    = find(SumofImage > (T1*max(SumofImage)));          % 


Mask   = zeros(size(sobeledimage));
Mask(Candidaterows,:) = 1;                          % Maske
MB    = Mask.*(sobeledimage);                        % 
MB = imerode(MB,structureelement);
% figure();
%imshow(MB)

%Morfolojik Yöntemler
Extensiony    = strel('rectangle',[80,4]);      % Yatayda büyütme
Imageextendendy   = imdilate(MB,Extensiony);                 
Imageextendendy   = imfill(Imageextendendy,'holes');         % Boslukları doldurma 
% figure();imshow(MBy)

%Morfolojik Yöntemler 
Extensionx    = strel('rectangle',[4,80]);      % Dikeyde büyütme
Imageextendendx   = imdilate(MB,Extensionx);                
Imageextendendx   = imfill(Imageextendendx,'holes');            % Boslukları doldurma 
% figure();imshow(MBx)

%Ektendleri birlestirme
Jointedimage   = Imageextendendx.*Imageextendendy;                      
% figure();imshow(BIM)

%Morfolojik Yöntemler 
Extension    = strel('rectangle',[4,80]);      % Yatayda Büyütme
MM    = imdilate(Jointedimage,Extension);               
MM    = imfill(MM,'holes');             % Boslukları doldurma 
% figure();imshow(MM.*im2doubled)

% Erozyon kısmı
Lineerosion    = strel('line',40,0);            
LastImage    = imerode(MM,Lineerosion);
% figure();
%imshow(LastImage);


% En büyük alana sahib bölgeyi bulma
[Label,num] = bwlabel(LastImage);                  % Ayırma             
Area   = zeros(num,1);

for i = 1:num                           % Her alan icin alan hesabı
[r,c,v]  = find(Label == i);                % İndexleri bulma
Area(i) = sum(v);                      % Alanların toplamı hesabı   
end 

La = find(Area==max(Area));     %en büyük alanın indexini bulma
[a,b]   = find(Label==La);       %alanın koordinatlarını cıkarma 
[Row,Col] = size(im2doubled);    
plateimage      = zeros(Row,Col);           %bos alan olsturma
T       = Row*0.5/100;                 %hata payı verme yüzde 0.5
xloc      = (min(a)-T :max(a)+T);     % yüzde 0.5 pixel kadar genisletiyorum
yloc      = (min(b)-T :max(b)+T);
xloc      = xloc(xloc >= T & xloc <= Row);   %kenarlardan tasmasını engelle
yloc      = yloc(yloc >= T & yloc <= Col);
plateimage(xloc,yloc) = 1;               
PL      = plateimage.*im2doubled;                        % Bulunan Plaka

%imshow(im2doubled)
%figure();imshow(PL)


imshow(im2doubled); title('Detected Plate')
hold on
rectangle('Position',[min(yloc),min(xloc),max(yloc)-min(yloc),...
max(xloc)-min(xloc)],'LineWidth',4,'EdgeColor','r')
hold off
%savefig('/Users/talhakilic/Desktop/yeni/figure'+""+sayii)
%end

im = imcrop(imbinarize(imresized), [min(yloc),min(xloc),max(yloc)-min(yloc),max(xloc)-min(xloc)]);%crop the number plate area

im = bwareaopen(~im, 500); 
%im in tersi alınıytor.toplam alan 500 pixel den düşükse sil
[h, w] = size(im);%get width

%imshow(im);

Iprops=regionprops(im,'BoundingBox','Area', 'Image'); %Görüntüyü alanlara ayırma
count = numel(Iprops);
plate=[]; % Baslanıgıcta plaka bos doldurma islemi yapilacak

for i=1:count
    verticallength = length(Iprops(i).Image(1,:));
    horizontallength = length(Iprops(i).Image(:,1));
    if verticallength<(h/2) && horizontallength>(h/3)        
    letter=Letter_detection(Iprops(i).Image); %plaka tanıma islemine sokma
    plate=[plate letter] % her seferinde eliyor.
    end
end
disp('Bitti');
%disp(imagefiles(sayii).folder+"/"+imagefiles(sayii).name);
%end

%%%Merkezleri gösterme fonksiyonu direk matlab sayfasından alınmıstır.

% imshow(im);
% stats = regionprops('table',im,'Centroid',...
%     'MajorAxisLength','MinorAxisLength')
% centers = stats.Centroid;
% diameters = mean([stats.MajorAxisLength stats.MinorAxisLength],2);
% radii = diameters/2;
% hold on
% viscircles(centers,radii);
% hold off