% Ruta del archivo
dpath = fullfile('segmentado/');
% file = '';
file = 'H01COM_ppepoch1a2.set';
if isempty(file)
    % ==== Ventana de seleccion ====
    prompt = 'Selecciona el archivo de texto';
    disp('Para continuar debe seleccionar un archivo a analizar')
    [file, ~] = uigetfile('*.set',prompt); % Ignoramos la salida de ruta
end

% Busca con regex dentro de la cadena, con la exp: H\d{2}CO[NM]
sujeto = regexp(file,'H\d{2}CO[NM]','match');
sujeto = sujeto{1};

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; 
% Prueba con el set de datos epoqueado de Mer
EEG = pop_loadset(file,dpath);
eeglab redraw
% Se detectan los eventos potencialmente ruidosos
[ALLEEG, EEG,CURRENTSET, noisy_epochs] = detectar_ruido(ALLEEG,EEG,CURRENTSET);
eliminar_ruido(ALLEEG, EEG,CURRENTSET, noisy_epochs,sujeto,20);
