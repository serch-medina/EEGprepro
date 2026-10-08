% Ruta del archivo
dpath = fullfile('segmentado/');
file = '';
% file = 'H01COM_ppepoch1a2.set';
if isempty(file)
    % ==== Ventana de seleccion ====
    % Por defecto se seleccionan los archivos .set
    prompt = 'Selecciona el archivo de texto';
    disp('Para continuar debe seleccionar un archivo a analizar')
    [file, ~] = uigetfile('*.set',prompt); % Ignoramos la salida de ruta
    % Damos error si no se selecciono ningun archivo
    if isequal(file, 0)
        error('No se seleccionó ningún archivo.');
    end
end

% Busca con regex dentro de la cadena, con la exp: H\d{2}CO[NM] el nombre
% del sujeto a procesar.
sujeto = regexp(file,'H\d{2}CO[NM]','match');
sujeto = sujeto{1};

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; 
% Prueba con el set de datos epoqueado de Mer
EEG = pop_loadset(file,dpath);
eeglab redraw
% Se detectan los eventos potencialmente ruidosos
[ALLEEG, EEG,CURRENTSET, noisy_epochs] = detectar_ruido(ALLEEG,EEG,CURRENTSET);
eliminar_ruido(ALLEEG, EEG,CURRENTSET, noisy_epochs,sujeto,20);
