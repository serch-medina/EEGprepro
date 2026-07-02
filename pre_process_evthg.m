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

py.extraer_datos.extraer_datos(recortar=true) % Yo guarde en el registro_dexp... la info sobre la duracion de los datos

disp('¡Primer paso del preprocesamiento obliterado, finiquitado, machacado y pulverizado!');
