config_files

% Carpeta fuente de los archivos .set y dft
srcDir = fullfile('datos_exportados_m','dft_set_data');
% Indica a dir todos los archivos que tiene que listar
regex = fullfile(srcDir,'*.set');
files = dir(regex);

for i = 1:numel(files)
    disp(files(i).name);
    exp_eventos(files(i).name,srcDir);
    exp_tiempos(files(i).name,srcDir);
    exp_actividad(files(i).name,srcDir);
end

% IMPORTANTE ! : Forzar verificacion, fuerza a todos los archivos dentro de
% la carpeta datos_exportados_m/eventos_exportados a ser reprocesados por
% python y con ello sobreescribe los registros generados. 
% POR ESO QUEDA POR IMPLEMENTAR, UNA OPCION QUE PERMITA REPROCESAR SOLO UN
% ARCHIVO O ARCHIVOS, EN ESPECIFICO.

py.extraer_datos.extraer_datos(false, true, false) % Yo guarde en el registro_dexp... la info sobre la duracion de los datos

disp('¡Primer paso del preprocesamiento obliterado, finiquitado, machacado y pulverizado!');

clear srcDir regex files 
