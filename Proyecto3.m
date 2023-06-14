clc;
clear;
close all;

%Buscamos la imagen a abrir
char name;
[name,pathname] = uigetfile('*.JPG');
nombre = sprintf('%s%s',pathname,name);
I = imread(nombre);

%Ploteo de la imagen original
figure(1);
imshow(I);
title('Imagen Original');

%Pedimos se nos indique el tipo de imagen ingresada
Tipo = input("Tipo de imagen ingresada: ", 's');

%Dependiendo del tipo de imagen creamos los presets
switch Tipo
    case 'pradera'
        k = 2;
        ClasesDat = ["Cielo", 0; "Pasto", 0];
        ClasesRGB = [12, 183, 242; 0,128,94];
    case 'playa'
        k = 3;
        ClasesDat = ["Cielo", 0; "Mar", 0; "Arena", 0];
        ClasesRGB = [100, 255, 255; 0,0,200; 255,255,204];
   case 'rocas'
        k = 3;
        ClasesDat = ["Cielo", 0; "Mar", 0; "Rocas", 0];
        ClasesRGB = [150, 255, 255; 0,0,200; 100, 100, 100];
    case 'nubes'
        k = 2;
        ClasesDat = ["Cielo", 0; "Nubes", 0];
        ClasesRGB = [12, 183, 242; 255,255,255];
end

%Aplicamos segmentacion por K-means
[L, Centers] = imsegkmeans(I,k);

%Revisamos los centroides resultantes de la clasificacion para saber cual
%corresponde a cuales de nuestras clases en los presets
for i=1:size(ClasesRGB,1) %for que revisa los centroides que saco K-means
    Dmin = 450; %Asignamos como distancia minima inicial una mas grande que la distancia maxima posible en la escala RGB
    for j=1:size(Centers,1) %for que revisa los rgb de las clases de nuestros presets
        Dtest = pdist([ClasesRGB(i,:); Centers(j,:)]); %Medimos la distancia entre el punto RGB i y el centroide j
        %fprintf('FOR: i = %d, j = %d, Dtest = %d, Dmin=%d\n',i,j,Dtest,Dmin);
        if( Dtest < Dmin ) %Si la distancia testeada es menor a la Dmin actual
            Dmin = Dtest; %La asignamos como la nueva distancia minima
            ClasesDat(i,2) = j; %Y guardamos el centroide que nos genero esa distancia            
            %fprintf('ENTRE: i = %d, j = %d, Dtest = %d, Dmin=%d\n',i,j,Dtest,Dmin);
        end
    end
end
ClasesDat = sortrows(ClasesDat,2); %Ordenamos ClasesDat

%Ploteo de la imagen segmentada por K-means
B = labeloverlay(I,L);
figure(2);
imshow(B);
title('Imagen Segmentada sin Suavizado');

%Pedimos se nos indique si la imagen tendra suavizado
S = 0;
S = input("¿Suavizado?[No=0/Si=1]: ");

%Proceso para suavizar la clasificacion por K-means
if( S == 1 )
    wavelength = 2.^(0:5) * 3;
    orientation = 0:45:135;
    g = gabor(wavelength,orientation);
    BW = im2gray(im2single(I));
    gabormag = imgaborfilt(BW,g);
    %montage(gabormag,'Size',[4 6])
    for i = 1:length(g)
        sigma = 0.5*g(i).Wavelength;
        gabormag(:,:,i) = imgaussfilt(gabormag(:,:,i),3*sigma); 
    end
    %montage(gabormag,'Size',[4 6])
    nrows = size(I,1);
    ncols = size(I,2);
    [X,Y] = meshgrid(1:ncols,1:nrows);
    featureSet = cat(3,I,gabormag,X,Y);
    LO = L; %Guardamos la matriz clasificada original para futuras referencias
    L = imsegkmeans(featureSet,k,'NormalizeInput',true);
    C = labeloverlay(I,L);
    figure(3);
    imshow(C);
    title('Imagen Segmentada con Suavizado')
end

%Revisamos la matriz clasificada por el k-means y creamos las separacione a partir de ella
Sep = []; %Inicializamos la matriz que guardara las coordenadas de los puntos de separacion
for i=1:1:size(L,1) %for que revisa la imagen a lo alto
    for j=1:1:size(L,2) %for que revisa la imagen a lo largo
        if( j ~= 1 ) %Si el pixel no es el primero de la fila
            if( L(i,j) ~= L(i,j-1) ) %Si el pixel que estamos revisando es de diferente color que el pixel anterior en la fila
                Sep = [Sep; i,j]; %Guardamos las coordenadas de este pixel
                continue;
            end
        end
        if( i ~= 1 ) %Si el pixel no es el primero de la columna
            if( L(i,j) ~= L(i-1,j) ) %Si el pixel que estamos revisando es de diferente color que el pixel anterior en la columna
                Sep = [Sep; i,j]; %Guardamos las coordenadas de este pixel
            end
        end
    end
end

%Sacamos la posicion promedio de todos los puintos de cierta clase
ClasesCoords = [];
for i=1:size(Centers,1)
    [rows, cols] = find( L == i ) ; %Encontramos las coordenadas de todos los puntos de esta clase
    %ClasesCoords(i,:) = [rows(randi(size(rows,1))), cols(randi(size(cols,1)))]; %Y tomamos una de ellas de manera aleatoria
    ClasesCoords(i,:) = [mean(rows), mean(cols)]; %Y las promediamos
end

%Ploteo de las separaciones
figure(4);
imshow(I); %Mostramos la imagen de nuevo
grid on; %Ponemos la rejilla
hold on; %Mantemos lo que ya habiamos ploteado (La imagen)
for i=1:size(Centers,1) %for que plotea el centro de cada clase
    plot(ClasesCoords(i,2),ClasesCoords(i,1),'.','MarkerSize',30);
end
Sep = Sep.'; %Transponemos la matriz de los puntos de separación
plot(Sep(2,:),Sep(1,:),'.m','MarkerSize',10);
legend();
title('Separaciones');

%Imprimimos la informacion de las clases
fprintf('\n');
for i=1:size(Centers,1)
    fprintf('data%s => %s\n',ClasesDat(i,2),ClasesDat(i,1));
end
fprintf('data%d => Separaciones\n',size(Centers,1)+1);